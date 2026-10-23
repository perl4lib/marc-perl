use strict;
use warnings;
use Test::More tests => 12;
use MARC::Record;
use MARC::Charset;
use MARC::File::XML;

# A MARC-8 record (Leader/09 is blank) whose 520 holds 0xBF, which is not
# a valid MARC-8 character, among text that can be mapped (0xE2 is an acute
# accent combining with the 'e').
my $marc8_title = "Caf\x{e2}e";
my $marc8_note  = "Before \x{bf}quoted\x{bf} after";

my $record = MARC::Record->new();
$record->leader('00000nam  2200000 a 4500');
$record->append_fields(
    MARC::Field->new( '245', '1', '0', a => $marc8_title ),
    MARC::Field->new( '520', ' ', ' ', a => $marc8_note ),
);

# MARC::Charset warns about each character it can't map.
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

sub subfields_in {
    my ( $xml, $tag ) = @_;
    my ($datafield) = $xml =~ m{(<datafield tag="$tag".*?</datafield>)}s;
    return [ $datafield =~ m{<subfield code="."[^>]*>(.*?)</subfield>}gs ];
}

is( $MARC::File::XML::OUTPUT_LEVEL, 'strict', "the output level is 'strict' unless asked otherwise" );

{
    local $MARC::File::XML::OUTPUT_LEVEL = 'strict';
    @warnings = ();
    my $xml = $record->as_xml_record();
    is_deeply( subfields_in( $xml, '520' ), [''], 'strict: a field with an unmappable character comes out empty' );
    like( subfields_in( $xml, '245' )->[0], qr/^Caf/, 'strict: a field with only mappable characters is converted' );
    ok( scalar( grep { /no mapping found/ } @warnings ), 'strict: MARC::Charset warns' );
}

{
    local $MARC::File::XML::OUTPUT_LEVEL = 'lenient';
    @warnings = ();
    my $xml = $record->as_xml_record();
    my $note = subfields_in( $xml, '520' )->[0];
    utf8::decode($note);
    is( $note, 'Before quoted after', 'lenient: only the unmappable characters are dropped' );
    ok( scalar( grep { /no mapping found/ } @warnings ), 'lenient: MARC::Charset still warns' );
}

# The lenient level applies to this call only and does not touch the
# process-wide setting.
is( MARC::Charset->ignore_errors(), 0, 'lenient: MARC::Charset->ignore_errors() is left alone' );

{
    local $MARC::File::XML::OUTPUT_LEVEL = 'strict';
    MARC::Charset->ignore_errors(1);
    my $xml = $record->as_xml_record();
    my $note = subfields_in( $xml, '520' )->[0];
    utf8::decode($note);
    is( $note, 'Before quoted after', 'strict: a global MARC::Charset->ignore_errors(1) is still honoured' );
    MARC::Charset->ignore_errors(0);
}

# The parsing level only concerns input and does not affect record().
{
    local $MARC::File::XML::PARSING_LEVEL = 'lenient';
    @warnings = ();
    my $xml = $record->as_xml_record();
    is_deeply( subfields_in( $xml, '520' ), [''], 'the parsing level does not affect record()' );
}

is( $record->leader, '00000nam  2200000 a 4500', 'the record is left as it was' );

{
    local $MARC::File::XML::OUTPUT_LEVEL = 'bogus';
    eval { $record->as_xml_record() };
    like( $@, qr/Unknown output level 'bogus' \(expected one of: lenient, strict\)/, 'an unknown output level dies' );
}

{
    local $MARC::File::XML::PARSING_LEVEL = 'bogus';
    eval { $record->as_xml_record() };
    is( $@, '', 'an unknown parsing level does not affect record()' );
}
