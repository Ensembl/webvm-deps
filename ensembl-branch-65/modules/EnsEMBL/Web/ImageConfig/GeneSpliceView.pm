# $Id: GeneSpliceView.pm,v 1.4 2011-08-23 08:53:33 sb23 Exp $

package EnsEMBL::Web::ImageConfig::GeneSpliceView;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;
  
  $self->set_parameters({
    label_width      => 100, # width of labels on left-hand side
    opt_halfheight   => 0,   # glyphs are half-height [ probably removed when this becomes a track config ]
    opt_empty_tracks => 0,   # include empty tracks..
  });
  
  $self->create_menus(qw(
    transcript
    gsv_transcript
    other 
    gsv_domain
  ));
  
  $self->load_tracks;
  
  $self->get_node('transcript')->set('caption', 'Other genes');
  
  $self->modify_configs(
    [ 'gsv_transcript', 'other' ],
    { menu => 'no' }
  );
  
  if ($self->{'code'} ne $self->{'type'}) {
    my $func = "init_$self->{'code'}";
    $self->$func if $self->can($func);
  }
}

sub init_gene {
  my $self = shift;
  
  $self->add_tracks('other',
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'b', menu => 'no', tag => 0, colours => 'bisque', src => 'all' }]
  );
  
  $self->add_tracks('other',
    [ 'scalebar', '', 'scalebar', { display => 'normal', strand => 'f', menu => 'no'               }],
    [ 'ruler',    '', 'ruler',    { display => 'normal', strand => 'f', menu => 'no', notext => 1  }],
    [ 'spacer',   '', 'spacer',   { display => 'normal', strand => 'r', menu => 'no', height => 52 }],
  );
  
  $self->get_node('gsv_domain')->remove;
}

sub init_transcript {
  my $self = shift;
  
  $self->get_node('transcript')->remove;
  
  $self->add_tracks('other',
    [ 'spacer', '', 'spacer', { display => 'normal', strand => 'r', menu => 'no', height => 10 }],
  );
}

1;
