# $Id: TranscriptsImage.pm,v 1.2 2011-11-16 13:13:09 sb23 Exp $

package EnsEMBL::Web::ViewConfig::LRG::TranscriptsImage;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->add_image_config('lrg_summary');
  $self->title = 'Summary';
}

1;