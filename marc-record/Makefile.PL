# vi:et:sw=4 ts=4
require v5.8.8;
use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME            => 'MARC::Record',
    DISTNAME        => 'MARC-Record',
    VERSION_FROM    => 'lib/MARC/Record.pm',
    ABSTRACT_FROM   => 'lib/MARC/Record.pm',
    PMLIBDIRS       => [ qw( lib/ ) ],
    AUTHOR          => 'Galen Charlton <gmcharlt@gmail.com>',
    LICENSE         => 'perl',
    MIN_PERL_VERSION => '5.008008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES   => {
        'Test::More' => 0,
    },
    META_MERGE      => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/perl4lib/marc-perl',
            repository => {
                type => 'git',
                url  => 'https://github.com/perl4lib/marc-perl.git',
                web  => 'https://github.com/perl4lib/marc-perl/tree/master/marc-record',
            },
            bugtracker => {
                web => 'https://github.com/perl4lib/marc-perl/issues',
            },
        },
    },
    PREREQ_PM       => {
        'File::Spec' => 0,
        'File::Find' => 0,
        'Carp' => 0,
    },
    EXE_FILES       => [ qw( bin/marcdump ) ],
    dist            => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
    },
    depend          => {
        Makefile => '$(VERSION_FROM)'
    },
    clean           => { FILES => 'MARC-Record-*' },
    
);
