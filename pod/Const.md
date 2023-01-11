# NAME

NMF::Const - Constant definitions for Noir Music File (NMF).

# SYNOPSIS

    use NMF::Const;

# DESCRIPTION

Importing this module will define NMF constants, documented below.

# CONSTANTS

- **NMF\_MAXINT**

    The maximum value of a 32-bit integer stored in an NMF file.
    (2,147,483,647)

- **NMF\_MAXSHORT**

    The maximum value of a 16-bit integer stored in an NMF file.
    (65,535)

- **NMF\_MAXDUR**

    The maximum value of a note duration stored in an NMF file. (32,767)

- **NMF\_MINDUR**

    The minimum value of a note duration stored in an NMF file. (-32,767)

- **NMF\_MAXSECT**

    The maximum number of sections within an NMF file.  (65,535)

- **NMF\_MAXNOTE**

    The maximum number of notes within an NMF file.  (1,048,576)

- **NMF\_MINPITCH**

    The minimum pitch of note, as a semitone displacement from middle C.
    (-39)

- **NMF\_MAXPITCH**

    The maximum pitch of note, as a semitone displacement from middle C.
    (48)

- **NMF\_MAXART**

    The maximum articulation value.  (61)

# AUTHOR

Noah Johnson <noah.johnson@loupmail.com>

# COPYRIGHT

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
