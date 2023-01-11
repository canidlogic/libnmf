# NAME

NMF::Data - Noir Music File (NMF) data object.

# SYNOPSIS

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

# DESCRIPTION

Represents all the data in an NMF file.

NMF data is stored in memory.  After construction with `create()`, the
data object is in a default initial state.  You can either start
defining a new NMF file from this default initial state or you can load
an existing NMF file with `parse()`.  `parse()` accepts a binary
string reference holding the whole NMF file, but wrapper functions
`parse_stdin()` and `parse_path()` are available to read an NMF file
from standard input or a file path, respectively.

At any point in time, the current state of an NMF data object can be
serialized into an NMF file.  The `serialize()` function writes the
resulting file into a binary string reference.  Wrapper functions
`serialize_stdout()` and `serialize_path()` are available to write an
NMF file to standard output or a file path, respectively.

The rest of the functions allow the data within the NMF file to be
inspected and edited.  The `basis()` function both reads and writes the
quantum basis of the NMF data.  `sections()` and `notes()` counts the
total number of sections and notes currently in the data object.  The
`offset()` function queries existing section offsets and `sect()` adds
new section definitions.  `get()`, `set()`, and `append()` allow
individual notes to be read, edited, and appended.

NMF does not require notes to be sorted in chronological order.  If you
want to get them in chronological order, the `sort_notes()` function
will sort all the currently defined notes.

# CONSTRUCTOR

- **create()**

    Create a new NMF data object.

    The data object starts out with a quantum basis of 96 quanta per quarter
    note, a single section defined at offset zero, and no notes defined.

# PUBLIC INSTANCE METHODS

- **parse(binary\_ref)**

    Deserialize NMF data from an NMF file.

    `binary_ref` is a reference to a scalar storing the whole NMF file in a
    binary string.

    The state of the NMF data object is completely replaced with the data
    parsed from the given file.  Errors are thrown if there are any parsing
    problems.

- **serialize(binary\_ref)**

    Serialize NMF data into an NMF file.

    `binary_ref` is a reference to a scalar that will be overwritten with
    the serialized NMF file based on the current state of the data object.

    At least one note must be defined in the data object.

- **parse\_stdin()**

    Wrapper around `parse()` that reads an NMF file from standard input.

- **parse\_path(path)**

    Wrapper around `parse()` that reads an NMF file from a file path.

- **serialize\_stdout()**

    Wrapper around `serialize()` that writes an NMF file to standard
    output.

- **serialize\_path(path)**

    Wrapper around `serialize()` that writes an NMF file to a file path.

- **basis(\[hz\])**

    Get or set the quantum basis of the NMF data.

    The valid basis values are integers -1, 44100, 48000, and anything in
    range \[1, 1024\].  The value -1 means 96 quanta per quarter note.  All
    other values are fixed rates given in Hz.

    If a parameter is passed, the quantum basis is changed to the given
    basis.  None of the note events are changed by this function.  Only the
    recorded quantum basis is updated.

    If no parameter is passed, the current quantum basis is returned.

- **sections()**

    Return the total number of sections defined.

- **offset(i)**

    Return the starting time offset of the given section.

    `i` must be an integer greater than or equal to zero and less than the
    value returned by `sections()`.

- **sect(offs)**

    Add another section.

    `offs` is the time offset the section should begin at.  It must be an
    integer greater than or equal to the value defined by the previous
    section, and it must not exceed `NMF_MAXINT` from `NMF::Const`.

    The total number of defined sections may not exceed `NMF_MAXSECT` from
    `NMF::Const`.

    New NMF objects always start out with a single section defined that has
    offset zero.

- **notes()**

    Return the total number of notes defined.

- **get(i)**

    Get a requested note.

    `i` must be an integer greater than or equal to zero and less than the
    value returned by `notes()`.

    Notes are not necessarily in chronological order!

    The return value is a hash in list context that defines the following
    keys:

        t     : time offset
        dur   : duration
        pitch : pitch
        art   : articulation
        sect  : section index
        layer : layer index

    The values of each of these keys is an integer.  `t` is greater than or
    equal to zero, and less than `NMF_MAXINT` defined in `NMF::Const`.

    `dur` is in range \[NMF\_MINDUR, NMF\_MAXDUR\].  Values greater than zero
    mean a regular note duration.  The value zero means a cue with no
    duration.  Values less than zero are grace note indices leading up to
    the time offset defined by `t`.

    `pitch` is in range \[NMF\_MINPITCH, NMF\_MAXPITCH\].  It represents the
    number of semitones away from middle C.

    `art` is an articulation index, in range \[0, NMF\_MAXART\].

    `sect` is the (zero-based) index of one of the sections defined by this
    NMF data object.

    `layer` is the (one-based) index of the layer.  The first layer is
    layer one, not layer zero.  The range is \[1, NMF\_MAXSHORT+1\].

- **set(i, %note)**

    Set a requested note.

    `i` must be an integer greater than or equal to zero and less than the
    value returned by `notes()`.

    Notes are not necessarily in chronological order!

    After the first parameter follows a list of key/value pairs that define
    the properties of the note to update.  Only properties that are included
    in the key/value pairs are changed, while the rest of the properties are
    left at their current value.  Passing only the `i` parameter and not
    following it with any key/value pairs results in no changes to the note.

    The following property keys may be specified, which are the same as the
    property keys returned from `get()`:

        t     : time offset
        dur   : duration
        pitch : pitch
        art   : articulation
        sect  : section index
        layer : layer index

    See the documentation of `get()` for further information about these
    properties.

- **append(%note)**

    Append a new note.

    You can add notes in any order you want.  They do not have to be
    chronological.

    The parameters of this function are a list of key/value pairs that
    define the properties of the note to append.  The following property
    keys must be specified, which are the same as the property keys returned
    from `get()`:

        t     : time offset
        dur   : duration
        pitch : pitch
        art   : articulation
        sect  : section index
        layer : layer index

    See the documentation of `get()` for further information about these
    properties.

    You must specify each of these properties for the new note, unlike for
    the `set()` function where you can just give a subset.

    The total number of notes may not exceed the `NMF_MAXNOTE` constant
    defined in `NMF::Const`.

- **sort\_notes()**

    Sort all the notes define in the NMF data object so that they are in
    chronological order.

    The notes are sorted first by their `t` offset.  For notes that have
    the same `t` offset, they are sorted in ascending order of their `dur`
    value.

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
