#########
# Author:        rmp
# Maintainer:    rmp
# Created:       ?
# Last Modified: 2006-03-30 rmp - validate.pl converted into more generic OO class
#
# To be run on XML::Xerces / xerces-c 2.7.0
#
package XML::Xerces::SchemaValidator;
use strict;
use XML::Xerces;

our @ISA      = "XML::Xerces::XercesDOMParser";
our $DEFAULTS = {
		 'setValidationScheme'             => $XML::Xerces::AbstractDOMParser::Val_Always,
		 'setDoNamespaces'                 => 1,
		 'setDoSchema'                     => 1,
		 'setValidationSchemaFullChecking' => 1,
		};

sub new {
  my $class = shift;
  my $self  = XML::Xerces::XercesDOMParser->new();
  bless $self, $class;

  for my $k (keys %$DEFAULTS) {
    $self->$k($DEFAULTS->{$k}) if($self->can($k));
  }

  $self->setErrorHandler(XML::Xerces::PerlErrorHandler->new());

  return $self;
}

sub setExternalSchemaLocation {
  my ($self, $schema) = @_;

  if(ref($schema) && ref($schema) eq "ARRAY") {
    $schema = join("\n", @$schema)."\n";
  }

  return $self->SUPER::setExternalSchemaLocation($schema);
}

1;
