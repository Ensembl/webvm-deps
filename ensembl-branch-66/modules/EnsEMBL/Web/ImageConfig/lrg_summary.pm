# $Id: lrg_summary.pm,v 1.13 2011-08-23 08:53:34 sb23 Exp $

package EnsEMBL::Web::ImageConfig::lrg_summary;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;

  $self->set_parameters({
    opt_lines => 1,  # draw registry lines
  });

  $self->create_menus(qw(
    sequence
    transcript
    prediction
    lrg
    variation
    somatic
    functional
    external_data
    user_data
    other
  ));
  
  $self->get_node('transcript')->set('caption', 'Other genes');
  
  $self->add_tracks('other',
    [ 'scalebar',  '', 'lrg_scalebar', { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',        { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable',    { display => 'normal', strand => 'b', menu => 'no' }],
  );
  
  $self->add_tracks('sequence',
    [ 'contig', 'Contigs',  'stranded_contig', { display => 'normal', strand => 'r' }]
  );

  $self->load_tracks;
  $self->load_configured_das;

  $self->add_tracks('lrg',
    [ 'lrg_transcript', 'LRG', '_transcript', {
      display     => 'normal',
      name        => 'LRG transcripts', 
      description => 'Shows LRG transcripts',
      logic_names => [ 'LRG_import' ], 
      logic_name  => 'LRG_import',
      colours     => $self->species_defs->colour('gene'),
      label_key   => '[display_label]',
      colour_key  => '[logic_name]',
      zmenu       => 'LRG',
    }]
  );
  
  $self->modify_configs(
    [ 'fg_regulatory_features_funcgen', 'transcript', 'prediction', 'variation' ],
    { display => 'off' }
  );
  
  $self->modify_configs(
    [ 'reg_feats_MultiCell', 'variation_feature_variation' ],
    { display => 'normal' }
  );

  $self->modify_configs(
    [ 'transcript_core_ensembl' ],
    { display => 'transcript_label' }
  );
}

1;
