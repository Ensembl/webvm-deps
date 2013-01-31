# $Id: reg_detail.pm,v 1.19 2012-12-12 14:54:47 sb23 Exp $

package EnsEMBL::Web::ImageConfig::reg_detail;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;
  
  $self->set_parameters({
    opt_lines => 1,
  });  
  
  $self->create_menus(qw(
    sequence
    transcript
    prediction
    dna_align_rna
    simple
    misc_feature
    functional
    multiple_align
    conservation
    variation
    oligo
    repeat
    other
    information
  ));
  
  $self->add_tracks('other',
    [ 'draggable',                '', 'draggable',                { display => 'normal', strand => 'b', menu => 'no' }],
    [ 'fg_background_regulation', '', 'fg_background_regulation', { display => 'normal', strand => 'b', menu => 'no', tag => 0, colours => 'bisque' }],
    [ 'scalebar',                 '', 'scalebar',                 { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',                    '', 'ruler',                    { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }]
  );
  
  $self->add_tracks('sequence',
    [ 'contig', 'Contigs', 'contig', { display => 'normal', strand => 'r' }]
  );
  
  $self->load_tracks;
  $self->load_configured_das;

  $self->modify_configs(
    [ 'transcript_core_ensembl' ],
    { display => 'collapsed_nolabel' }
  );
  
  $self->modify_configs(
    [ 'alignment_compara_431_constrained' ], 
    { display => 'compact' }
 ); 
 
  $self->modify_configs(
    [ 'regulatory_features', 'functional_other_regulatory_regions' ],
    { display => 'normal' }
  );
  
  $self->modify_configs(
    [ 'regulatory_features_core', 'regulatory_features_non_core' ],
    { display => 'off', menu => 'no' }
  );
  
  $self->modify_configs(
    [ 'gene_legend' ],
    { display => 'off' }
  );

  my @feature_sets = ('cisRED', 'VISTA', 'miRanda', 'NestedMICA', 'REDfly CRM', 'REDfly TFBS');
  
  $self->modify_configs(
    [ map "regulatory_regions_funcgen_$_", @feature_sets ],
    { depth => 25, height => 6 }
  );
}

1;
