# $Id: idhistoryview.pm,v 1.8 2011-08-23 08:53:34 sb23 Exp $

package EnsEMBL::Web::ImageConfig::idhistoryview;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;
  
  $self->set_parameters({
    show_labels => 'no',
  });

  $self->create_menus('idhistory');

  $self->load_tracks;

  $self->add_tracks('idhistory',
    [ 'idhistorytree', '', 'idhistorytree', { display => 'on', strand => 'f', menu => 'no' }]
  );
  
  $self->storable = 0;
}

1;
