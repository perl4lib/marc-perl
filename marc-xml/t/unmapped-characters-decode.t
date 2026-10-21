use strict;
use warnings;
use Test::More tests => 7;
use MARC::Record;
use MARC::Charset;
use MARC::File::XML;

# Leader/09 is 'a', so decode() converts to MARC-8 when asked for it. The
# 520 holds U+1F600, which has no MARC-8 mapping, among text that does.
my $xml = qq{<record xmlns="http://www.loc.gov/MARC21/slim">}
        . qq{<leader>00000nam a2200000 a 4500</leader>}
        . qq{<datafield tag="245" ind1="1" ind2="0"><subfield code="a">Caf\x{e9}</subfield></datafield>}
        . qq{<datafield tag="520" ind1=" " ind2=" "><subfield code="a">Before \x{1F600}smile after</subfield></datafield>}
        . qq{</record>};

# MARC::Charset warns about each character it can't map.
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

is( $MARC::File::XML::OUTPUT_LEVEL, 'strict', "the output level is 'strict' unless asked otherwise" );

{
    local $MARC::File::XML::OUTPUT_LEVEL = 'strict';
    @warnings = ();
    my $record = eval { MARC::Record->new_from_xml( $xml, 'MARC-8' ) };
    ok( !$record, 'strict: a field with an unmappable character is not kept intact' );
    ok( scalar( grep { /no mapping found/ } @warnings ), 'strict: MARC::Charset warns' );
}

{
    local $MARC::File::XML::OUTPUT_LEVEL = 'default';
    @warnings = ();
    my $record = MARC::Record->new_from_xml( $xml, 'MARC-8' );
    is( $record->subfield( '520', 'a' ), 'Before smile after', 'default: only the unmappable character is dropped' );
    like( $record->subfield( '245', 'a' ), qr/^Caf/, 'default: a field with only mappable characters is converted' );
    ok( scalar( grep { /no mapping found/ } @warnings ), 'default: MARC::Charset still warns' );
}

is( MARC::Charset->ignore_errors(), 0, 'default: MARC::Charset->ignore_errors() is left alone' );
