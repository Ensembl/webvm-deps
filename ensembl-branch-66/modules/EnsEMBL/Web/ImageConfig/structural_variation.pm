# $Id: structural_variation.pm,v 1.6 2011-08-23 08:53:34 sb23 Exp $

package EnsEMBL::Web::ImageConfig::structural_variation;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;

  $self->set_parameters({
    opt_halfheight => 1,  # glyphs are half-height [ probably removed when this becomes a track config ]
    opt_lines      => 1,  # draw registry lines
  });
  
  $self->create_menus(qw(
    transcript
    prediction
    sequence
    variation
    somatic
    functional
    information
    other
  ));
  
  $self->add_tracks('sequence',
    [ 'contig', 'Contigs', 'stranded_contig', { display => 'normal', strand => 'r' }]
  );

 	$self->add_tracks('information',
    [ 'variation_legend', '', 'variation_legend', { display => 'normal', strand => 'r', name => 'Variation Legend', caption => 'Variation legend' }]
  );
  
  $self->add_tracks('other',
    [ 'scalebar', '', 'scalebar', { display => 'normal', strand => 'r', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',    '', 'ruler',    { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }]
  );

  $self->load_tracks;
 
  $self->modify_configs(
   [ 'gene_legend' ],
   { display => 'off', menu => 'no' }
  );

  # variations
	$self->modify_configs(
   [ 'variation_legend', 'somatic', 'functional', 'fg_regulatory_features_legend' ],
   { display => 'off' }
  );
  
  $self->modify_configs(
    [ 'variation' ],
    { display => 'off', style => 'box', depth => 100000 }
  ); 
  
	$self->modify_configs(
    ['somatic_mutation_COSMIC'],
    { style => 'box', depth => 100000 }
  );

	# structural variations
	$self->modify_configs(
    ['variation_feature_structural'],
    { display => 'normal', depth => 50 }
  );
	
	# CNV probes
	$self->modify_configs(
    ['variation_feature_cnv'],
    { display => 'normal', depth => 5 }
  );
	
  # genes
  $self->modify_configs(
    ['transcript_core_ensembl'],
    { display => 'transcript_nolabel' }
  );

  # Turn off cell line wiggle tracks
  my @cell_lines = sort keys %{$self->species_defs->databases->{'DATABASE_FUNCGEN'}->{'tables'}{'cell_type'}{'ids'}};
  
  foreach my $cell_line (@cell_lines) {
    $cell_line =~ s/\:\d*//;
    
    # Turn off core and supporting evidence track
    $self->modify_configs(
      [ "reg_feats_core_$cell_line", "reg_feats_other_$cell_line" ],
      { display => 'off' }
    );
  }
}

1;
