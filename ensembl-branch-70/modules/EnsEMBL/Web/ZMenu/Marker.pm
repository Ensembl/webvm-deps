# $Id: Marker.pm,v 1.3 2010-07-12 15:08:18 sb23 Exp $

package EnsEMBL::Web::ZMenu::Marker;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self = shift;
  my $hub  = $self->hub;
  my $m    = $hub->param('m');
  
  $self->caption($m);
  
  $self->add_entry({
    label => 'Marker info.',
    link  => $hub->url({
      type   => 'Marker',
      action => 'Details',
      m      => $m
    })
  });
}

1;
