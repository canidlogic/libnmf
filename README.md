# Noir Music Format (NMF) library

Provides a parsing library for working with files in the binary Noir Music Format (NMF).

See `NMF_Spec.md` in the `doc` directory for a specification of this binary NMF format.

Two versions of this library are provided:  a C version and a Perl version.  The C library is contained within the `nmf.h` and `nmf.c` source files.  See the documentation in the header file for the API specification.  The Perl library modules are contained within the `NMF` subdirectory.  See the POD documentation in the `pod` subdirectory for documentation of the Perl interface.

To check an NMF file and print a textual listing of its contents, you can use the included `nmfwalk` utility program.  Two versions of the program are provided, a C version using the C library and a Perl version using the Perl library.

## Releases

### Version 0.9.2 Beta

Added support for fixed quantum bases in range [1 Hz, 1024 Hz].  Added a pure Perl implementation alongside the C implementation.

### Version 0.9.1 Beta

Spun off legacy tools to the [nmftools](https://www.purl.org/canidtech/r/nmftools) project.  Updated documentation to indicate that NMF is still the current binary format.  The deprecation of NMF in favor of NRB mentioned in the version 0.9.0 beta is no longer in effect.

### Version 0.9.0 Beta

Copying files from Noir beta 0.5.2, and applying just a few edits to documentation to account for the project now being separate from the main Noir project.
