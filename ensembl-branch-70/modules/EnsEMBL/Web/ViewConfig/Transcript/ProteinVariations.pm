# $Id: ProteinVariations.pm,v 1.5 2012-07-18 10:37:28 wm2 Exp $

package EnsEMBL::Web::ViewConfig::Transcript::ProteinVariations;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  
  $self->set_defaults({
    consequence_format => 'so',
  });

  $self->title = 'Protein Variations';
}

sub form {
  my $self = shift;

  $self->add_form_element({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'Type of consequences to display',
    name   => 'consequence_format',
    values => [
      { value => 'so',      name => 'Sequence Ontology terms' },
      { value => 'ensembl', name => 'Old Ensembl terms'       },
    ]
  });  
}

1;
