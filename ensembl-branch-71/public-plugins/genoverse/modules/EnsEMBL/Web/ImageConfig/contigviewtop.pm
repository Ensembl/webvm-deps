# $Id: contigviewtop.pm,v 1.1 2013-03-15 09:38:00 sb23 Exp $

package EnsEMBL::Web::ImageConfig::contigviewtop;

use strict;

use JSON;

use base qw(EnsEMBL::Web::ImageConfig::Genoverse);

sub modify {
  my $self = shift;
  
  $self->init_genoverse;
  $self->set_parameter('zoom', 'no');
}

1;
