# $Id: genetreeview.pm,v 1.8 2012-09-13 10:53:21 ma7 Exp $

package EnsEMBL::Web::ImageConfig::genetreeview;

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
    [ 'genetree_legend', 'Legend', 'genetree_legend', { on => 'on', strand => 'r', menu => 'no' }],
  );
  
  $self->storable = 0;
  $self->{extra_menus} = {'display_options' => 1};
}

1;

