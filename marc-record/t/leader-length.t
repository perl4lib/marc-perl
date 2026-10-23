#!perl -Tw

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Field' );
    use_ok( 'MARC::File::USMARC' );
}

# The record length and base address in the leader are only recalculated
# when the record is serialised; see the POD for leader() and as_usmarc().

my $record = MARC::Record->new();
$record->append_fields( MARC::Field->new( '245', '0', '0', a => 'Title' ) );

is( substr( $record->leader, 0, 5 ), '     ',
    'no record length before serialising' );

my $usmarc = $record->as_usmarc();
is( substr( $record->leader, 0, 5 ), sprintf( '%05d', length $usmarc ),
    'as_usmarc() stores the record length in the leader' );
is( substr( $record->leader, 12, 5 ), '00037',
    'as_usmarc() stores the base address in the leader' );

my $length = substr( $record->leader, 0, 5 );
$record->append_fields( MARC::Field->new( '650', ' ', '0', a => 'Subject' ) );
is( substr( $record->leader, 0, 5 ), $length,
    'changing the record leaves the stored length as it was' );

my $reserialised = $record->as_usmarc();
is( substr( $record->leader, 0, 5 ), sprintf( '%05d', length $reserialised ),
    'serialising again brings the length up to date' );

# update_leader() never worked and has been removed.
ok( !MARC::File::USMARC->can( 'update_leader' ), 'no update_leader() function' );
