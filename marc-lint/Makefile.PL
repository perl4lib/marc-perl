use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME          => 'MARC::Lint',
    DISTNAME      => 'MARC-Lint',
    VERSION_FROM  => 'lib/MARC/Lint.pm',
    ABSTRACT_FROM => 'lib/MARC/Lint.pm',
    AUTHOR        => 'Bryan Baldus <eijabb@cpan.org>',
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/perl4lib/marc-perl',
            repository => {
                type => 'git',
                url  => 'https://github.com/perl4lib/marc-perl.git',
                web  => 'https://github.com/perl4lib/marc-perl/tree/master/marc-lint',
            },
            bugtracker => {
                web => 'https://github.com/perl4lib/marc-perl/issues',
            },
        },
    },
    LICENSE       => 'perl',
    MIN_PERL_VERSION => '5.008008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM     => {
                        'MARC::Record' => 0,
                        'Business::ISBN' => 0,
                     },
    EXE_FILES     => [ qw( bin/marclint ) ],
);
