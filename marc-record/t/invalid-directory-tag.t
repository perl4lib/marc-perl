#!perl -Tw

use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::Field' );
    use_ok( 'MARC::File::USMARC' );
}

# Build a record, then corrupt the tag of its 245 directory entry so that it
# is a single character ("0") padded with spaces, as in rt.cpan.org #27581.

my $record = MARC::Record->new();
$record->append_fields(
    MARC::Field->new( '100', '1', ' ', a => 'Author' ),
    MARC::Field->new( '245', '0', '0', a => 'Title' ),
    MARC::Field->new( '650', ' ', '0', a => 'Subject' ),
);
my $good = $record->as_usmarc();

my $bad = $good;
$bad =~ s/245/0  /
    or die 'could not find the 245 directory entry';
is( length $bad, length $good, 'corrupted record keeps its length' );

{
    local $MARC::File::USMARC::PARSING_LEVEL = 'lenient';

    my $decoded = eval { MARC::File::USMARC->decode( $bad ) };
    is( $@, '', 'lenient: decode() does not die on an invalid directory tag' );
    isa_ok( $decoded, 'MARC::Record' );

    SKIP: {
        skip 'no record decoded', 4 unless $decoded;

        is( join( ',', map { $_->tag } $decoded->fields ), '100,650',
            'lenient: the field with the invalid tag is skipped, the rest are kept' );
        my @warnings = $decoded->warnings;
        is( scalar @warnings, 1, 'lenient: one warning recorded' );
        like( $warnings[0], qr/Invalid tag in directory.*"0"/,
            'lenient: the warning names the invalid tag' );
        is( $decoded->subfield( '650', 'a' ), 'Subject',
            'lenient: fields after the bad one are readable' );
    }
}

{
    local $MARC::File::USMARC::PARSING_LEVEL = 'strict';

    eval { MARC::File::USMARC->decode( $bad ) };
    like( $@, qr/Invalid tag in directory/, 'strict: decode() still dies' );
}
