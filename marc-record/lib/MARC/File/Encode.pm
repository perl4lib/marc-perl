package MARC::File::Encode;

=head1 NAME 

MARC::File::Encode - (DEPRECATED) Encode wrapper for MARC::Record

=head1 DEPRECATED

This module, which only existed to support an implementation detail
of L<MARC::File::USMARC>, is deprecated and should not be used.

If you were using its marc_to_utf() function, which despite the
name has nothing to do with converting from a MARC character
encoding to UTF-8, it can be replaced with utf8::decode()
or Encode::decode('UTF-8', ...).

=head1 DESCRIPTION

Encode.pm exports encode() by default, and MARC::File::USMARC
already has a function encode() so we need this wrapper to 
keep things the way they are. I was half tempted to change
MARC::File::USMARC::encode() to something else but there could
very well be code in the wild that uses it directly and I don't 
want to break backwards compat. This probably comes with a performance
hit of some kind.

=cut

use strict;
use warnings;
use base qw( Exporter );
use Encode;

our @EXPORT_OK = qw( marc_to_utf8 );

=head2 marc_to_utf8()

Simple wrapper around Encode::decode().

=cut

sub marc_to_utf8 {
    # if there is invalid utf8 date then this will through an exception
    # let's just hope it's valid :-)
    return decode( 'UTF-8', $_[0], 1 );
}

1;
