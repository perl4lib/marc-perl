#!perl -Tw

use strict;
use integer;

use Test::More tests => 15;

BEGIN {
    use_ok( 'MARC::Record' );
}

my $r = MARC::Record->new();

$r->insert_fields_ordered( 
    MARC::Field->new( '100', '', '', a => 'foo' )
);

my @fields = $r->fields();
isa_ok( $fields[0], 'MARC::Field' );
is( $fields[0]->tag(), '100', 'insert_fields_ordered works with empty rec' );

$r->insert_fields_ordered(
    MARC::Field->new( '110', '', '', a => 'bar' ),
    MARC::Field->new( '105', '', '', b => 'bez' ),
    MARC::Field->new( '008', '', '', c => 'fez' )
);

@fields = $r->fields();
my @tags = ();
foreach (@fields ) { 
    isa_ok( $_, 'MARC::Field' ); 
    push( @tags, $_->tag() ); 
}

is( scalar(@fields), 4, 'insert_fields_ordered added multiple fields' );
is_deeply( \@tags, [ '008', '100', '105', '110' ], 
    'insert_fields_ordered() added fields in numeric order' );

# Fields with the same tag.
sub same_tag_order {
    my ( $method, @values ) = @_;
    my $rec = MARC::Record->new();
    $rec->insert_fields_ordered( MARC::Field->new( '245', '', '', a => 'title' ) );
    my @new = map { MARC::Field->new( '100', '', '', a => $_ ) } @values;
    $rec->$method( @new );
    return [ map { $_->subfield('a') } $rec->field('100') ];
}

# The long-standing default files a new field before existing fields with the
# same tag, so same-tag fields come out reversed. Other code relies on this.
is_deeply( same_tag_order( 'insert_fields_ordered', qw( first second third ) ), [ qw( third second first ) ],
    'insert_fields_ordered: same-tag fields are in reverse order of insertion' );

is_deeply( same_tag_order( 'insert_fields_ordered_stable', qw( first second third ) ), [ qw( first second third ) ],
    'insert_fields_ordered_stable: same-tag fields keep their insertion order' );

# Stable insertion across separate calls, and among other tags.
{
    my $rec = MARC::Record->new();
    $rec->insert_fields_ordered_stable( MARC::Field->new( '650', '', '0', a => 'one' ) );
    $rec->insert_fields_ordered_stable( MARC::Field->new( '245', '', '', a => 'title' ) );
    $rec->insert_fields_ordered_stable( MARC::Field->new( '650', '', '0', a => 'two' ) );
    $rec->insert_fields_ordered_stable( MARC::Field->new( '700', '', '', a => 'name' ) );
    is_deeply(
        [ map { $_->tag() . ':' . $_->subfield('a') } $rec->fields() ],
        [ '245:title', '650:one', '650:two', '700:name' ],
        'insert_fields_ordered_stable: tag order is kept, and same-tag fields follow existing ones'
    );
}

# The return value is the number of fields.
is( MARC::Record->new->insert_fields_ordered_stable(
        MARC::Field->new( '100', '', '', a => 'x' ), MARC::Field->new( '245', '', '', a => 'y' ) ),
    2, 'insert_fields_ordered_stable returns the number of fields inserted' );

# Arguments are validated.
ok( !eval { MARC::Record->new->insert_fields_ordered_stable( 'not a field' ); 1 },
    'insert_fields_ordered_stable croaks on a non-field argument' );
ok( !eval { MARC::Record->new->insert_fields_ordered( 'not a field' ); 1 },
    'insert_fields_ordered croaks on a non-field argument' );
