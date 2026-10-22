package MARC::File::XML;

use v5.8.8;

use warnings;
use strict;

use vars qw( $VERSION %_load_args );
use base qw( MARC::File );
use MARC::Record;
use MARC::Field;
use XML::LibXML;

use MARC::Charset qw( marc8_to_utf8 utf8_to_marc8 );
use IO::File;
use Carp qw( croak );
use Encode ();

$VERSION = '1.0.6';

our $parser;

# How tolerant decode() is of malformed data; see "PARSING LEVELS".
our $PARSING_LEVEL = 'strict';
# How tolerant record() is of data it cannot serialize cleanly; see
# "OUTPUT LEVELS".
our $OUTPUT_LEVEL = 'strict';
my %_levels = map { $_ => 1 } qw( strict default );

sub _level {
    my ( $what, $level ) = @_;
    croak( "Unknown $what level '" . ( defined $level ? $level : 'undef' ) . "' (expected one of: " . join( ', ', sort keys %_levels ) . ')' )
        unless defined $level && $_levels{$level};
    return $level;
}

sub _parsing_level { return _level( 'parsing', $PARSING_LEVEL ) }
sub _output_level  { return _level( 'output',  $OUTPUT_LEVEL ) }

sub import {
    my $class = shift;
    %_load_args = @_;
    $_load_args{ DefaultEncoding } ||= 'UTF-8';
    $_load_args{ RecordFormat } ||= 'USMARC';
}

=head1 NAME

MARC::File::XML - Work with MARC data encoded as XML 

=head1 SYNOPSIS

    ## Loading with USE options
    use MARC::File::XML ( BinaryEncoding => 'utf8', RecordFormat => 'UNIMARC' );

    ## Setting the record format without USE options
    MARC::File::XML->default_record_format('USMARC');
    
    ## reading with MARC::Batch
    my $batch = MARC::Batch->new( 'XML', $filename );
    my $record = $batch->next();

    ## or reading with MARC::File::XML explicitly
    my $file = MARC::File::XML->in( $filename );
    my $record = $file->next();

    ## serialize a single MARC::Record object as XML
    print $record->as_xml();

    ## write a bunch of records to a file
    my $file = MARC::File::XML->out( 'myfile.xml' );
    $file->write( $record1 );
    $file->write( $record2 );
    $file->write( $record3 );
    $file->close();

    ## instead of writing to disk, get the xml directly 
    my $xml = join( "\n", 
        MARC::File::XML::header(),
        MARC::File::XML::record( $record1 ),
        MARC::File::XML::record( $record2 ),
        MARC::File::XML::footer()
    );

=head1 DESCRIPTION

The MARC-XML distribution is an extension to the MARC-Record distribution for 
working with MARC21 data that is encoded as XML. The XML encoding used is the
MARC21slim schema supplied by the Library of Congress. More information may 
be obtained here: http://www.loc.gov/standards/marcxml/

You must have MARC::Record installed to use MARC::File::XML. In fact 
once you install the MARC-XML distribution you will most likely not use it 
directly, but will have an additional file format available to you when you
use MARC::Batch.

This version of MARC-XML supersedes an the versions ending with 0.25 which 
were used with the MARC.pm framework. MARC-XML now uses MARC::Record 
exclusively.

If you have any questions or would like to contribute to this module please
visit the project's GitHub repository at L<https://github.com/perl4lib/marc-perl>.

=head1 METHODS

When you use MARC::File::XML your MARC::Record objects will have two new
additional methods available to them: 

=head2 MARC::File::XML->default_record_format([$format])

Sets or returns the default record format used by MARC::File::XML.  Valid
formats are B<MARC21>, B<USMARC>, B<UNIMARC> and B<UNIMARCAUTH>.

    MARC::File::XML->default_record_format('UNIMARC');

=cut

sub default_record_format {
    my $self = shift;
    my $format = shift;

    $_load_args{RecordFormat} = $format if ($format);

    return $_load_args{RecordFormat};
}


=head2 as_xml()

Returns a MARC::Record object serialized in XML. You can pass an optional format
parameter to tell MARC::File::XML what type of record (USMARC, UNIMARC, UNIMARCAUTH) you are
serializing.

    print $record->as_xml([$format]);

=cut 

