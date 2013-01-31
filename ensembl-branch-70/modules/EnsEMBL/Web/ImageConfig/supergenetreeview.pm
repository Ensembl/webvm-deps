# $Id: supergenetreeview.pm,v 1.1 2012-11-03 16:22:29 mm14 Exp $

package EnsEMBL::Web::ImageConfig::supergenetreeview;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;

  $self->set_parameters({
    show_labels => 'no',
    bgcolor     => 'background1',
    bgcolour1   => 'background1',
    bgcolour2   => 'background1',
  });

  $self->create_menus('other');

  $self->add_tracks('other',
    [ 'genetree',        'Gene',   'genetree',        { on => 'on', strand => 'r', menu => 'no' }],
  );
  
  $self->storable = 0;
  $self->{extra_menus} = {'display_options' => 0};
}

1;

