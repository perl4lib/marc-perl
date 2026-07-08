use strict;
use warnings;
use Test::More tests => 5;
use MARC::Record;
use MARC::File::XML;

open my $IN, '<', 't/missing-indicators.xml';
my $xml = join('', <$IN>);
close $IN;

my $r;
eval { $r = MARC::Record->new_from_xml($xml, 'UTF-8'); };
ok(!$@, 'new_from_xml() does not die on a <datafield> missing ind1/ind2 entirely');

my $field = $r->field('500');
ok($field, 'the field with missing indicators is still present');
is($field->indicator(1), ' ', 'ind1 defaults to a blank');
is($field->indicator(2), ' ', 'ind2 defaults to a blank');

my @warnings = $r->warnings();
ok(
    (grep { /500/ } @warnings),
    'a warning identifying tag 500 is recorded'
) or diag(join("\n", @warnings));