sub MARC::Record::as_xml {
    my $record = shift;
    my $format = shift || $_load_args{RecordFormat};
    return(  MARC::File::XML::encode( $record, $format ) );
}

=head2 as_xml_record([$format])

Returns a MARC::Record object serialized in XML without a collection wrapper.
You can pass an optional format parameter to tell MARC::File::XML what type of
record (USMARC, UNIMARC, UNIMARCAUTH) you are serializing.

    print $record->as_xml_record('UNIMARC');

=cut 

sub MARC::Record::as_xml_record {
    my $record = shift;
    my $format = shift || $_load_args{RecordFormat};
    return(  MARC::File::XML::encode( $record, $format, 1 ) );
}

=head2 new_from_xml([$encoding, $format])

If you have a chunk of XML and you want a record object for it you can use 
this method to generate a MARC::Record object.  You can pass an optional
encoding parameter to specify which encoding (UTF-8 or MARC-8) you would like
the resulting record to be in.  You can also pass a format parameter to specify
the source record type, such as UNIMARC, UNIMARCAUTH, USMARC or MARC21.

    my $record = MARC::Record->new_from_xml( $xml, $encoding, $format );

Note: only works for single record XML chunks.

=cut 

sub MARC::Record::new_from_xml {
    my $xml = shift;
    ## to allow calling as MARC::Record::new_from_xml()
    ## or MARC::Record->new_from_xml()
    $xml = shift if ( ref($xml) || ($xml eq "MARC::Record") );

    my $enc = shift || $_load_args{BinaryEncoding};
    my $format = shift || $_load_args{RecordFormat};
    return( MARC::File::XML::decode( $xml, $enc, $format ) );
}

=pod 

If you want to write records as XML to a file you can use out() with write()
to serialize more than one record as XML.

=head2 out()

A constructor for creating a MARC::File::XML object that can write XML to a
file. You must pass in the name of a file to write XML to.  If the $encoding
parameter or the DefaultEncoding (see above) is set to UTF-8 then the binmode
of the output file will be set appropriately.

    my $file = MARC::File::XML->out( $filename [, $encoding] );

=cut

sub out {
    my ( $class, $filename, $enc ) = @_;
    my $fh = IO::File->new( ">$filename" ) or croak( $! );
    $enc ||= $_load_args{DefaultEncoding};

    if ($enc =~ /^utf-?8$/oi) {
        $fh->binmode(':utf8');
    } else {
        $fh->binmode(':raw');
    }

    my %self = ( 
        filename    => $filename,
        fh          => $fh, 
        header      => 0,
        encoding    => $enc
    );
    return( bless \%self, ref( $class ) || $class );
}

=head2 write()

Used in tandem with out() to write records to a file. 

    my $file = MARC::File::XML->out( $filename );
    $file->write( $record1 );
    $file->write( $record2 );

=cut

sub write {
    my ( $self, $record, $enc ) = @_;
    if ( ! $self->{ fh } ) { 
        croak( "MARC::File::XML object not open for writing" );
    }
    if ( ! $record ) { 
        croak( "must pass write() a MARC::Record object" );
    }
    ## print the XML header if we haven't already
    if ( ! $self->{ header } ) { 
        $enc ||= $self->{ encoding } || $_load_args{DefaultEncoding};
        $self->{ fh }->print( header( $enc ) );
        $self->{ header } = 1;
    } 
    ## print out the record
    $self->{ fh }->print( record( $record ) ) || croak( $! );
    return( 1 );
}

=head2 close()

When writing records to disk the filehandle is automatically closed when you
the MARC::File::XML object goes out of scope. If you want to close it explicitly
use the close() method.

=cut

sub close {
    my $self = shift;
    if ( $self->{ fh } ) {
        $self->{ fh }->print( footer() ) if $self->{ header };
        $self->{ fh } = undef;
        $self->{ filename } = undef;
        $self->{ header } = undef;
    }
    return( 1 );
}

## makes sure that the XML file is closed off

sub DESTROY {
    shift->close();
}

=pod

If you want to generate batches of records as XML, but don't want to write to
disk you'll have to use header(), record() and footer() to generate the
different portions.  

    $xml = join( "\n",
        MARC::File::XML::header(),
        MARC::File::XML::record( $record1 ),
        MARC::File::XML::record( $record2 ),
        MARC::File::XML::record( $record3 ),
        MARC::File::XML::footer()
    );

