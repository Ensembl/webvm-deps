# $Id: text_seq_legend.pm,v 1.4 2011-06-10 14:16:57 sb23 Exp $

package EnsEMBL::Web::ImageConfig::text_seq_legend;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;
  $self->set_parameter('show_labels', 'no');
  $self->create_menus('other');
  $self->add_tracks('other', [ 'text_seq_legend', '', 'text_seq_legend', { display => 'normal', strand => 'f' }]);
  $self->storable = 0;
}

1;
