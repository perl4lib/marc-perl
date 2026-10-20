##!perl -Tw

use Test::More tests => 31;

use strict;
use MARC::Record;
use MARC::Batch;
use MARC::File::USMARC;
use Encode;
use File::Spec;
use utf8;

## we are going to create a MARC record with a utf8 character in
## it (a Hebrew Aleph), write it to disk, and then attempt to
## read it back from disk as a MARC::Record.

my $aleph = chr(0x05d0);
ok( Encode::is_utf8($aleph), 'is_utf8()' );
my $filename = File::Spec->catfile( 't', 'utf8.marc' );

CREATE_FILE: {
    my $r = MARC::Record->new();
    isa_ok( $r, 'MARC::Record' );

    is( $r->encoding(), 'MARC-8', 'default encoding' );
    $r->encoding( 'UTF-8' );
    is( $r->encoding(), 'UTF-8', 'set encoding' );

    my $f = MARC::Field->new( 245, 0, 0, a => $aleph, c => 'Mr. Foo' );
    isa_ok( $f, 'MARC::Field' );

    my $nadds = $r->append_fields( $f );
    is( $nadds, 1, "Added one field" );

    ## write record to disk, telling perl (as we should) that we
    ## will be writing utf8 unicode
    open( my $OUT, '>', $filename );
    binmode( $OUT, ':utf8' ); # so we don't get a warning
    print $OUT $r->as_usmarc();
    close( $OUT );
}

## open the file back up, get the record, and see if our Aleph
## is there

REREAD_FILE: {
    my $f = MARC::File::USMARC->in( $filename );
    isa_ok( $f, 'MARC::File::USMARC' );

    my $r = $f->next();
    isa_ok( $r, 'MARC::Record' );

    # check encoding
    is( $r->encoding(), 'UTF-8', 'encoding is utf-8' );

    # check for warnings
    is( scalar( $r->warnings() ), 0, 'Reading it generated no warnings' ); 

    my $a = $r->field( 245 )->subfield( 'a' );
    ok( Encode::is_utf8( $a ), 'got actual utf8' );
    is( $a, $aleph, 'got aleph' );

    unlink( $filename );
}

WRITE_ANSEL: {
    my $r = MARC::Record->new();
    isa_ok( $r, 'MARC::Record' );
    is( $r->encoding(), 'MARC-8', 'default encoding' );

    my $f = MARC::Field->new( 245, 0, 0, a => "foo".chr(0xE2)."e" );
    isa_ok( $f, 'MARC::Field' );

    my $nadds = $r->append_fields( $f );
    is( $nadds, 1, "Added one field" );

    open( my $OUT, '>', $filename );
    print $OUT $r->as_usmarc();
    close( $OUT );    
}

READ_ANSEL: {
    my $f = MARC::File::USMARC->in( $filename );
    isa_ok( $f, 'MARC::File::USMARC' );

    my $r = $f->next();
    isa_ok( $r, 'MARC::Record' );
    is( scalar( $r->warnings() ), 0, 'Reading it generated no warnings' ); 

    is( $r->field('245')->subfield('a'), "foo".chr(0xE2)."e", 'non-utf8' );
    unlink( $filename );
}

# UTF-8 record that claims it's UTF-8
my $r1 = MARC::Record->new;
$r1->leader( '00000nam a2200000 a 4500' );
$r1->append_fields( MARC::Field->new( '245', '1', '0', a => "Caf\x{e9} \x{4e2d}\x{6587}" ) );
my $title1 = $r1->title();
is( $title1, 'Café 中文', 'Can create record using non-ASCII Unicode characters and get back correct title' );

my $marc1 = $r1->as_usmarc;
my $r2 = MARC::File::USMARC::decode( $marc1 );
is( scalar( $r2->warnings() ), 0, 'Got no warnings after generating ISO2709 record and parsing it again' );
my $title2 = $r2->title();
is( $title1, $title2, 'Title remains the same after round trip' );

# Non UTF-8 record that claims it's UTF-8
my $r3 = MARC::Record->new;
$r3->leader( '00000nam a2200000 a 4500' );
$r3->append_fields( MARC::Field->new( '245', '1', '0', a => "Caf\x{e9}" ) ); # string is _not_ UTF-8;
                                                                             # would need characters with codepoint
                                                                             # higher than U+00FF in the literal
                                                                             # to be promoted to UTF-8
my $title3 = $r3->title();
is( $title3, "Caf\x{e9}", 'Non-UTF-8 title preserved' );
isnt( $title3, $title1, 'Non-UTF-8 and UTF-8 titles do not match' );

my $marc3 = $r3->as_usmarc;
my $r4 = MARC::File::USMARC::decode( $marc3 );
my @r4warnings = $r4->warnings();
is( scalar @r4warnings, 1, 'Got one warning after generating ISO2709 record that is not UTF-8 but claims to be and parsing it again' );
like( $r4warnings[0], qr/Could not mark string as UTF-8 for/, 'Correctly identified byte sequence that is not UTF-8' );
my $title4 = $r4->title();
is( $title3, $title4, 'Title remains the same after round trip' );

# MARC-8 record that claims it's MARC-8
my $r5 = MARC::Record->new;
$r5->leader( '00000nam  2200000 a 4500' );
$r5->append_fields( MARC::Field->new( '245', '1', '0', a => "Caf\x{e2}e" ) ); # MARC-8
my $title5 = $r5->title();
is( $title5, "Caf\x{e2}e", 'MARC-8 title preserved' );

my $marc5 = $r5->as_usmarc;
my $r6 = MARC::File::USMARC::decode( $marc5 );
is( scalar( $r6->warnings() ), 0, 'Got no warnings after generating MARC-8 ISO2709 record and parsing it again' );
my $title6 = $r6->title();
is( $title5, $title6, 'MARC-8 title remains the same after round trip' );
