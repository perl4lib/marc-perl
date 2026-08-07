#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

use MARC::Record;
use MARC::Record::MiJ;

subtest 'new_from_mij_structure rejects invalid input' => sub {
    plan tests => 5;

    throws_ok { MARC::Record->new_from_mij_structure(undef) }
        qr/input must be a hashref/,
        'croaks on undef';

    throws_ok { MARC::Record->new_from_mij_structure("a string") }
        qr/input must be a hashref/,
        'croaks on string';

    throws_ok { MARC::Record->new_from_mij_structure([]) }
        qr/input must be a hashref/,
        'croaks on arrayref';

    throws_ok { MARC::Record->new_from_mij_structure({ foo => 'bar' }) }
        qr/input must contain a 'fields' arrayref/,
        'croaks on hashref without fields key';

    throws_ok { MARC::Record->new_from_mij_structure({ leader => '00000nam', fields => 'not an array' }) }
        qr/input must contain a 'fields' arrayref/,
        'croaks when fields is not an arrayref';
};

subtest 'new_from_mij_structure accepts valid input' => sub {
    plan tests => 3;

    my $mij = {
        leader => '00000nam a2200000 a 4500',
        fields => [
            { '245' => { ind1 => '1', ind2 => '0', subfields => [ { a => 'Test title' } ] } }
        ]
    };

    my $record;
    lives_ok { $record = MARC::Record->new_from_mij_structure($mij) }
        'accepts valid MiJ structure';

    isa_ok($record, 'MARC::Record');
    is(scalar $record->fields(), 1, 'record has one field');
};

subtest 'new_from_mij_structure accepts empty fields array' => sub {
    plan tests => 2;

    my $mij = { leader => '00000nam a2200000 a 4500', fields => [] };

    my $record;
    lives_ok { $record = MARC::Record->new_from_mij_structure($mij) }
        'accepts structure with empty fields array';
    is(scalar $record->fields(), 0, 'record has no fields');
};

done_testing();
