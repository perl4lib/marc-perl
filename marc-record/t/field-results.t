#!perl -Tw

use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Field' );
}

# The contract of field() when given several field specifiers:
#
# * results are returned in the order of the specifiers (so they can be
#   used as a priority list), and in record order within each specifier;
# * a field matched by more than one specifier is returned only once, at
#   the position of the first specifier that matches it;
# * in scalar context the result is the first field of the first specifier
#   that matches anything.

my $f020 = MARC::Field->new( '020', ' ', ' ', a => '0123456789' );
my $f245 = MARC::Field->new( '245', '0', '0', a => 'Title' );
my $f345 = MARC::Field->new( '345', ' ', ' ', a => 'Aspect' );
my $f650a = MARC::Field->new( '650', ' ', '0', a => 'Subject A' );
my $f650b = MARC::Field->new( '650', ' ', '0', a => 'Subject B' );

# Fields are in tag order, as they usually are in a record.
my $record = MARC::Record->new();
$record->append_fields( $f020, $f245, $f345, $f650a, $f650b );

sub is_fields {
    my ( $got, $expected, $name ) = @_;
    my $ok = @$got == @$expected;
    $ok &&= $got->[$_] == $expected->[$_] for 0 .. $#$expected;
    return ok( $ok, $name )
        || diag( 'got: ' . join( ',', map { $_->tag } @$got ) );
}

# Deduplication
is_fields( [ $record->field( '245', '24.' ) ], [ $f245 ],
    'a field matched by two specifiers is returned once' );
is_fields( [ $record->field( '24.', '245', '0..', '2..' ) ], [ $f245, $f020 ],
    'dedup keeps each field at the position of the first specifier matching it' );
is_fields( [ $record->field( '650', '650' ) ], [ $f650a, $f650b ],
    'the same specifier twice returns the fields once each' );

# Priority order
is_fields( [ $record->field( '345', '020' ) ], [ $f345, $f020 ],
    'results follow the order of the specifiers, not the record' );
is_fields( [ $record->field( '650', '245', '020' ) ], [ $f650a, $f650b, $f245, $f020 ],
    'record order is kept within a specifier' );
is( scalar( $record->field( '345', '020' ) ), $f345,
    'scalar context returns the first field of the first specifier that matches' );
is( scalar( $record->field( '999', '020' ) ), $f020,
    'scalar context skips specifiers that match nothing' );
is( scalar( $record->field( '999' ) ), undef,
    'scalar context returns undef when nothing matches' );

# Unchanged behaviour
is_fields( [ $record->field( '6..' ) ], [ $f650a, $f650b ],
    'a single wildcard specifier returns its fields in record order' );

# Dedup is by object identity, not by content.
my $twin = MARC::Field->new( '245', '0', '0', a => 'Title' );
$record->append_fields( $twin );
is_fields( [ $record->field( '245', '24.' ) ], [ $f245, $twin ],
    'distinct fields with identical content are not collapsed' );

# A field object appended to the record twice is still returned as many
# times as it appears for a single specifier, as it always has been.
my $record2 = MARC::Record->new();
$record2->append_fields( $f245, $f245 );
is( scalar( () = $record2->field( '245' ) ), 2,
    'a single specifier is unaffected by deduplication' );
is( scalar( () = $record2->field( '245', '24.' ) ), 2,
    'only matches already returned for an earlier specifier are dropped' );
