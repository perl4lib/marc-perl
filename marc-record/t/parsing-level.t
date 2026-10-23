#!perl -Tw

use strict;
use warnings;
use Test::More tests => 8;

use_ok( 'MARC::File::USMARC' );
use_ok( 'MARC::Record' );

# A well-formed record, and a copy of it with a corrupt terminator.
my $good = MARC::Record->new();
$good->leader( '00000nam  22000007a 4500' );
$good->append_fields( MARC::Field->new( '245', '1', '0', a => 'A title' ) );
my $usmarc = $good->as_usmarc();

is( $MARC::File::USMARC::PARSING_LEVEL, 'lenient', "the parsing level is 'lenient' unless asked otherwise" );

# Corrupt the record terminator so decode() has something to warn about.
my $bad = substr( $usmarc, 0, -1 ) . 'X';

{
    local $MARC::File::USMARC::PARSING_LEVEL = 'lenient';
    my $r = eval { MARC::File::USMARC->decode( $bad ) };
    ok( $r && !$@, 'lenient: a bad record terminator does not die' ) or diag( $@ );
    ok( scalar( grep { /terminator/ } $r->warnings ), 'lenient: a warning is recorded' );
}

{
    local $MARC::File::USMARC::PARSING_LEVEL = 'strict';
    eval { MARC::File::USMARC->decode( $bad ) };
    like( $@, qr/Invalid record terminator/, 'strict: a bad record terminator dies' );

    my $r = eval { MARC::File::USMARC->decode( $usmarc ) };
    ok( $r && !$@, 'strict: a well-formed record still decodes' ) or diag( $@ );
}

{
    local $MARC::File::USMARC::PARSING_LEVEL = 'bogus';
    eval { MARC::File::USMARC->decode( $usmarc ) };
    like( $@, qr/Unknown parsing level 'bogus' \(expected one of: lenient, strict\)/, 'an unknown parsing level dies' );
}
