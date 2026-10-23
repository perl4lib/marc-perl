#!perl -Tw

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Field' );
}

my $record = MARC::Record->new();
$record->append_fields(
    MARC::Field->new( '245', '0', '0', a => 'Title' ),
    MARC::Field->new( '650', ' ', '0', a => 'Subject' ),
    MARC::Field->new( '651', ' ', '0', a => 'Place' ),
);

sub tags { join( ',', map { $_->tag } @_ ) }

# A field specifier is anchored to the whole tag, even when it contains an
# alternation: the alternatives must not be anchored separately.
is( tags( $record->field( '24|65' ) ), '',
    'alternation does not match on a prefix or a suffix' );
is( tags( $record->field( '245|650' ) ), '245,650',
    'alternation of whole tags matches each of them' );
is( tags( $record->field( '24.|65.' ) ), '245,650,651',
    'alternation of wildcarded tags' );
is( tags( $record->field( '(?:245|650)' ) ), '245,650',
    'an explicitly grouped alternation still works' );

# The ordinary forms keep working.
is( tags( $record->field( '245' ) ), '245', 'simple tag' );
is( tags( $record->field( '6..' ) ), '650,651', 'wildcard' );
is( tags( $record->field( '24' ) ), '', 'partial tag does not match' );
