# MARC/Perl

[![CI](https://github.com/perl4lib/marc-perl/actions/workflows/ci.yml/badge.svg)](https://github.com/perl4lib/marc-perl/actions/workflows/ci.yml)

MARC/Perl is a set of Perl 5 libraries for reading, manipulating,
outputting and converting bibliographic records in the MARC format.
The MAchine Readable Cataloging format was designed by the Library
of Congress in the late 1960s in order to allow libraries to convert
their card catalogs into a digital format. The MARC format was
standardized as ANSI/NISO Z39.2 in 1971 and is now being used by
libraries around the world to provide computerized access to their
collections.

## Distributions

This repository is a monorepo. Each directory is a separately
released CPAN distribution with its own `Makefile.PL` (or `Build.PL`),
`Changes` and version number:

| Directory | CPAN distribution | Purpose |
|---|---|---|
| [`marc-record`](marc-record) | [MARC-Record](https://metacpan.org/dist/MARC-Record) | core MARC processing library |
| [`marc-lint`](marc-lint) | [MARC-Lint](https://metacpan.org/dist/MARC-Lint) | examine your MARC data for common problems |
| [`marc-xml`](marc-xml) | [MARC-File-XML](https://metacpan.org/dist/MARC-File-XML) | extensions to marc-record for working with MARCXML |
| [`marc-mij`](marc-mij) | [MARC-File-MiJ](https://metacpan.org/dist/MARC-File-MiJ) | extensions to marc-record for working with marc-in-json |
| [`marc-marcmaker`](marc-marcmaker) | [MARC-File-MARCMaker](https://metacpan.org/dist/MARC-File-MARCMaker) | extensions to marc-record to handle MARCMaker format |
| [`marc-charset`](marc-charset) | [MARC-Charset](https://metacpan.org/dist/MARC-Charset) | work with MARC-8 and UTF-8 encodings |
| [`marc-www`](marc-www) | | the original project website (legacy) |

## Getting help

* Questions and discussion: the
  [perl4lib mailing list](https://perl4lib.perl.org/).
* Bug reports and feature requests:
  [GitHub issues](https://github.com/perl4lib/marc-perl/issues).
  Please say which distribution the report is about.

## Contributing

Patches and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)
for how to run the tests and what to include in a pull request. Security
issues should be reported as described in [SECURITY.md](SECURITY.md).

## Source code

The canonical repository is <https://github.com/perl4lib/marc-perl>.
