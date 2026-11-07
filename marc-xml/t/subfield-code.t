use strict;
use warnings;
use Test::More tests => 13;
use MARC::Record;
use MARC::File::XML;

# The reader applies the parsing level to invalid subfield codes, because
# MARC::Field->new() croaks on them. See MARC::Field->is_valid_subfield_code().

sub record_xml {
    my ($subfields) = @_;
    return qq{<record xmlns="http://www.loc.gov/MARC21/slim">
  <leader>00000nam a2200000 a 4500</leader>
  <datafield tag="245" ind1="0" ind2="0">$subfields</datafield>
  <datafield tag="650" ind1=" " ind2="0"><subfield code="a">Subject</subfield></datafield>
</record>};
}

my %bad_code = (
    'multi-character code' => 'code="ab"',
    'empty code'           => 'code=""',
    'missing code'         => '',
    'newline code'         => "code=\"&#10;\"",
);

{
    local $MARC::File::XML::PARSING_LEVEL = 'lenient';

    for my $name ( sort keys %bad_code ) {
        my $xml = record_xml(
            qq{<subfield code="a">Title</subfield><subfield $bad_code{$name}>bad</subfield><subfield code="c">by</subfield>}
        );
        my $r = eval { MARC::Record->new_from_xml( $xml, 'UTF-8' ) };
        is( $@, '', "lenient: $name does not die" );
        SKIP: {
            skip 'no record', 1 unless $r;
            is_deeply( [ $r->field('245')->subfields ], [ [ a => 'Title' ], [ c => 'by' ] ],
                "lenient: only the subfield with the $name is dropped" );
        }
    }

    my $r = MARC::Record->new_from_xml(
        record_xml(q{<subfield code="a">Title</subfield><subfield code="ab">bad</subfield>}), 'UTF-8' );
    my @w = grep { /subfield code/ } $r->warnings;
    is( scalar @w, 1, 'lenient: one warning for the invalid code' );
    like( $w[0], qr/Invalid subfield code "ab".*tag 245/, 'lenient: the warning names the code and the tag' );

    $r = MARC::Record->new_from_xml(
        record_xml(q{<subfield code="xx">bad</subfield>}), 'UTF-8' );
    ok( !$r->field('245'), 'lenient: a field left with no subfields is dropped' );
    is( $r->subfield( '650', 'a' ), 'Subject', 'lenient: other fields are still read' );
}

{
    local $MARC::File::XML::PARSING_LEVEL = 'strict';

    eval { MARC::Record->new_from_xml(
        record_xml(q{<subfield code="ab">bad</subfield>}), 'UTF-8' ) };
    like( $@, qr/not a valid subfield code/, 'strict: an invalid code still dies' );
}
