use strict;
use warnings;
use Test::More tests => 5;
use MARC::Record;
use MARC::File::XML;

open my $IN, '<', 't/empty-datafield.xml';
my $xml = join('', <$IN>);
close $IN;

my $r;
eval { $r = MARC::Record->new_from_xml($xml, 'UTF-8'); };
ok(!$@, 'new_from_xml() does not die on a <datafield> with no <subfield> children');

ok($r->field('245'), 'the well-formed 245 field survives');
ok(!$r->field('500'), 'the empty 500 datafield is dropped, not just left blank');

my @warnings = $r->warnings();
ok(
    (grep { /500/ } @warnings),
    'a warning identifying tag 500 is recorded'
) or diag(join("\n", @warnings));

my $xml_out = $r->as_xml_record();
unlike($xml_out, qr/tag="500"/, 're-serializing does not resurrect the dropped field');
