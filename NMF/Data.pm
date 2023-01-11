package NMF::Data;
use v5.14;
use warnings;

# NMF imports
use NMF::Const;

# Core imports
use Scalar::Util qw(looks_like_number);

=head1 NAME

NMF::Data - Noir Music File (NMF) data object.

=head1 SYNOPSIS

  use NMF::Data;
  
  # Declare new data object
  my $nmf = NMF::Data->create;
  
  # Deserialize an NMF file from a scalar reference
  $nmf->parse(\$binary_string);
  
  # Serialize this object into a NMF file in a scalar reference
  $nmf->serialize(\$binary_string);
  
  # Wrappers around parse() and serialize()
  $nmf->parse_stdin;
  $nmf->parse_path("path/to/file.nmf");
  $nmf->serialize_stdout;
  $nmf->serialize_path("path/to/output.nmf");
  
  # Get and set the basis
  my $basis = $nmf->basis;
  if ($basis == -1) {
    # 96 quanta per quarter note
    ...
  } else {
    # Fixed basis, $basis is in Hz
    ...
  }
  
  $nmf->basis(-1);
  $nmf->basis(48000);
  $nmf->basis(44100);
  $nmf->basis(60);
  
  # Get the number of sections
  my $count = $nmf->sections;
  
  # Get the starting offset of a given section
  my $offs = $nmf->offset(2);
  
  # Define a new section
  $nmf->sect($offset);
  
  # Get the number of notes
  my $count = $nmf->notes;
  
  # Get a specific note
  my %note = $nmf->get(253);
  
  my $t = $note{'t'};
  my $dur = $note{'dur'};
  my $pitch = $note{'pitch'};
  my $art = $note{'art'};
  my $sect = $note{'sect'};
  my $layer = $note{'layer'};
  
  # Set a specific note
  $nmf->set(253, %note);
  
  # Add a new note
  $nmf->append(%note);
  
  # Sort the notes in chronological order
  $nmf->sort_notes;

=head1 DESCRIPTION

Represents all the data in an NMF file.

NMF data is stored in memory.  After construction with C<create()>, the
data object is in a default initial state.  You can either start
defining a new NMF file from this default initial state or you can load
an existing NMF file with C<parse()>.  C<parse()> accepts a binary
string reference holding the whole NMF file, but wrapper functions
C<parse_stdin()> and C<parse_path()> are available to read an NMF file
from standard input or a file path, respectively.

At any point in time, the current state of an NMF data object can be
serialized into an NMF file.  The C<serialize()> function writes the
resulting file into a binary string reference.  Wrapper functions
C<serialize_stdout()> and C<serialize_path()> are available to write an
NMF file to standard output or a file path, respectively.

The rest of the functions allow the data within the NMF file to be
inspected and edited.  The C<basis()> function both reads and writes the
quantum basis of the NMF data.  C<sections()> and C<notes()> counts the
total number of sections and notes currently in the data object.  The
C<offset()> function queries existing section offsets and C<sect()> adds
new section definitions.  C<get()>, C<set()>, and C<append()> allow
individual notes to be read, edited, and appended.

NMF does not require notes to be sorted in chronological order.  If you
want to get them in chronological order, the C<sort_notes()> function
will sort all the currently defined notes.

=cut

# ===============
# Local functions
# ===============

# Comparison function for sorting note events.
#
sub _nmf_cmp {
  # Try sorting by t offset first
  my $result = ($a->[0] <=> $b->[0]);
  if ($result == 0) {
    # t offsets were equal, so sort by duration with lowest values first
    # so grace notes are properly ordered
    $result = ($a->[1] <=> $b->[1]);
  }
  return $result;
}

=head1 CONSTRUCTOR

=over 4

=item B<create()>

Create a new NMF data object.

The data object starts out with a quantum basis of 96 quanta per quarter
note, a single section defined at offset zero, and no notes defined.

=cut

