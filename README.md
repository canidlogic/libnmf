# Noir Music Format (NMF) library

Provides a parsing library and utilities for working with files in the binary Noir Music Format (NMF).

__This is not the current Noir binary format.__  You probably instead are looking for `libnrb` which can be found [here](https://www.purl.org/canidtech/r/libnrb).  This library `libnmf` is only useful if you are handling binary files produced by the original Noir, beta 0.5.2 or earlier.

See `NMF_Spec.md` for a specification of this binary NMF format.

The whole NMF parsing library is contained within the `nmf.h` and `nmf.c` source files.  See the documentation in the header file for the API specification.

To check an NMF file and print a textual listing of its contents, you can use the included `nmfwalk` utility program.

To convert an NMF file with a quantum basis of 96 quanta per quarter note into an NMF file with a 44.1kHz or 48kHz quanta rate, you can use the `nmfrate` and `nmftempo` utility programs.  `nmfrate` uses a fixed tempo for the conversion.  `nmftempo` allows for variable tempi, including gradual tempo changes.  However, you must create a separate tempo map file in order to use `nmftempo`.  See the sample tempo map `Tempo_Map.txt` for further information.

To convert an NMF file into a data format that can be used with the Retro synthesizer, you can use the `nmfgraph` and `nmfsimple` utility programs.  `nmfsimple` converts an NMF file into a sequence of note events that can be included in a Retro synthesis script.  `nmfgraph` can convert specially-formatted NMF files into dynamic graphs for use with Retro.

## Releases

### Version 0.9 Beta

Copying files from Noir beta 0.5.2, and applying just a few edits to documentation to account for the project now being separate from the main Noir project.
