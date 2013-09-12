# $Id: Vsynteny.pm,v 1.8 2012-10-31 11:29:36 ma7 Exp $

package EnsEMBL::Web::ImageConfig::Vsynteny;

use strict;

use base qw(EnsEMBL::Web::ImageConfig::Vertical);

sub init {
  my $self = shift;

  $self->set_parameters({
    toolbars        => {'top' => 1, 'bottom' => 1},
    label           => 'above',
    band_labels     => 'off',
    image_height    => 500,
    image_width     => 550,
    top_margin      => 20,
    band_links      => 'no',
    main_width      => 30,
    secondary_width => 12,
    padding         => 4,
    spacing         => 20,
    inner_padding   => 140,
    outer_padding   => 20,
  });

  $self->create_menus('synteny');
  $self->add_tracks('synteny', [ 'Vsynteny', 'Videogram', 'Vsynteny', { display => 'normal', renderers => [ 'normal', 'normal' ], colourset => 'ideogram' } ]);
  $self->storable = 0;
}

1;
