use strict;
use warnings;
use Test::More tests => 19;
use XML::LibXML;

# test escaping of ' " < > and & for XML

use_ok( 'MARC::File::XML' );

is( MARC::File::XML::escape( 'foo&bar&baz' ), 'foo&amp;bar&amp;baz', '&' );
is( MARC::File::XML::escape( 'foo>bar>baz' ), 'foo&gt;bar&gt;baz', '>' );
is( MARC::File::XML::escape( 'foo<bar<baz' ), 'foo&lt;bar&lt;baz', '<' );
is( MARC::File::XML::escape( 'foo"baz' ), 'foo&quot;baz', '"' );
is( MARC::File::XML::escape( 'foo' . q(') . 'baz' ), 'foo&apos;baz', "'" );

use_ok( 'MARC::Record' );
use_ok( 'MARC::Field' );
use_ok( 'MARC::Batch' );

my $r1 = MARC::Record->new();
isa_ok( $r1, 'MARC::Record' );

$r1->leader( '&xyz<123>' );
$r1->append_fields(
    MARC::Field->new( '005', '&abc<def>' ),
    MARC::Field->new( '245', 0, 1, a => 'Foo&Bar<Baz>' ),
    MARC::Field->new( '650', ' ', ' ', "'" => 'Topic', '"' => 'Topic 2' ),
);

my $xml1 = $r1->as_xml();
like( $xml1, qr/&amp;xyz&lt;123&gt;/, 'escaped leader' );
like( $xml1, qr/&amp;abc&lt;def&gt;/, 'escape control field' );
like( $xml1, qr/Foo&amp;Bar&lt;Baz&gt;/, 'escaped field' );
like( $xml1, qr/code=.&apos;./, 'escaped single quote in subfield code' );
like( $xml1, qr/code=.&quot;./, 'escaped double quote in subfield code' );

my $parser = XML::LibXML->new();
eval {
    my $doc = $parser->parse_string($xml1);
};
if ($@) {
    fail('XML produced from a MARC::Record with quotes as subfield labels fails to parse');
    diag($@);
} else {
    pass('XML produced from a MARC::Record with quotes as subfield labels successfully parsed');
}

# check escaping of subfield labels
my $b = MARC::Batch->new( 'USMARC', 't/escape.mrc' );
my $r2 = $b->next();
is($r2->subfield('650', '<'), 'France', 'read subfield $< parsed from ISO2709 blob');
my $xml2 = $r2->as_xml();
my $r3;
SKIP: {
    eval { $r3 = MARC::Record->new_from_xml($xml2); };
    if ($@) {
        fail('failed to parse MARCXML generated from record containing a subfield $<');
	skip 'no point in checking further', 1;
    } else {
        is($r3->subfield('650', '<'), 'France', 'read subfield $< parsed from MARCXML');
	is_deeply($r2, $r3, 'record with subfield $< the same parsed from ISO2709 or MARCXML');
    }
}