=head2 header() 

Returns a string of XML to use as the header to your XML file.

=cut 

sub header {
    my $enc = shift; 
    $enc = shift if ( $enc && (ref($enc) || ($enc eq "MARC::File::XML")) );
    $enc ||= 'UTF-8';
    return( <<MARC_XML_HEADER );
<?xml version="1.0" encoding="$enc"?>
<collection
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
  xmlns="http://www.loc.gov/MARC21/slim">
MARC_XML_HEADER
}

=head2 footer()

Returns a string of XML to use at the end of your XML file.

=cut

sub footer {
    return( "</collection>" );
}

=head2 record()

Returns a chunk of XML suitable for placement between the header and the footer.

=cut

sub record {
    my $record = shift;
    my $format = shift;
    my $include_full_record_header = shift;
    my $enc = shift;

    $format ||= $_load_args{RecordFormat};

    # At the 'default' level characters with no UTF-8 mapping are dropped
    # one by one; otherwise leave MARC::Charset to apply its own setting.
    my $ignore_errors = _output_level() eq 'default' ? 1 : undef;

    my $_transcode = 0;
    my $ldr = $record->leader;
    my $original_encoding = substr($ldr,9,1);

    # Does the record think it is already Unicode?
    if ($original_encoding ne 'a' && lc($format) !~ /^unimarc/o) {
        # If not, we'll make it so
        $_transcode++;
        substr($ldr,9,1,'a');
        $record->leader( $ldr );
    }

    my @xml = ();

    if ($include_full_record_header) {
        push @xml, <<HEADER
<?xml version="1.0" encoding="$enc"?>
<record
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    xmlns="http://www.loc.gov/MARC21/slim">
HEADER

    } else {
        push( @xml, "<record>" );
    }

    push( @xml, "  <leader>" . escape( $record->leader ) . "</leader>" );

    foreach my $field ( $record->fields() ) {
        my ($tag) = escape( $field->tag() );
        if ( $field->is_control_field() ) { 
            my $data = $field->data;
            push( @xml, qq(  <controlfield tag="$tag">) .
                    escape( ($_transcode ? marc8_to_utf8($data, $ignore_errors) : $data) ). qq(</controlfield>) );
        } else {
            my ($i1) = escape( $field->indicator( 1 ) );
            my ($i2) = escape( $field->indicator( 2 ) );
            push( @xml, qq(  <datafield tag="$tag" ind1="$i1" ind2="$i2">) );
            foreach my $subfield ( $field->subfields() ) { 
                my ( $code, $data ) = ( escape( $$subfield[0] ), $$subfield[1] );
                push( @xml, qq(    <subfield code="$code">).
                        escape( ($_transcode ? marc8_to_utf8($data, $ignore_errors) : $data) ).qq(</subfield>) );
            }
            push( @xml, "  </datafield>" );
        }
    }
    push( @xml, "</record>\n" );

    if ($_transcode) {
        substr($ldr,9,1,$original_encoding);
        $record->leader( $ldr );
    }

    return( join( "\n", @xml ) );
}

