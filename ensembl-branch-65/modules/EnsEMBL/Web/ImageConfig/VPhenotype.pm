# $Id: VPhenotype.pm,v 1.1 2011-11-16 13:49:27 sb23 Exp $

package EnsEMBL::Web::ImageConfig::VPhenotype;

use strict;

use base qw(EnsEMBL::Web::ImageConfig::Vkaryotype);

sub init {
  my $self = shift;
  
  $self->SUPER::init;
  $self->get_node('user_data')->remove;
}

1;
