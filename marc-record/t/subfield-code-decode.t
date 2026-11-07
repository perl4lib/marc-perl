#!perl -Tw

use strict;
use warnings;

use Test::More tests => 13;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Field' );
    use_ok( 'MARC::File::USMARC' );
}

# Build a record, then corrupt subfield codes in the binary form. The
# replacement is the same length, so the directory stays correct.

sub usmarc_with {
    my ( $from, $to ) = @_;
    my $record = MARC::Record->new();
    $record->append_fields(
        MARC::Field->new( '245', '0', '0', a => 'Title', b => 'sub', c => 'by' ),
        MARC::Field->new( '650', ' ', '0', x => 'only' ),
        MARC::Field->new( '700', '1', ' ', a => 'Last' ),
    );
    my $usmarc = $record->as_usmarc();
    $usmarc =~ s/\Q$from\E/$to/
        or die "could not find $from";
    return $usmarc;
}

{
    local $MARC::File::USMARC::PARSING_LEVEL = 'lenient';

    # one bad code among good ones
    my $bad = usmarc_with( "\x1fbsub", "\x1f\nsub" );
    my $r = eval { MARC::File::USMARC->decode($bad) };
    is( $@, '', 'lenient: decode() does not die on an invalid subfield code' );

    SKIP: {
        skip 'no record decoded', 5 unless $r;
        is_deeply( [ $r->field('245')->subfields ], [ [ a => 'Title' ], [ c => 'by' ] ],
            'lenient: only the subfield with the invalid code is dropped' );
        my @w = $r->warnings;
        is( scalar @w, 1, 'lenient: one warning recorded' );
        like( $w[0], qr/Invalid subfield code "\\x\{A\}".*tag 245/,
            'lenient: the warning names the code and the tag' );
        is( $r->subfield( '700', 'a' ), 'Last', 'lenient: later fields are still read' );
        ok( $r->field('650'), 'lenient: the field before is still there' );
    }

    # a printable but invalid code is shown as it is
    my $space = usmarc_with( "\x1fcby", "\x1f by" );
    $r = MARC::File::USMARC->decode($space);
    like( ( $r->warnings )[0], qr/Invalid subfield code " "/,
        'lenient: a space code is shown as a space' );

    # every subfield of a field invalid: the field itself goes
    my $all = usmarc_with( "\x1fxonly", "\x1f\nonly" );
    $r = eval { MARC::File::USMARC->decode($all) };
    is( $@, '', 'lenient: a field with only invalid codes does not die' );
    ok( !$r->field('650'), 'lenient: a field left with no subfields is dropped' );
}

{
    local $MARC::File::USMARC::PARSING_LEVEL = 'strict';

    eval { MARC::File::USMARC->decode( usmarc_with( "\x1fbsub", "\x1f\nsub" ) ) };
    like( $@, qr/Invalid subfield code/, 'strict: decode() dies on an invalid subfield code' );
}
