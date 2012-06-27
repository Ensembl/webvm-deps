# $Id: Region.pm,v 1.5 2011-11-16 13:13:10 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Location::Region;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->add_image_config('cytoview');
  $self->title = 'Region Overview';
}

1;