sub create {
  # Get parameters
  ($#_ == 0) or die;
  
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  
  # Define the new object
  my $self = { };
  bless($self, $class);
  
  # _qbasis stores the quantum basis in Hz, which is either [1, 1024],
  # or 44100 or 48000, or -1 indicating 96 quanta in a quarter note
  $self->{'_qbasis'} = -1;
  
  # _sect is the section table; each section is an integer in range
  # [0, NMF_MAXINT] specifying the starting offset of the section; at
  # most NMF_MAXSECT sections allowed; always starts out with a single
  # section at offset zero
  $self->{'_sect'} = [0];
  
  # _note is the note table; each record is a subarray storing the
  # following six values:
  #
  #   0. Time offset
  #   1. Duration
  #   2. Pitch
  #   3. Articulation
  #   4. Section index
  #   5. Layer index
  #
  # Time offset is the starting time of the note, in range
  # [0, NMF_MAXINT]; must be greater than or equal to the starting 
  # offset of the section selected by the section index
  #
  # Duration is in range [-NMF_MAXINT, NMF_MAXINT]; values greater than
  # zero are duration in quanta; values of zero mean a cue; values less
  # than zero mean grace notes before the beat
  #
  # Pitch is in range [NMF_MINPITCH, NMF_MAXPITCH]; counts the number of
  # semitones away from middle C
  #
  # Articulation is in range [0, NMF_MAXART]
  #
  # Section index is an index into the _sect array selecting which
  # section this note belongs to
  #
  # Layer index is one less than the layer this note belongs to; it must
  # be in range [0, NMF_MAXSHORT]
  #
  # Note records can be in any order, but there may be at most
  # NMF_MAXNOTE notes
  $self->{'_note'} = [];
  
  # Return the new object
  return $self;
}

=back

=head1 PUBLIC INSTANCE METHODS

=over 4

=item B<parse(binary_ref)>

Deserialize NMF data from an NMF file.

C<binary_ref> is a reference to a scalar storing the whole NMF file in a
binary string.

The state of the NMF data object is completely replaced with the data
parsed from the given file.  Errors are thrown if there are any parsing
problems.

=cut

sub parse {
  # Get self and parameters
  ($#_ == 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $str = shift;
  (ref($str) eq 'SCALAR') or die;
  
  # Define values that will hold the parsed information
  my $qbasis;
  my @sect;
  my @notes;
  
  # Get the 16-byte header
  (length($$str) >= 16) or die "Failed to read NMF header!\n";
  my $header = substr($$str, 0, 16);
  
  # Verify that header is binary string
  ($header =~ /^[\x{00}-\x{ff}]*$/) or
    die "Parse requires a binary string!\n";
  
  # Unpack header
  my ($primary, $secondary, $f_qb, $f_sect, $f_note) =
    unpack 'L>L>S>S>L>', $header;
  
  # Verify signatures
  (($primary == 1928196216) and ($secondary == 1313818926)) or
    die "Failed to read NMF signatures!\n";
  
  # Parse the quantum basis
  if ($f_qb == 0) {
    $qbasis = -1;
  } elsif ($f_qb == 1) {
    $qbasis = 44100;
  } elsif ($f_qb == 2) {
    $qbasis = 48000;
  } elsif (($f_qb >= 3) and ($f_qb <= 1026)) {
    $qbasis = $f_qb - 2;
  } else {
    die "NMF has unrecognized quantum basis!\n";
  }
  
  # Make sure section count is in range and then compute the offset
  # within the string of the section table, its byte length, and its
  # record count
  my $tsect_offs;
  my $tsect_blen;
  my $tsect_count;
  
  (($f_sect >= 1) and ($f_sect <= NMF_MAXSECT)) or
    die "NMF file has invalid section count!\n";
  
  $tsect_offs  = 16;
  $tsect_count = $f_sect;
  $tsect_blen  = $tsect_count * 4;
  
  # Make sure note count is in range and then compute the offset within
  # the string of the note table, its byte length, and its record count
  my $tnote_offs;
  my $tnote_blen;
  my $tnote_count;
  
  (($f_note >= 1) and ($f_note <= NMF_MAXNOTE)) or
    die "NMF file has invalid note count!\n";
  
  $tnote_offs  = $tsect_offs + $tsect_blen;
  $tnote_count = $f_note;
  $tnote_blen  = $tnote_count * 16;
  
  # Make sure the total length of the binary string is at least the
  # initial header plus the section table plus the note table
  (length($$str) >= 16 + $tsect_blen + $tnote_blen) or
    die "NMF file is incomplete!\n";
  
  # Get the section table and make sure it only contains binary data
  my $stable = substr($$str, $tsect_offs, $tsect_blen);
  ($stable =~ /^[\x{00}-\x{ff}]*$/) or
    die "Parse requires a binary string!\n";
  
  # Unpack the section table
  for(my $i = 0; $i < $tsect_count; $i++) {
    my $rec = substr($stable, $i * 4, 4);
    push @sect, (unpack('L>', $rec));
  }
  
  # Check the section table
  ($sect[0] == 0) or
    die "First section in NMF file must have offset zero!\n";
  for(my $i = 1; $i < $tsect_count; $i++) {
    ($sect[$i] >= $sect[$i - 1]) or
      die "Sections in NMF file are out of order!\n";
    ($sect[$i] <= NMF_MAXINT) or
      die "Section offset in NMF file is out of range!\n";
  }
  
  # Unpack all the notes and add them to the table
  for(my $i = 0; $i < $tnote_count; $i++) {
    # Get the binary note record and check that it is binary string
    my $rec = substr($$str, $tnote_offs + ($i * 16), 16);
    ($rec =~ /^[\x{00}-\x{ff}]*$/) or
      die "Parse requires a binary string!\n";
    
    # Unpack the note record fields
    my ($n_t, $n_dur, $n_pitch, $n_art, $n_sect, $n_layer) =
      unpack 'L>L>S>S>S>S>', $rec;
    
    # Decode biased values to proper numeric value after checking they
    # are greater than zero when encoded
    (($n_dur > 0) and ($n_pitch > 0)) or
      die "Invalid biased integers in NMF file!\n";
    
    $n_dur   -= 2147483648;
    $n_pitch -= 32768;
    
    # Check ranges
    ($n_t <= NMF_MAXINT) or
      die "Note offset out of range in NMF file!\n";
    (($n_pitch >= NMF_MINPITCH) and ($n_pitch <= NMF_MAXPITCH)) or
      die "Note pitch out of range in NMF file!\n";
    ($n_art <= NMF_MAXART) or
      die "Note articulation out of range in NMF file!\n";
    
    # Make sure section index refers to section within the table and
    # that the offset of this note is greater than or equal to the
    # section offset
    ($n_sect < scalar(@sect)) or
      die "Note in NMF file refers to undefined section!\n";
    ($n_t >= $sect[$n_sect]) or
      die "Note in NMF file occurs before start of its section!\n";
    
    # Note is OK, so add it to the table
    push @notes, ([
      $n_t, $n_dur, $n_pitch, $n_art, $n_sect, $n_layer
    ]);
  }
  
  # If we got here, the parse worked, so replace the state of the object
  # with the newly parsed state
  $self->{'_qbasis'} = $qbasis;
  $self->{'_sect'  } = \@sect ;
  $self->{'_note'  } = \@notes;
}

=item B<serialize(binary_ref)>

Serialize NMF data into an NMF file.

C<binary_ref> is a reference to a scalar that will be overwritten with
the serialized NMF file based on the current state of the data object.

At least one note must be defined in the data object.

=cut

sub serialize {
  # Get self and parameters
  ($#_ == 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $str = shift;
  (ref($str) eq 'SCALAR') or die;
  
  # Reset the string reference to an empty string
  $$str = '';
  
  # Check note count
  (scalar(@{$self->{'_note'}}) > 0) or
    die "Must define at least one note before saving NMF!\n";
  
  # Get the encoded quantum basis
  my $qbasis = $self->{'_qbasis'};
  if ($qbasis == -1) {
    $qbasis = 0;
  } elsif ($qbasis == 44100) {
    $qbasis = 1;
  } elsif ($qbasis == 48000) {
    $qbasis = 2;
  } elsif (($qbasis >= 1) and ($qbasis <= 1024)) {
    $qbasis += 2;
  } else {
    die;
  }
  
  # Add the NMF header
  $$str = $$str . pack('L>L>S>S>L>',
    1928196216,
    1313818926,
    $qbasis,
    scalar(@{$self->{'_sect'}}),
    scalar(@{$self->{'_note'}})
  );
  
  # Add the section table
  for my $sval (@{$self->{'_sect'}}) {
    $$str = $$str . pack('L>', $sval);
  }
  
  # Add the note records
  for my $rec (@{$self->{'_note'}}) {
    # Unpack record
    my $f_t     = $rec->[0];
    my $f_dur   = $rec->[1];
    my $f_pitch = $rec->[2];
    my $f_art   = $rec->[3];
    my $f_sect  = $rec->[4];
    my $f_layer = $rec->[5];
    
    # Convert signed values to biased integers
    $f_dur   += 2147483648;
    $f_pitch += 32768;
    
    # Add packed note
    $$str = $$str . pack('L>L>S>S>S>S>',
      $f_t,
      $f_dur,
      $f_pitch,
      $f_art,
      $f_sect,
      $f_layer
    );
  }
}

=item B<parse_stdin()>

Wrapper around C<parse()> that reads an NMF file from standard input.

=cut

sub parse_stdin {
  # Get self
  ($#_ == 0) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  # Set binary mode
  binmode(STDIN, ':raw') or die;
  
  # Read the whole input in
  my $str = do { local $/; readline(STDIN) };
  (defined $str) or die "Failed to read input!\n";
  
  # Call through
  $self->parse(\$str);
}

=item B<parse_path(path)>

Wrapper around C<parse()> that reads an NMF file from a file path.

=cut

sub parse_path {
  # Get self and parameters
  ($#_ == 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $path = shift;
  (not ref($path)) or die;
  
  # Open handle for binary reading
  open(my $fh, "< :raw", $path) or
    die "Failed to open '$path' for reading!\n";
  
  # Wrap rest in an eval that closes the file on the way out
  eval {
    # Read the whole file in
    my $str = do { local $/; readline($fh) };
    (defined $str) or die "Failed to read file '$path'!\n";
    
    # Call through
    $self->parse(\$str);
    
  };
  if ($@) {
    close($fh) or warn "Failed to close file";
    die $@;
  }
  
  # Close the file
  close($fh) or warn "Failed to close file";
}

=item B<serialize_stdout()>

Wrapper around C<serialize()> that writes an NMF file to standard
output.

=cut

sub serialize_stdout {
  # Get self
  ($#_ == 0) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  # Set binary mode
  binmode(STDOUT, ':raw') or die;
  
  # Call through
  my $str = '';
  $self->serialize(\$str);
  
  # Print result to output
  print $str or die "Failed to write to output!\n";
}

=item B<serialize_path(path)>

Wrapper around C<serialize()> that writes an NMF file to a file path.

=cut

sub serialize_path {
  # Get self and parameters
  ($#_ == 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $path = shift;
  (not ref($path)) or die;
  
  # Open handle for binary writing
  open(my $fh, "> :raw", $path) or
    die "Failed to open '$path' for writing!\n";
  
  # Wrap rest in an eval that closes and deletes the file on the way out
  # in case of error
  eval {
    # Call through
    my $str = '';
    $self->serialize(\$str);
    
    # Print result to file
    print { $fh } $str or die "Failed to write to file '$path'!\n";
    
  };
  if ($@) {
    close($fh) or warn "Failed to close file";
    (unlink($path) == 1) or warn "Failed to remove file";
    die $@;
  }
  
  # Close the file
  close($fh) or warn "Failed to close file";
}

=item B<basis([hz])>

Get or set the quantum basis of the NMF data.

The valid basis values are integers -1, 44100, 48000, and anything in
range [1, 1024].  The value -1 means 96 quanta per quarter note.  All
other values are fixed rates given in Hz.

If a parameter is passed, the quantum basis is changed to the given
basis.  None of the note events are changed by this function.  Only the
recorded quantum basis is updated.

If no parameter is passed, the current quantum basis is returned.

=cut

sub basis {
  # Get self and parameters
  (($#_ == 0) or ($#_ == 1)) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $val = undef;
  if ($#_ >= 0) {
    $val = shift;
    (looks_like_number($val) and (int($val) == $val)) or die;
    (($val == -1) or ($val == 44100) or ($val == 48000) or
      (($val >= 1) and ($val <= 1024))) or die;
  }
  
  # Either get or set the value
  if (defined $val) {
    $self->{'_qbasis'} = $val;
  } else {
    return $self->{'_qbasis'};
  }
}

=item B<sections()>

Return the total number of sections defined.

=cut

sub sections {
  # Get self
  ($#_ == 0) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  # Return requested value
  return scalar(@{$self->{'_sect'}});
}

=item B<offset(i)>

Return the starting time offset of the given section.

C<i> must be an integer greater than or equal to zero and less than the
value returned by C<sections()>.

=cut

sub offset {
  # Get self and parameters
  ($#_ == 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $i = shift;
  (looks_like_number($i) and (int($i) == $i)) or die;
  (($i >= 0) and ($i < scalar(@{$self->{'_sect'}}))) or die;
  
  # Return requested value
  return $self->{'_sect'}->[$i];
}

=item B<sect(offs)>

Add another section.

C<offs> is the time offset the section should begin at.  It must be an
integer greater than or equal to the value defined by the previous
section, and it must not exceed C<NMF_MAXINT> from C<NMF::Const>.

The total number of defined sections may not exceed C<NMF_MAXSECT> from
C<NMF::Const>.

New NMF objects always start out with a single section defined that has
offset zero.

=cut

sub sect {
  # Get self and parameters
  ($#_ == 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $offs = shift;
  (looks_like_number($offs) and (int($offs) == $offs)) or die;
  (($offs >= $self->{'_sect'}->[-1]) and ($offs <= NMF_MAXINT)) or
    die "Sections must be chronological!\n";
  
  # Check not too many sections
  (scalar(@{$self->{'_sect'}}) < NMF_MAXSECT) or
    die "Too many sections defined!\n";
  
  # Add the section
  push @{$self->{'_sect'}}, ($offs);
}

=item B<notes()>

Return the total number of notes defined.

=cut

sub notes {
  # Get self
  ($#_ == 0) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  # Return requested value
  return scalar(@{$self->{'_note'}});
}

=item B<get(i)>

Get a requested note.

C<i> must be an integer greater than or equal to zero and less than the
value returned by C<notes()>.

Notes are not necessarily in chronological order!

The return value is a hash in list context that defines the following
keys:

  t     : time offset
  dur   : duration
  pitch : pitch
  art   : articulation
  sect  : section index
  layer : layer index

The values of each of these keys is an integer.  C<t> is greater than or
equal to zero, and less than C<NMF_MAXINT> defined in C<NMF::Const>.

C<dur> is in range [NMF_MINDUR, NMF_MAXDUR].  Values greater than zero
mean a regular note duration.  The value zero means a cue with no
duration.  Values less than zero are grace note indices leading up to
the time offset defined by C<t>.

C<pitch> is in range [NMF_MINPITCH, NMF_MAXPITCH].  It represents the
number of semitones away from middle C.

C<art> is an articulation index, in range [0, NMF_MAXART].

C<sect> is the (zero-based) index of one of the sections defined by this
NMF data object.

C<layer> is the (one-based) index of the layer.  The first layer is
layer one, not layer zero.  The range is [1, NMF_MAXSHORT+1].

=cut

sub get {
  # Get self and parameters
  ($#_ == 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $i = shift;
  (looks_like_number($i) and (int($i) == $i)) or die;
  (($i >= 0) and ($i < scalar(@{$self->{'_note'}}))) or die;
  
  # Get record
  my $rec = $self->{'_note'}->[$i];
  
  # Return parsed note descriptor
  return (
    't' => $rec->[0],
    'dur' => $rec->[1],
    'pitch' => $rec->[2],
    'art' => $rec->[3],
    'sect' => $rec->[4],
    'layer' => ($rec->[5] + 1)
  );
}

=item B<set(i, %note)>

Set a requested note.

C<i> must be an integer greater than or equal to zero and less than the
value returned by C<notes()>.

Notes are not necessarily in chronological order!

After the first parameter follows a list of key/value pairs that define
the properties of the note to update.  Only properties that are included
in the key/value pairs are changed, while the rest of the properties are
left at their current value.  Passing only the C<i> parameter and not
following it with any key/value pairs results in no changes to the note.

The following property keys may be specified, which are the same as the
property keys returned from C<get()>:

  t     : time offset
  dur   : duration
  pitch : pitch
  art   : articulation
  sect  : section index
  layer : layer index

See the documentation of C<get()> for further information about these
properties.

=cut

sub set {
  # Get self and first parameter
  ($#_ >= 1) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  my $i = shift;
  (looks_like_number($i) and (int($i) == $i)) or die;
  (($i >= 0) and ($i < scalar(@{$self->{'_note'}}))) or die;
  
  # Make sure remaining count of parameters is even, so we can pair them
  ((scalar(@_) % 2) == 0) or die;
  
  # Get and check all the properties that were passed
  my %pmap;
  while ($#_ >= 0) {
    # Get key and value
    my $key = shift;
    my $val = shift;
    
    # Check that key is scalar and value is integer
    (not ref($key)) or die;
    (looks_like_number($val) and (int($val) == $val)) or die;
    
    # Range check based on key
    if ($key eq 't') {
      (($val >= 0) and ($val <= NMF_MAXINT)) or die;
      
    } elsif ($key eq 'dur') {
      (($val >= NMF_MINDUR) and ($val <= NMF_MAXDUR)) or die;
      
    } elsif ($key eq 'pitch') {
      (($val >= NMF_MINPITCH) and ($val <= NMF_MAXPITCH)) or die;
      
    } elsif ($key eq 'art') {
      (($val >= 0) and ($val <= NMF_MAXART)) or die;
      
    } elsif ($key eq 'sect') {
      (($val >= 0) and ($val < scalar(@{$self->{'_sect'}}))) or die;
      
    } elsif ($key eq 'layer') {
      (($val >= 1) and ($val <= NMF_MAXSHORT + 1)) or die;
      
    } else {
      die;
    }
    
    # Add pair to property map
    $pmap{$key} = $val;
  }
  
  # Get record
  my $rec = $self->{'_note'}->[$i];
  
  # Update record
  while (my ($k, $v) = each %pmap) {
    if ($k eq 't') {
      $rec->[0] = $v;
      
    } elsif ($k eq 'dur') {
      $rec->[1] = $v;
      
    } elsif ($k eq 'pitch') {
      $rec->[2] = $v;
      
    } elsif ($k eq 'art') {
      $rec->[3] = $v;
      
    } elsif ($k eq 'sect') {
      $rec->[4] = $v;
      
    } elsif ($k eq 'layer') {
      $rec->[5] = $v - 1;
      
    } else {
      die;
    }
  }
}

=item B<append(%note)>

Append a new note.

You can add notes in any order you want.  They do not have to be
chronological.

The parameters of this function are a list of key/value pairs that
define the properties of the note to append.  The following property
keys must be specified, which are the same as the property keys returned
from C<get()>:

  t     : time offset
  dur   : duration
  pitch : pitch
  art   : articulation
  sect  : section index
  layer : layer index

See the documentation of C<get()> for further information about these
properties.

You must specify each of these properties for the new note, unlike for
the C<set()> function where you can just give a subset.

The total number of notes may not exceed the C<NMF_MAXNOTE> constant
defined in C<NMF::Const>.

=cut

sub append {
  # Get self
  ($#_ >= 0) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  # Make sure count of parameters is even, so we can pair them
  ((scalar(@_) % 2) == 0) or die;
  
  # Get and check all the properties that were passed
  my %pmap;
  while ($#_ >= 0) {
    # Get key and value
    my $key = shift;
    my $val = shift;
    
    # Check that key is scalar and value is integer
    (not ref($key)) or die;
    (looks_like_number($val) and (int($val) == $val)) or die;
    
    # Range check based on key
    if ($key eq 't') {
      (($val >= 0) and ($val <= NMF_MAXINT)) or die;
      
    } elsif ($key eq 'dur') {
      (($val >= NMF_MINDUR) and ($val <= NMF_MAXDUR)) or die;
      
    } elsif ($key eq 'pitch') {
      (($val >= NMF_MINPITCH) and ($val <= NMF_MAXPITCH)) or die;
      
    } elsif ($key eq 'art') {
      (($val >= 0) and ($val <= NMF_MAXART)) or die;
      
    } elsif ($key eq 'sect') {
      (($val >= 0) and ($val < scalar(@{$self->{'_sect'}}))) or die;
      
    } elsif ($key eq 'layer') {
      (($val >= 1) and ($val <= NMF_MAXSHORT + 1)) or die;
      
    } else {
      die;
    }
    
    # Add pair to property map
    $pmap{$key} = $val;
  }
  
  # Make sure we got all six properties
  (scalar(keys %pmap) == 6) or die;
  
  # Check we are not at the maximum note count
  (scalar(@{$self->{'_note'}}) < NMF_MAXNOTE) or
    die "Too many notes defined in NMF!\n";
  
  # Add record
  push @{$self->{'_note'}}, ([
    $pmap{'t'},
    $pmap{'dur'},
    $pmap{'pitch'},
    $pmap{'art'},
    $pmap{'sect'},
    $pmap{'layer'}
  ]);
}

=item B<sort_notes()>

Sort all the notes define in the NMF data object so that they are in
chronological order.

The notes are sorted first by their C<t> offset.  For notes that have
the same C<t> offset, they are sorted in ascending order of their C<dur>
value.

=cut

sub sort_notes {
  # Get self
  ($#_ == 0) or die;
  
  my $self = shift;
  (ref($self) and $self->isa(__PACKAGE__)) or die;
  
  # Get a sorted list of notes
  my @sorted = sort _nmf_cmp @{$self->{'_note'}};
  
  # Replace note list with our sorted list
  $self->{'_note'} = \@sorted;
}

=back

=head1 AUTHOR

Noah Johnson E<lt>noah.johnson@loupmail.comE<gt>

=head1 COPYRIGHT

Copyright 2023 Multimedia Data Technology, Inc.

This program is free software.  You can redistribute it and/or modify it
under the same terms as Perl itself.

This program is also dual-licensed under the MIT license:

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

# End with something that evaluates to true
1;
