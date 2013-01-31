# $Id: ChromosomeImage.pm,v 1.2 2011-11-16 13:13:09 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Location::ChromosomeImage;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {  
  my $self = shift;
  $self->add_image_config('Vmapview', 'nodas');
  $self->title = 'Chromosome Image';
}

1;
