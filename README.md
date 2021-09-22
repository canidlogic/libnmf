# Noir Music Format (NMF) library

Provides a parsing library for working with files in the binary Noir Music Format (NMF).

See `NMF_Spec.md` in the `doc` directory for a specification of this binary NMF format.

The whole NMF parsing library is contained within the `nmf.h` and `nmf.c` source files.  See the documentation in the header file for the API specification.

To check an NMF file and print a textual listing of its contents, you can use the included `nmfwalk` utility program.

## Releases

### Version 0.9.1 Beta

Spun off legacy tools to the [nmftools](https://www.purl.org/canidtech/r/nmftools) project.  Updated documentation to indicate that NMF is still the current binary format.  The deprecation of NMF in favor of NRB mentioned in the version 0.9.0 beta is no longer in effect.

### Version 0.9.0 Beta

Copying files from Noir beta 0.5.2, and applying just a few edits to documentation to account for the project now being separate from the main Noir project.
