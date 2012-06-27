# $Id: FeatureSummary.pm,v 1.2 2011-11-16 13:13:10 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Regulation::FeatureSummary;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->add_image_config('reg_summary');
  $self->title = 'Feature Context';
}

1;
