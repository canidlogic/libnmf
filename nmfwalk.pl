#!/usr/bin/env perl
use v5.14;
use warnings;

# NMF imports
use NMF::Data;

=head1 NAME

nmfwalk.pl - Walk through a Noir Music File (NMF).

=head1 SYNOPSIS

  ./nmfwalk.pl < input.nmf
  ./nmfwalk.pl -check < input.nmf

=head1 DESCRIPTION

Read through an NMF file, verify it, and optionally print a textual
description of its data.

Both invocations read an NMF file from standard input and verify it.
 
The C<-check> invocation does nothing beyond verifying the NMF file.

The parameter-less invocation also prints out a textual description of
the data within the NMF file to standard output.

=cut

# ===============
# Local functions
# ===============

# report(pd)
# ----------
#
# Print a textual representation of an NMF::Data object to standard
# output.
#
sub report {
  # Get parameters
  ($#_ == 0) or die;
  
  my $pd = shift;
  (ref($pd) and $pd->isa('NMF::Data')) or die;
  
  # Print the basis
  if ($pd->basis == -1) {
    print  "BASIS   : 96 quanta per quarter\n"
  } else {
    printf "BASIS   : %d quanta per second\n", $pd->basis;
  }
  
  # Print section and note counts
  printf "SECTIONS: %d\n", $pd->sections;
  printf "NOTES   : %d\n", $pd->notes;
  print  "\n";
  
  # Print each section location
  for(my $i = 0; $i < $pd->sections; $i++) {
    printf "SECTION %d AT %d\n", $i, $pd->offset($i);
  }
  print "\n";
  
  # Print each note
  for(my $i = 0; $i < $pd->notes; $i++) {
    
    # Get the note
    my %note = $pd->get($i);
    
    # Print the information
    printf "NOTE T=%ld DUR=%ld P=%d A=%ld S=%ld L=%ld\n",
      $note{'t'}, $note{'dur'}, $note{'pitch'},
      $note{'art'}, $note{'sect'}, $note{'layer'};
  }
}

# ==================
# Program entrypoint
# ==================

# Get program mode
#
my $is_silent = 0;
if (scalar(@ARGV) == 1) {
  my $mode = shift;
  ($mode eq '-check') or die "Unrecognized mode '$mode'!\n";
  $is_silent = 1;
  
} elsif (scalar(@ARGV) == 0) {
  $is_silent = 0;
  
} else {
  die "Wrong number of program arguments!\n";
}

# Parse standard input as an NMF file
#
my $nmf = NMF::Data->create;
$nmf->parse_stdin;
  
# If not silent, then report the contents
unless ($is_silent) {
  report($nmf);
}
