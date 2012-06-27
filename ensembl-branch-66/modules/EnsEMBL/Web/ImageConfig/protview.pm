# $Id: protview.pm,v 1.20 2011-11-25 09:09:18 sb23 Exp $

package EnsEMBL::Web::ImageConfig::protview;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;

  $self->set_parameters({ sortable_tracks => 'drag' });
  
  $self->create_menus(qw(
    domain
    feature
    variation
		somatic
    other
    information
  ));
  
  $self->load_tracks;
  
  $self->modify_configs(
    [ 'variation', 'somatic' ],
    { menu => 'no' }
  );
  
  $self->modify_configs(
    [ 'variation_feature_variation', 'somatic_mutation_COSMIC' ],
    { menu => 'yes', glyphset => 'P_variation', display => 'normal', strand => 'r', colourset => 'protein_feature', depth => 1e5 }
  );
  
  $self->modify_configs(
    [ 'variation_legend' ],
    { glyphset => 'P_variation_legend' }
  );
  
  $self->add_tracks('other',
    [ 'scalebar',       'Scale bar', 'P_scalebar', { display => 'normal', strand => 'r' }],
    [ 'exon_structure', 'Protein',   'P_protein',  { display => 'normal', strand => 'f', colourset => 'protein_feature', menu => 'no' }],
  );
}

1;
