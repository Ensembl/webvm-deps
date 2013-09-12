# $Id: Genoverse.pm,v 1.1 2013-03-15 09:38:00 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Location::Genoverse;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->add_image_config('scrollable', 'nodas');
  $self->title = 'Scrollable Region';
}

1;
