# $Id: alignsliceviewbottom.pm,v 1.15 2012-05-10 11:12:40 sb23 Exp $

package EnsEMBL::Web::ImageConfig::alignsliceviewbottom;

use strict;

use base qw(EnsEMBL::Web::ImageConfig::MultiSpecies);

sub init {
  my $self    = shift;
  my $species = $self->species;
  
  $self->set_parameters({
    sortable_tracks => 1, # allow the user to reorder tracks
  });

  $self->create_menus(qw(
    sequence
    transcript
    repeat
    variation
    somatic
    conservation
    information
  ));
  
  if ($species eq 'Multi') {
    $self->set_parameter('sortable_tracks', 0);
  } else {
    $self->load_tracks;
  }
  
  $self->add_track('sequence', 'contig', 'Contigs', 'contig', { display => 'normal', strand => 'r', description => 'Track showing underlying assembly contigs' });
  
  $self->add_tracks('information', 
    [ 'alignscalebar',     '',                  'alignscalebar',     { display => 'normal', strand => 'b', menu => 'no' }],
    [ 'ruler',             '',                  'ruler',             { display => 'normal', strand => 'f', menu => 'no' }],
    [ 'draggable',         '',                  'draggable',         { display => 'normal', strand => 'b', menu => 'no' }], # TODO: get this working
    [ 'alignslice_legend', 'AlignSlice Legend', 'alignslice_legend', { display => 'normal', strand => 'r' }]
  );
  
  $self->modify_configs(
    [ 'transcript' ],
    { renderers => [ 
      off                   => 'Off', 
      as_transcript_label   => 'Expanded with labels',
      as_transcript_nolabel => 'Expanded without labels',
      as_collapsed_label    => 'Collapsed with labels',
      as_collapsed_nolabel  => 'Collapsed without labels' 
    ]}
  );
  
  $self->modify_configs(
    [ 'conservation' ],
    { menu => 'no' }
  );
}

sub species_list {
  my $self = shift;
  
  if (!$self->{'species_list'}) {
    my $species_defs = $self->species_defs;
    my $referer      = $self->hub->referer;
    my ($align)      = split '--', $referer->{'params'}{'align'}[0];
    my $alignment    = $species_defs->multi_hash->{'DATABASE_COMPARA'}{'ALIGNMENTS'}{$align}{'species'} || {};
    my $primary      = $referer->{'ENSEMBL_SPECIES'};
    my @species      = scalar keys %$alignment ? () : ([ $primary, $species_defs->SPECIES_COMMON_NAME($primary) ]);
    
    foreach (sort { $a->[1] cmp $b->[1] } map [ $_, $species_defs->SPECIES_COMMON_NAME($_) ], keys %$alignment) {
      if ($_->[0] eq $primary) {
        unshift @species, $_;
      } elsif ($_->[0] eq 'ancestral_sequences') {
        push @species, [ 'Multi', 'Ancestral sequences' ]; # Cheating: set species to Multi to stop errors due to invalid species.
      } else {
        push @species, $_;
      }
    }
    
    $self->{'species_list'} = \@species;
  }
  
  return $self->{'species_list'};
}

1;
