use strict;
use warnings;
use Test::More tests => 8;
use MARC::Record;
use MARC::File::XML;

my $header = '<record xmlns="http://www.loc.gov/MARC21/slim">'
    . '<leader>00755cam a22002414a 4500</leader>'
    . '<datafield tag="245" ind1="1" ind2="0"><subfield code="a">A title /</subfield></datafield>';
my %bad = (
    'empty datafield'    => '<datafield tag="500" ind1=" " ind2=" "></datafield>',
    'missing indicators' => '<datafield tag="500"><subfield code="a">A note</subfield></datafield>',
);

is($MARC::File::XML::PARSING_LEVEL, 'strict', "the parsing level is 'strict' unless asked otherwise");

for my $name (sort keys %bad) {
    my $xml = "$header$bad{$name}</record>";

    {
        local $MARC::File::XML::PARSING_LEVEL = 'strict';
        eval { MARC::Record->new_from_xml($xml, 'UTF-8') };
        like($@, qr/Field 500 must have/, "strict: $name dies");
    }
    {
        local $MARC::File::XML::PARSING_LEVEL = 'lenient';
        my $r = eval { MARC::Record->new_from_xml($xml, 'UTF-8') };
        ok($r && !$@, "lenient: $name does not die") or diag($@);
        ok($r && scalar(grep { /500/ } $r->warnings), "lenient: $name records a warning for tag 500");
    }
}

{
    local $MARC::File::XML::PARSING_LEVEL = 'bogus';
    eval { MARC::Record->new_from_xml("$header</record>", 'UTF-8') };
    like($@, qr/Unknown parsing level 'bogus' \(expected one of: lenient, strict\)/, 'an unknown parsing level dies');
}
