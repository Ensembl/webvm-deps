# $Id: lrgsnpview_gene.pm,v 1.5 2011-05-04 15:41:55 sb23 Exp $

package EnsEMBL::Web::ImageConfig::lrgsnpview_gene;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;

  $self->set_parameters({
    title            => 'MyGenes',
    show_labels      => 'yes', # show track names on left-hand side
    label_width      => 100,   # width of labels on left-hand side
    opt_halfheight   => 0,     # glyphs are half-height [ probably removed when this becomes a track config ]
    opt_empty_tracks => 0,     # include empty tracks
  });
  
  $self->create_menus(      
    lrg        => 'LRG transcripts',
    transcript => 'Other Genes',
    variation  => 'Germline variation',
    somatic    => 'Somatic Mutations',
    other      => 'Other Stuff'
  );
  
  $self->load_tracks;

  $self->add_tracks('lrg',
    [ 'lrg_transcript', 'LRG', '_lrg_transcript', {
      display     => 'normal', 
      name        => 'LRG transcripts', 
      description => 'Shows LRG transcripts', 
      logic_names => [ 'LRG_import' ], 
      logic_name  => 'LRG_import',
      colours     => $self->species_defs->colour('gene'),
      label_key   => '[display_label]',
    }]
  );


  $self->add_tracks('variation',
    [ 'snp_join',         '', 'snp_join',         { display => 'on',     strand => 'b', menu => 'no', tag => 0, colours => $self->species_defs->colour('variation') }],
    [ 'geneexon_bgtrack', '', 'geneexon_bgtrack', { display => 'normal', strand => 'b', menu => 'no', tag => 0, colours => 'bisque', src => 'all' }]
  );
  
  $self->add_tracks('other',
    [ 'scalebar', '', 'scalebar', { display => 'normal', strand => 'f', menu => 'no' }],
    [ 'ruler',    '', 'ruler',    { display => 'normal', strand => 'f', menu => 'no', notext => 1 }],
    [ 'spacer',   '', 'spacer',   { display => 'normal', strand => 'r', menu => 'no', height => 50 }]
  );
  

  $self->modify_configs(
    [ 'transcript', 'transcript_core_ensembl' ],
    { display => 'off' }
  );
  
  $self->modify_configs(
    [ 'variation' ],
    { menu => 'no' }
  );
  
  $self->modify_configs(
    [ 'variation_feature_variation' ],
    { display => 'normal', caption => 'Variations', strand => 'f' }
  );
}

1;
