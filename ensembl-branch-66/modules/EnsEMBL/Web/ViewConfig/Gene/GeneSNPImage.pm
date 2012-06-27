# $Id: GeneSNPImage.pm,v 1.1 2011-05-19 09:48:56 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Gene::GeneSNPImage;

use strict;

use base qw(EnsEMBL::Web::ViewConfig::Gene::GeneSNPTable);

sub init {
  my $self = shift;
  $self->SUPER::init;
  $self->add_image_config('GeneSNPView', 'nodas');
}

1;
