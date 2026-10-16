# Contributing to MARC/Perl

Thank you for your interest in improving MARC/Perl! Bug reports, documentation
fixes, tests and patches are all welcome.

## Reporting bugs and requesting features

Please open an issue at <https://github.com/perl4lib/marc-perl/issues> and
say which distribution it concerns (for example `marc-record` or `marc-xml`).
A short script or a small sample record that reproduces the problem helps a
great deal. Questions about using the modules are better asked on the
[perl4lib mailing list](https://perl4lib.perl.org/).

Please do not report security problems in public issues; see
[SECURITY.md](SECURITY.md).

## Repository layout

This is a monorepo of separately released CPAN distributions, each with its
own `Makefile.PL` (or `Build.PL` for `marc-mij`), `lib/`, `t/`, `MANIFEST`,
`Changes` and `README.pod`:

`marc-record`, `marc-lint`, `marc-xml`, `marc-charset`, `marc-mij`,
`marc-marcmaker` (and `marc-www`, the legacy project website).

`marc-record` is the core; the others depend on it, and `marc-xml` also
depends on `marc-charset`.

## Running the tests

Run the tests from inside the distribution you are changing. Sibling
distributions are not on `@INC` automatically, so point `prove` at them with
`-I` when a distribution depends on one:

```sh
cd marc-record     && prove -l t/
cd marc-lint       && prove -l -I../marc-record/lib t/
cd marc-xml        && prove -l -I../marc-record/lib -I../marc-charset/lib t/
cd marc-marcmaker  && prove -l -I../marc-record/lib t/
cd marc-mij        && prove -l -I../marc-record/lib t/
cd marc-charset    && prove -l t/
```

`-l` adds the distribution's own `lib/`. The usual `perl Makefile.PL && make
&& make test` flow also works (`marc-mij` uses `perl Build.PL && ./Build &&
./Build test`).

**`marc-charset` needs its character database built first.**
`MARC::Charset::Table` is generated from `marc-charset/etc/*.xml` and is not
committed. `make` builds it automatically, but if you run `prove -l` directly
you need to build it once:

```sh
cd marc-charset && perl -Ilib build_db.PL
```

Without it most `marc-charset` tests, and any `marc-xml` test touching
non-ASCII data, fail with "no mapping found". If those tests fail, check for
the database before suspecting a code regression.

Continuous integration runs every distribution's tests on each pull request.

## Submitting a pull request

* Keep each pull request focused on one change.
* Add or update tests for any behaviour change or bug fix.
* Update the POD when you change documented behaviour.
* Explain the change and its motivation in the commit message or the pull
  request description, including a short changelog-style summary if the change
  is user-visible.
* **Please do not bump `$VERSION` or edit a distribution's `Changes` file.**
  Those are release-time activities handled by the maintainers when a release
  is cut, and doing them in a pull request adds friction.

## License

MARC/Perl is released under the same terms as Perl itself. By contributing you
agree that your contribution may be distributed under those terms.