my %ESCAPES = (
    '&'     => '&amp;',
    '<'     => '&lt;',
    '>'     => '&gt;',
    q(')    => '&apos;',
    q(")    => '&quot;',
);
my $_base_escape_regex = join( '|', map { "\Q$_\E" } keys %ESCAPES );
my $ESCAPE_REGEX = qr/$_base_escape_regex/;

sub escape {
    my $string = shift;
    return '' if ! defined $string or $string eq '';
    $string =~ s/($ESCAPE_REGEX)/$ESCAPES{$1}/oge;
    return( $string );
}

sub _next {
    my $self = shift;
    my $fh = $self->{ fh };

    ## return undef at the end of the file
    return if eof($fh);

    ## get a chunk of xml for a record
    local $/ = 'record>';
    my $xml = <$fh>;

    return if $xml =~ m!</([^:]+:){0,1}collection>$!;

    ## do we have enough?
    $xml .= <$fh> if $xml !~ m!</([^:]+:){0,1}record>$! && !eof($fh);
    ## trim stuff before the start record element 
    $xml =~ s/.*?<(([^:]+:){0,1})record.*?>/<$1record>/s;

    ## return undef if there isn't a good chunk of xml
    return if ( $xml !~ m|<(([^:]+:){0,1})record>.*</\1record>|s );

    ## if we have a namespace prefix, restore the declaration
    if ($xml =~ /<([^:]+:)record>/) {
        $xml =~ s!<([^:]+):record>!<$1:record xmlns:$1="http://www.loc.gov/MARC21/slim">!;
    }

    ## return the chunk of xml
    return( $xml );
}

sub _parser {
    $parser ||= XML::LibXML->new(
        expand_entities => 1,
        ext_ent_handler => sub {
            die "External entities are not supported\n";
        }
    );
    return $parser;
}

=head2 decode()

You probably don't ever want to call this method directly. If you do 
you should pass in a chunk of XML as the argument. 

It is normally invoked by a call to next(), see L<MARC::Batch> or L<MARC::File>.

=cut

sub decode {
    my $self = shift;
    my $text;
    my $location = '';

    my $level = _parsing_level();

    # At the 'default' output level characters with no MARC-8 mapping are
    # dropped one by one; otherwise leave MARC::Charset to apply its own
    # setting.
    my $ignore_errors = _output_level() eq 'default' ? 1 : undef;

    if ( ref($self) =~ /^MARC::File/ ) {
        $location = 'in record '.$self->{recnum};
        $text = shift;
    } else {
        $location = 'in record 1';
        $text = $self=~/MARC::File/ ? shift : $self;
    }

    my $enc = shift || $_load_args{BinaryEncoding};
    my $format = shift || $_load_args{RecordFormat};

    my $parser = _parser();
    my $xml = $parser->parse_string($text);

    my $root = $xml->documentElement;
    croak('MARCXML document has no root element') unless defined $root;
    if ($root->localname eq 'collection') {
        my @records = $root->getChildrenByLocalName('record');
        croak('MARCXML document has no record element') unless @records;
        $root = $records[0];
    }

    my $rec = MARC::Record->new();
    my @leaders = $root->getElementsByLocalName('leader');
    my $transcode_to_marc8 = 0;
    if (@leaders) {
        my $leader = $leaders[0]->textContent;

        # this bit is rather questionable
        $transcode_to_marc8 = substr($leader, 9, 1) eq 'a' && decideMARC8Binary($format, $enc) ? 1 : 0;
        substr($leader, 9, 1) = ' ' if $transcode_to_marc8;
    
        $rec->leader($leader);
    }

    my @fields = ();
    foreach my $elt ($root->getChildrenByLocalName('*')) {
        if ($elt->localname eq 'controlfield') {
            push @fields, MARC::Field->new($elt->getAttribute('tag'), $elt->textContent);
        } elsif ($elt->localname eq 'datafield') {
            my @sfs = ();
            foreach my $sfelt ($elt->getChildrenByLocalName('subfield')) {
                push @sfs, $sfelt->getAttribute('code'),
                           $transcode_to_marc8 ? utf8_to_marc8($sfelt->textContent(), $ignore_errors) : $sfelt->textContent();
            }

            my $tag = $elt->getAttribute('tag');

            my $ind1 = $elt->getAttribute('ind1');
            my $ind2 = $elt->getAttribute('ind2');

            # At the 'strict' level these are left for MARC::Field->new()
            # to reject.
            if ($level eq 'default') {
                unless (@sfs) {
                    $rec->_warn("no subfield data found $location for tag $tag");
                    next;
                }

                unless (defined $ind1 && defined $ind2) {
                    $rec->_warn("missing indicator(s) forced to blanks $location for tag $tag");
                    $ind1 = ' ' unless defined $ind1;
                    $ind2 = ' ' unless defined $ind2;
                }
            }

            push @fields, MARC::Field->new($tag, $ind1, $ind2, @sfs);
        }
    }
    $rec->append_fields(@fields);
    return $rec;
   
}

=head2 MARC::File::XML->set_parser($parser)

Pass a XML::LibXML parser to MARC::File::XML
for it to use.  This is optional, meant for
use by applications that maintain a shared
parser object or which require that external
entities be processed.  Note that the latter
is a potential security risk; see
L<https://www.owasp.org/index.php/XML_External_Entity_(XXE)_Processing>.

=cut

sub set_parser {
    my $self = shift;

    $parser = shift;
    undef $parser unless ref($parser) =~ /XML::LibXML/;
}

sub decideMARC8Binary {
    my $format = shift;
    my $enc = shift;

    return 0 if (defined($format) && lc($format) =~ /^unimarc/o);
    return 0 if (defined($enc) && lc($enc) =~ /^utf-?8/o);
    return 1;
}


=head2 encode()

You probably want to use the as_xml() method on your MARC::Record object
instead of calling this directly. But if you want to you just need to 
pass in the MARC::Record object you wish to encode as XML, and you will be
returned the XML as a scalar.

=cut

sub encode {
    my $record = shift;
    my $format = shift || $_load_args{RecordFormat};
    my $without_collection_header = shift;
    my $enc = shift || $_load_args{DefaultEncoding};

    if (lc($format) =~ /^unimarc/o) {
        $enc = _unimarc_encoding( $format => $record );
    }

    my @xml = ();
    push( @xml, header( $enc ) ) unless ($without_collection_header);
    # verbose, but naming the header output flags this way to avoid
    # the potential confusion identified in CPAN bug #34082
    # http://rt.cpan.org/Public/Bug/Display.html?id=34082
    my $include_full_record_header = ($without_collection_header) ? 1 : 0;
    push( @xml, record( $record, $format, $include_full_record_header, $enc ) );
    push( @xml, footer() ) unless ($without_collection_header);

    return( join( "\n", @xml ) );
}

sub _unimarc_encoding {
    my $f = shift;
    my $r = shift;

    my $pos = 26;
    $pos = 13 if (lc($f) eq 'unimarcauth');

    my $enc = substr( $r->subfield(100 => 'a'), $pos, 2 );

    if ($enc eq '01' || $enc eq '03') {
        return 'ISO-8859-1';
    } elsif ($enc eq '50') {
        return 'UTF-8';
    } else {
        die "Unsupported UNIMARC character encoding [$enc] for XML output for $f; 100\$a -> " . $r->subfield(100 => 'a');
    }
}

=head1 PARSING LEVELS

How tolerant C<decode()> is of malformed data is controlled by the package
variable C<$MARC::File::XML::PARSING_LEVEL>:

    local $MARC::File::XML::PARSING_LEVEL = 'default';

=over 4

=item strict

The default. A C<< <datafield> >> with no C<< <subfield> >> children, or with
a missing C<ind1> or C<ind2> attribute, makes C<decode()> die, as it always
has.

=item default

Common errors are fixed or ignored, and a warning is added to the record's
C<warnings()> list. A C<< <datafield> >> with no subfields is dropped, and a
missing indicator is replaced with a blank. This is how
L<MARC::File::USMARC> treats the equivalent problems in binary records.

=back

Any other value makes C<decode()> die.

=head1 OUTPUT LEVELS

How tolerant C<record()> and C<decode()> are of characters that cannot be
converted between UTF-8 and MARC-8 is controlled by the package variable
C<$MARC::File::XML::OUTPUT_LEVEL>. It is separate from C<$PARSING_LEVEL>,
which is about the structure of the XML:

    local $MARC::File::XML::OUTPUT_LEVEL = 'default';

=over 4

=item strict

The default. When C<record()> converts a MARC-8 record to UTF-8, a field
containing a character with no UTF-8 mapping comes out empty, and
L<MARC::Charset> warns about the character. This is the behaviour of
C<< MARC::Charset->ignore_errors(0) >>, unless your code has set that globally.
Likewise, when C<decode()> converts UTF-8 to MARC-8, a subfield containing a
character with no MARC-8 mapping is left without a value.

=item default

When C<record()> converts a MARC-8 record to UTF-8, or C<decode()> converts
UTF-8 to MARC-8, only the characters that cannot be mapped are dropped
(L<MARC::Charset> still warns about each one) and the rest of the field is
kept. This is the same as C<yaz-marcdump -f marc8 -t utf8>. The setting
applies to that call only; it does not change
C<< MARC::Charset->ignore_errors() >>.

=back

Any other value makes C<record()> and C<decode()> die.

=head1 TODO

=over 4

=item * Support for callback filters in decode().

=back

=head1 SEE ALSO

=over 4

=item L<http://www.loc.gov/standards/marcxml/>

=item L<MARC::File::USMARC>

=item L<MARC::Batch>

=item L<MARC::Record>

=back

=head1 AUTHORS

=over 4 

=item * Ed Summers <ehs@pobox.com>

=back

=cut

1;
