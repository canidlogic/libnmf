package NMF::Const;
use v5.14;
use warnings;
use parent qw(Exporter);

=head1 NAME

NMF::Const - Constant definitions for Noir Music File (NMF).

=head1 SYNOPSIS

  use NMF::Const;

=head1 DESCRIPTION

Importing this module will define NMF constants, documented below.

=head1 CONSTANTS

=over 4

=item B<NMF_MAXINT>

The maximum value of a 32-bit integer stored in an NMF file.
(2,147,483,647)

=cut

use constant NMF_MAXINT => 2147483647;

=item B<NMF_MAXSHORT>

The maximum value of a 16-bit integer stored in an NMF file.
(65,535)

=cut

use constant NMF_MAXSHORT => 65535;

=item B<NMF_MAXDUR>

The maximum value of a note duration stored in an NMF file. (32,767)

=cut

use constant NMF_MAXDUR => 32767;

=item B<NMF_MINDUR>

The minimum value of a note duration stored in an NMF file. (-32,767)

=cut

use constant NMF_MINDUR => 32767;

=item B<NMF_MAXSECT>

The maximum number of sections within an NMF file.  (65,535)

=cut

use constant NMF_MAXSECT => 65535;

=item B<NMF_MAXNOTE>

The maximum number of notes within an NMF file.  (1,048,576)

=cut

use constant NMF_MAXNOTE => 1048576;

=item B<NMF_MINPITCH>

The minimum pitch of note, as a semitone displacement from middle C.
(-39)

=cut

use constant NMF_MINPITCH => -39;

=item B<NMF_MAXPITCH>

The maximum pitch of note, as a semitone displacement from middle C.
(48)

=cut

use constant NMF_MAXPITCH => 48;

=item B<NMF_MAXART>

The maximum articulation value.  (61)

=cut

use constant NMF_MAXART => 61;

=back

=cut

# ==============
# Module exports
# ==============

our @EXPORT = qw(
  NMF_MAXSECT
  NMF_MAXINT
  NMF_MAXSHORT
  NMF_MAXDUR
  NMF_MINDUR
  NMF_MAXNOTE
  NMF_MINPITCH
  NMF_MAXPITCH
  NMF_MAXART
);

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
