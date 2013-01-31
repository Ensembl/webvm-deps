# $Id: Meta.pm,v 1.2 2012-11-02 12:53:33 www-ens Exp $

package EnsEMBL::Web::Document::Element::Meta;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Document::Element);

sub new {
  return shift->SUPER::new({
    %{$_[0]},
    tags  => {},
    equiv => {}
  });
}

sub add      { $_[0]{'tags'}{$_[1]}  = $_[2]; }
sub addequiv { $_[0]{'equiv'}{$_[1]} = $_[2]; }

sub content {
  my $self = shift;
  my $content;
  
  $content .= sprintf qq{  <meta name="%s" content="%s" />\n},       encode_entities($_), encode_entities($self->{'tags'}{$_})  for keys %{$self->{'tags'}};
  $content .= sprintf qq{  <meta http-equiv="%s" content="%s" />\n}, encode_entities($_), encode_entities($self->{'equiv'}{$_}) for keys %{$self->{'equiv'}};
  $content .= '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=2.0, user-scalable=yes" />';
  
  return $content;
}

sub init {
  # There's nothing in the codebase. Delete?
}

1;
