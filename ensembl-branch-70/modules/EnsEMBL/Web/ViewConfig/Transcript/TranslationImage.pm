# $Id: TranslationImage.pm,v 1.2 2011-11-16 13:13:10 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Transcript::TranslationImage;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->add_image_config('protview');
  $self->title = 'Protein summary';
}

1;
