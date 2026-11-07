#!perl -Tw

use strict;
use warnings;

use Test::More;
use MARC::Field;

# The characters MARC21slim.xsd allows for a subfield code.
my @valid = ( 0 .. 9, 'a' .. 'z', 'A' .. 'Z',
    split //, q{!"#$%&'()*+,-./:;<=>?{}_^`~[]\\} );

my @invalid = (
    [ "multi-character CJK code" => "\x{4eba}\x{985e}" ],
    [ "two ASCII characters"     => 'ab' ],
    [ "empty code"               => '' ],
    [ "subfield delimiter"       => "\x1f" ],
    [ "newline"                  => "\n" ],
    [ "code with trailing newline" => "a\n" ],
    [ "space"                    => ' ' ],
    [ "a non-ASCII letter"       => "\x{e9}" ],
    [ "end of field"             => "\x1e" ],
    [ "undef"                    => undef ],
);

plan tests => 2 + @valid + 3 * @invalid + 7;

# is_valid_subfield_code()
ok( MARC::Field->is_valid_subfield_code($_), "'$_' is a valid subfield code" ) for @valid;
is( scalar( grep { MARC::Field->is_valid_subfield_code( $_->[1] ) } @invalid ), 0,
    'none of the invalid codes is accepted' );
ok( MARC::Field->is_valid_subfield_code('a'), 'works as a class method' );

for my $case (@invalid) {
    my ( $name, $code ) = @$case;

    eval { MARC::Field->new( '245', '0', '0', $code => 'stuff' ) };
    like( $@, qr/not a valid subfield code/, "new() croaks: $name" );

    my $field = MARC::Field->new( '245', '0', '0', a => 'Title' );
    eval { $field->add_subfields( $code => 'stuff' ) };
    like( $@, qr/not a valid subfield code/, "add_subfields() croaks: $name" );

    eval { $field->update( $code => 'stuff' ) };
    like( $@, qr/not a valid subfield code/, "update() croaks: $name" );
}

# a failed call must not leave the field half-changed
{
    my $field = MARC::Field->new( '245', '0', '0', a => 'Title' );
    eval { $field->add_subfields( b => 'ok', 'xx' => 'bad' ) };
    is_deeply( [ $field->subfields ], [ [ a => 'Title' ] ],
        'add_subfields() adds nothing when one code is invalid' );

    eval { $field->update( ind1 => '1', 'xx' => 'bad' ) };
    is( $field->indicator(1), '0', 'update() changes nothing when one code is invalid' );
}

# valid input is untouched
{
    my $field = MARC::Field->new( '245', '0', '0', a => 'Title', 9 => 'local', '$' => 'sym' );
    is_deeply( [ $field->subfields ], [ [ a => 'Title' ], [ 9 => 'local' ], [ '$' => 'sym' ] ],
        'new() keeps valid codes, including digits and symbols' );

    $field->add_subfields( c => 'Author', '~' => 'tilde' );
    is( scalar( () = $field->subfields ), 5, 'add_subfields() accepts valid codes' );

    $field->update( ind2 => '4', a => 'New title', z => 'appended' );
    is( $field->subfield('a'), 'New title', 'update() still updates an existing subfield' );
    is( $field->subfield('z'), 'appended', 'update() still appends a new subfield' );
    is( $field->indicator(2), '4', 'update() still sets indicators' );
}
