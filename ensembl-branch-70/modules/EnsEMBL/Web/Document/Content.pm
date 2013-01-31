# $Id: Content.pm,v 1.3 2010-09-28 15:16:58 sb23 Exp $

package EnsEMBL::Web::Document::Content;

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub new {
  my ($class, $args) = @_;
  
  my $self = {
    %$args,
    panels => []
  };
  
  bless $self, $class;
  
  return $self;
}

sub add_panel {
  my ($self, $panel) = @_;
  push @{$self->{'panels'}}, $panel;
}

sub panel {
  my ($self, $code) = @_;
  
  foreach (@{$self->{'panels'}}) {
    return $_ if $code eq $_->{'code'};
  }
  
  return undef;
}

sub content {
  my $self = shift;
  my $content;
  
  foreach my $panel (@{$self->{'panels'}}) {
    next if $panel->{'code'} eq 'summary_panel';
    
    $panel->{'disable_ajax'} = 1;
    $panel->renderer = $self->renderer;
    $content .= $panel->component_content;
  }
  
  return $content;
}

sub init {
  my $self       = shift;
  my $controller = shift;
  my $node       = $controller->node;
  
  return unless $node;
  
  my $hub           = $controller->hub;
  my $object        = $controller->object;
  my $configuration = $controller->configuration;
  
  $configuration->{'availability'} = $object ? $object->availability : {};

  my %params = (
    object      => $object,
    code        => 'main',
    omit_header => 1
  );
  
  my $panel = $self->new_panel('Navigation', $controller, %params);
   
  if ($panel) {
    $panel->add_components(@{$node->data->{'components'}});
    $self->add_panel($panel);
  }
}

1;
