package XML::Validator::Schema;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.10';

=head1 NAME

XML::Validator::Schema - validate XML against a subset of W3C XML Schema

=head1 SYNOPSIS

  use XML::SAX::ParserFactory;
  use XML::Validator::Schema;

  #
  # create a new validator object, using foo.xsd
  #
  $validator = XML::Validator::Schema->new(file => 'foo.xsd');

  #
  # create a SAX parser and assign the validator as a Handler
  #
  $parser = XML::SAX::ParserFactory->parser(Handler => $validator);

  #
  # validate foo.xml against foo.xsd
  #
  eval { $parser->parse_uri('foo.xml') };
  die "File failed validation: $@" if $@;

=head1 DESCRIPTION

This module allows you to validate XML documents against a W3C XML
Schema.  This module does not implement the full W3C XML Schema
recommendation (http://www.w3.org/XML/Schema), but a useful subset.
See the L<SCHEMA SUPPORT|"SCHEMA SUPPORT"> section below.

B<IMPORTANT NOTE>: To get line and column numbers in the error
messages generated by this module you must install
L<XML::Filter::ExceptionLocator|XML::Filter::ExceptionLocator> and use
L<XML::SAX::ExpatXS|XML::SAX::ExpatXS> as your SAX parser.  This
module is much more useful if you can tell where your errors are, so
using these modules is highly recommeded!

=head1 INTERFACE

=over 4

=item *

C<< XML::Validator::Schema->new(file => 'file.xsd', cache => 1) >>

Call this method to create a new XML::Validator:Schema object.  The
only required option is C<file> which must provide a path to an XML
Schema document.

Setting the optional C<cache> parameter to 1 causes
XML::Validator::Schema to keep a copy of the schema parse tree in
memory.  The tree will be reused on subsequent calls with the same
C<file> parameter, as long as the mtime on the schema file hasn't
changed.  This can save a lot of time if you're validating many
documents against a single schema.

Since XML::Validator::Schema is a SAX filter you will normally pass
this object to a SAX parser:

  $validator = XML::Validator::Schema->new(file => 'foo.xsd');
  $parser = XML::SAX::ParserFactory->parser(Handler => $validator);

Then you can proceed to validate files using the parser:

  eval { $parser->parse_uri('foo.xml') };
  die "File failed validation: $@" if $@;

Setting the optional C<debug> parameter to 1 causes
XML::Validator::Schema to output elements and associated attributes
while parsing and validating the XML document. This provides useful
information on the position where the validation failed (although not
at useful as the line and column numbers included when
XML::Filter::ExceptiionLocator and XML::SAX::ExpatXS are used).

=back

=head1 RATIONALE

I'm writing a piece of software which uses Xerces/C++
( http://xml.apache.org/xerces-c/ ) to validate documents against XML
Schema schemas.  This works very well, but I'd like to release my
project to the world.  Requiring users to install Xerces is simply too
onerous a requirement; few will have it already and the Xerces
installation system leaves much to be desired.

On CPAN, the only available XML Schema validator is XML::Schema.
Unfortunately, this module isn't ready for use as it lacks the ability
to actually parse the XML Schema document format!  I looked into
enhancing XML::Schema but I must admit that I'm not smart enough to
understand the code...  One day, when XML::Schema is completed I will
replace this module with a wrapper around it.

This module represents my attempt to support enough XML Schema syntax
to be useful without attempting to tackle the full standard.  I'm sure
this will mean that it can't be used in all situations, but hopefully
that won't prevent it from being used at all.

=head1 SCHEMA SUPPORT

=head2 Supported Elements

The following elements are supported by the XML Schema parser.  If you
don't see an element or an attribute here then you definitely can't
use it in a schema document. 

You can expect that the schema document parser will produce an error
if you include elements which are not supported.  However, unsupported
attributes I<may> be silently ignored.  This should not be
misconstrued as a feature and will eventually be fixed.

All of these elements must be in the http://www.w3.org/2001/XMLSchema
namespace, either using a default namespace or a prefix.

  <schema>

     Supported attributes: targetNamespace, elementFormDefault,
     attributeFormDefault

     Notes: the only supported values for elementFormDefault and
     attributeFormDefault are "unqualified."  As such, targetNamespace
     is essentially ignored.
        
  <element name="foo">

     Supported attributes: name, type, minOccurs, maxOccurs, ref

  <attribute>

     Supported attributes: name, type, use, ref

  <sequence>

     Supported attributes: minOccurs, maxOccurs

  <choice>

     Supported attributes: minOccurs, maxOccurs

  <all>

     Supported attributes: minOccurs, maxOccurs

  <complexType>

    Supported attributes: name

  <simpleContent>

    The only supported sub-element is <extension>.

  <extension>

    Supported attributes: base

    Notes: only allowed inside <simpleContent>

  <simpleType>

    Supported attributes: name

  <restriction>

    Supported attributes: base

    Notes: only allowed inside <simpleType>

  <whiteSpace>

    Supported attributes: value

  <pattern>

    Supported attributes: value

  <enumeration>

    Supported attributes: value

  <length>

    Supported attributes: value

  <minLength>

    Supported attributes: value

  <maxLength>

    Supported attributes: value

  <minInclusive>

    Supported attributes: value

  <minExclusive>

    Supported attributes: value

  <maxInclusive>

    Supported attributes: value

  <maxExclusive>

    Supported attributes: value

  <totalDigits>

    Supported attributes: value

  <fractionDigits>

    Supported attributes: value

  <annotation>

  <documentation>

    Supported attributes: name

  <union>
    Supported attributes: MemberTypes

=head2 Simple Type Support

Supported built-in types are:

  string

  normalizedString

  token

  NMTOKEN

   Notes: the spec says NMTOKEN should only be used for attributes,
   but this rule is not enforced.

  boolean

  decimal

   Notes: the enumeration facet is not supported on decimal or any
   types derived from decimal.

  integer

  int

  short

  byte

  unsignedInt

  unsignedShort

  unsignedByte

  positiveInteger

  negativeInteger

  nonPositiveInteger

  nonNegativeInteger

  dateTime

    Notes: Although dateTime correctly validates the lexical format it does not
    offer comparison facets (min*, max*, enumeration).

  double

    Notes: Although double correctly validates the lexical format it
    does not offer comparison facets (min*, max*, enumeration).  Also,
    minimum and maximum constraints as described in the spec are not
    checked.

  float

    Notes: The restrictions on double support apply to float as well.

  duration

  time

  date

  gYearMonth

  gYear

  gMonthDay

  gDay

  gMonth

  hexBinary

  base64Binary

  anyURI

  QName

  NOTATION

=head2 Miscellaneous Details

Other known devations from the specification:

=over

=item *

Patterns specified in pattern simpleType restrictions are Perl regexes
with none of the XML Schema extensions available.

=item *

No effort is made to prevent the declaration of facets which "loosen"
the restrictions on a type.  This is a bug and will be fixed in a
future release.  Until then types which attempt to loosen restrictions
on their base class will behave unpredictably.

=item *

No attempt has been made to exclude content models which are
ambiguous, as the spec demands.  In fact, I don't see any compelling
reason to do so, aside from strict compliance to the spec.  The
content model implementaton uses regular expressions which should be
able to handle loads of ambiguity without significant performance
problems.

=item *

Marking a facet "fixed" has no effect.

=item *

SimpleTypes must come after their base types in the schema body.  For
example, this is ok:

    <xs:simpleType name="foo">
        <xs:restriction base="xs:string">
            <xs:minLength value="10"/>
        </xs:restriction>
    </xs:simpleType>
    <xs:simpleType name="foo_bar">
        <xs:restriction base="foo">
            <xs:length value="10"/>
        </xs:restriction>
    </xs:simpleType>

But this is not:

    <xs:simpleType name="foo_bar">
        <xs:restriction base="foo">
            <xs:length value="10"/>
        </xs:restriction>
    </xs:simpleType>
    <xs:simpleType name="foo">
        <xs:restriction base="xs:string">
            <xs:minLength value="10"/>
        </xs:restriction>
    </xs:simpleType>

=back

=head1 CAVEATS

Here are a few gotchas that you should know about:

=over

=item *

No Unicode testing has been performed, although it seems possible that
the module will handle Unicode data correctly.

=item *

Namespace processing is almost entirely missing from the module.

=item *

Little work has been done to ensure that invalid schemas fail
gracefully.  Until that is done you may want to develop your schemas
using a more mature validator (like Xerces or XML Spy) before using
them with this module.

=back

=head1 BUGS

Please use C<rt.cpan.org> to report bugs in this module:

  http://rt.cpan.org

Please note that I will delete bugs which merely point out the lack of
support for a particular feature of XML Schema.  Those are feature
requests, and believe me, I know we've got a long way to go.

=head1 SUPPORT

This module is supported on the perl-xml mailing-list.  Please join
the list if you have questions, suggestions or patches:

  http://listserv.activestate.com/mailman/listinfo/perl-xml

=head1 CVS

If you'd like to help develop XML::Validator::Schema you'll want to
check out a copy of the CVS tree:

  http://sourceforge.net/cvs/?group_id=89764

=head1 CREDITS

The following people have contributed bug reports, test cases and/or
code:

  Russell B Cecala (aka Plankton)
  David Wheeler
  Toby Long-Leather
  Mathieu
  h.bridge@fasol.fujitsu.com
  michael.jacob@schering.de
  josef@clubphoto.com
  adamk@ali.as
  Jean Flouret

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2003 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 A NOTE ON DEVELOPMENT METHODOLOGY

This module isn't just an XML Schema validator, it's also a test of
the Test Driven Development methodology.  I've been writing tests
while I develop code for a while now, but TDD goes further by
requiring tests to be written I<before> code.  One consequence of this
is that the module code may seem naive; it really is I<just enough>
code to pass the current test suite.  If I'm doing it right then there
shouldn't be a single line of code that isn't directly related to
passing a test.  As I add functionality (by way of writing tests) I'll
refactor the code a great deal, but I won't add code only to support
future development.

For more information I recommend "Test Driven Development: By Example"
by Kent Beck.

=head1 SEE ALSO

L<XML::Schema>

http://www.w3.org/XML/Schema

http://xml.apache.org/xerces-c/

=cut

use base qw(XML::SAX::Base); # this module is a SAX filter
use Carp qw(croak);          # make some noise
use XML::SAX::Exception;     # for real
use XML::Filter::BufferText; # keep text together
use XML::SAX::ParserFactory; # needed to parse the schema documents

use XML::Validator::Schema::Parser;
use XML::Validator::Schema::ElementNode;
use XML::Validator::Schema::ElementRefNode;
use XML::Validator::Schema::RootNode;
use XML::Validator::Schema::ComplexTypeNode;
use XML::Validator::Schema::SimpleTypeNode;
use XML::Validator::Schema::SimpleType;
use XML::Validator::Schema::TypeLibrary;
use XML::Validator::Schema::ElementLibrary;
use XML::Validator::Schema::AttributeLibrary;
use XML::Validator::Schema::ModelNode;
use XML::Validator::Schema::Attribute;
use XML::Validator::Schema::AttributeNode;

use XML::Validator::Schema::Util qw(_err);
our %CACHE;

our $DEBUG = 0;

# create a new validation filter
sub new {
    my $pkg  = shift;
    my $opt  = (@_ == 1)  ? { %{shift()} } : {@_};
    my $self = bless $opt, $pkg;

    $self->{debug} = exists $self->{debug} ? $self->{debug} : $DEBUG;

    # check options
    croak("Missing required 'file' option.") unless $self->{file};

    # if caching is on, check the cache
    if ($self->{cache} and
        exists $CACHE{$self->{file}} and 
        $CACHE{$self->{file}}{mtime} == (stat($self->{file}))[9]) {

        # load cached object
        $self->{node_stack} = $CACHE{$self->{file}}{node_stack};

        # might have nodes on it leftover from failed validation,
        # truncate to root
        $#{$self->{node_stack}} = 0;

        # clean up any lingering state from the last use of this tree
        $self->{node_stack}[0]->walk_down(
           { callback => sub { shift->clear_memory; 1; } });

    } else {
        # create an empty element stack
        $self->{node_stack} = [];

        # load the schema, filling in the element tree
        $self->parse_schema();

        # store to cache
        if ($self->{cache}) {
            $CACHE{$self->{file}}{mtime} = (stat($self->{file}))[9];
            $CACHE{$self->{file}}{node_stack} = $self->{node_stack};
        }
    }

    # buffer text for convenience
    my $bf = XML::Filter::BufferText->new( Handler => $self );

    # add line-numbers and column-numbers to errors if
    # XML::Filter::ExceptionLocator is available
    eval { require XML::Filter::ExceptionLocator; };
    if ($@) {
        # no luck, just return the buffer-text handler
        return $bf;
    } else {
        # create a new exception-locator and return it
        my $el = XML::Filter::ExceptionLocator->new( Handler => $bf );
        return $el;
    }
}

# parse an XML schema document, filling $self->{node_stack}
sub parse_schema {
    my $self = shift;

    _err("Specified schema file '$self->{file}' does not exist.")
      unless -e $self->{file};
    
    # initialize the schema parser
    my $parser = XML::Validator::Schema::Parser->new(schema => $self);

    # add line-numbers and column-numbers to errors if
    # XML::Filter::ExceptionLocator is available
    eval { require XML::Filter::ExceptionLocator; };
    unless ($@) {
        # create a new exception-locator and set it up above the parser
        $parser = XML::Filter::ExceptionLocator->new( Handler => $parser );
    }

    # parse the schema file
    $parser = XML::SAX::ParserFactory->parser(Handler => $parser);
    $parser->parse_uri($self->{file});
}

# check element start
sub start_element {
    my ($self, $data) = @_;
    my $name = $data->{LocalName};
    my $node_stack = $self->{node_stack};
    my $element = $node_stack->[-1];

    print STDERR "  " x scalar(@{$node_stack}), " o ", $name, "\n" 
      if $self->{debug};

    # check that this alright
    my $daughter = $element->check_daughter($name);

    # check attributes
    $daughter->check_attributes($data->{Attributes});
    
    if ($self->{debug}) {
        foreach my $att ( keys %{ $data->{Attributes} } ) {
            print STDERR "  " x (scalar(@{$node_stack}) + 2), " - ", 
              $data->{Attributes}->{$att}->{Name}, " = ", 
                $data->{Attributes}->{$att}->{Value}, "\n" 
            }
    }

    # enter daughter node
    push(@$node_stack, $daughter);

    $self->SUPER::start_element($data);
}

# check character content
sub characters {
    my ($self, $data) = @_;
    my $element = $self->{node_stack}[-1];
    $element->check_contents($data->{Data});
    $element->{checked_content} = 1;

    $self->SUPER::characters($data);
}

# finish element checking
sub end_element {
    my ($self, $data) = @_;
    my $node_stack = $self->{node_stack};
    my $element = $node_stack->[-1];

    # check empty content if haven't checked yet
    $element->check_contents('')
      unless $element->{checked_content};
    $element->{checked_content} = 0;

    # final model check
    $element->{model}->check_final_model($data->{LocalName},
                                         $element->{memory} || [])
      if $element->{model};

    # done
    $element->clear_memory();
    pop(@$node_stack);

    $self->SUPER::end_element($data);
}

1;
