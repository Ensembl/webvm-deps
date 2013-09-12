# $Id: lrg_summary.pm,v 1.21 2013-01-17 12:04:43 ma7 Exp $

package EnsEMBL::Web::ImageConfig::lrg_summary;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;

  $self->set_parameters({
    opt_lines => 1,  # draw registry lines
    opt_empty_tracks => 1,     # include empty tracks
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
    information
  ));
  
  $self->get_node('transcript')->set('caption', 'Other genes');
  
  $self->add_tracks('information',
    [ 'scalebar',  '', 'lrg_scalebar', { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',        { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable',    { display => 'normal', strand => 'b', menu => 'no' }],
  );
  
  $self->add_tracks('sequence',
    [ 'contig', 'Contigs',  'contig', { display => 'normal', strand => 'r' }]
  );

  $self->load_tracks;
  $self->load_configured_das;

  $self->add_tracks('lrg',
    [ 'lrg_transcript', 'LRG', '_transcript', {
      display     => 'transcript_label',
      strand      => 'f',
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
 
  $self->modify_configs(['transcript'], { strand => 'f'});
 
  $self->modify_configs(
    [ 'fg_regulatory_features_funcgen', 'transcript', 'prediction', 'variation' ],
    { display => 'off' }
  );
  
  $self->modify_configs(
    [ 'reg_feats_MultiCell' ],
    { display => 'normal' }
  );

  $self->modify_configs(
    [ 'transcript_otherfeatures_refseq_human_import', 'transcript_core_ensembl' ],
    { display => 'transcript_label' }
  );
}

1;
