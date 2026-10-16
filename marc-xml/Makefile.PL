use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'MARC::File::XML',
    'DISTNAME'      => 'MARC-File-XML',
    'VERSION_FROM'  => 'lib/MARC/File/XML.pm',
    'PMLIBDIRS'     => [ qw( lib/ ) ],
    'AUTHOR'        => [
                            'Ed Summers <ehs@pobox.com>',
                            'Galen Charlton <gmcharlt@gmail.com>',
                       ],
    'LICENSE'       => 'perl',
    'MIN_PERL_VERSION' => '5.008002',
    'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => '6.64',
                       },
    'META_MERGE'    => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/perl4lib/marc-perl',
            repository => {
                type => 'git',
                url  => 'https://github.com/perl4lib/marc-perl.git',
                web  => 'https://github.com/perl4lib/marc-perl/tree/master/marc-xml',
            },
            bugtracker => {
                web => 'https://github.com/perl4lib/marc-perl/issues',
            },
        },
    },
    'PREREQ_PM'     => {
                            'XML::LibXML'   => 1.66,
                            'MARC::Record'  => 2.0,
                            'MARC::Charset' => 0.98,
                       },
    'TEST_REQUIRES' => {
                            'Test::More' => 0,
                            'Test::Warn' => 0,
                       },
    'EXE_FILES'         => [ qw( bin/marc2xml bin/xml2marc ) ]
);
