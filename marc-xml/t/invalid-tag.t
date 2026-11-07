use strict;
use warnings;
use Test::More tests => 10;
use MARC::Record;
use MARC::File::XML;

# A <datafield> or <controlfield> whose tag is not three alphanumeric
# characters can't be turned into a MARC::Field. See also
# marc-record/t/invalid-directory-tag.t for the USMARC reader.

sub xml_with {
    my ($bad) = @_;
    return qq{<record xmlns="http://www.loc.gov/MARC21/slim">
  <leader>00000nam a2200000 a 4500</leader>
  <controlfield tag="001">id1</controlfield>
  $bad
  <datafield tag="245" ind1="0" ind2="0"><subfield code="a">Title</subfield></datafield>
</record>};
}

my %cases = (
    'one-character datafield tag' =>
        '<datafield tag="0" ind1=" " ind2=" "><subfield code="a">bad</subfield></datafield>',
    'one-character controlfield tag' =>
        '<controlfield tag="0">bad</controlfield>',
    'missing tag attribute' =>
        '<datafield ind1=" " ind2=" "><subfield code="a">bad</subfield></datafield>',
);

{
    local $MARC::File::XML::PARSING_LEVEL = 'lenient';

    for my $name ( sort keys %cases ) {
        my $r = eval { MARC::Record->new_from_xml( xml_with( $cases{$name} ), 'UTF-8' ) };
        is( $@, '', "lenient: $name does not die" );
        SKIP: {
            skip 'no record', 2 unless $r;
            is( join( ',', map { $_->tag } $r->fields ), '001,245',
                "lenient: $name is skipped, the other fields are kept" );
            is( scalar( () = $r->warnings ), 1, "lenient: $name records one warning" );
        }
    }
}

{
    local $MARC::File::XML::PARSING_LEVEL = 'strict';

    eval { MARC::Record->new_from_xml( xml_with( $cases{'one-character datafield tag'} ), 'UTF-8' ) };
    like( $@, qr/not a valid tag/, 'strict: an invalid tag still dies' );
}
