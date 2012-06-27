# $Id: Genome.pm,v 1.14 2011-11-16 13:13:09 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Location::Genome;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  
  $self->set_defaults({
    chr_length => 300,
    h_padding  => 4,
    h_spacing  => 6,
    v_spacing  => 10,
    rows       => scalar @{$self->species_defs->ENSEMBL_CHROMOSOMES} >= 26 ? 2 : 1,
  });

  $self->add_image_config('Vkaryotype', 'nodas');
  $self->title = 'Genome';
}

sub form {
  my $self = shift;

  $self->add_form_element({
    type    => 'DropDown',
    name    => 'rows',
    label   => 'Number of rows of chromosomes',
    select  => 'select',
    values  => [
      { name => 1, value => 1 },
      { name => 2, value => 2 },
      { name => 3, value => 3 },
      { name => 4, value => 4 },
    ],
  });

  $self->add_form_element({
    type     => 'PosInt',
    name     => 'chr_length',
    label    => 'Height of the longest chromosome (pixels)',
    required => 'yes',
  });
}

1;
