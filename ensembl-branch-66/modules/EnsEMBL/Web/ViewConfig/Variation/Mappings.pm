# $Id: Mappings.pm,v 1.7.2.1 2012-02-15 11:46:08 wm2 Exp $

package EnsEMBL::Web::ViewConfig::Variation::Mappings;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  
  $self->set_defaults({
    consequence_format => 'ensembl',
    motif_scores       => 'no'
  });

  $self->title = 'Genes and regulation';
}

sub form {
  my $self = shift;
  
  $self->add_form_element({
    type   => 'DropDown',
    select => 'select',
    label  => 'Type of consequences to display',
    name   => 'consequence_format',
    values => [
      { value => 'ensembl', name => 'Ensembl terms'           },
      { value => 'so',      name => 'Sequence Ontology terms' },
      { value => 'ncbi',    name => 'NCBI terms'              },
    ]
  }); 
  
  if ($self->hub->species =~ /homo_sapiens|mus_musculus/i) {
    $self->add_form_element({
      type  => 'CheckBox',
      label => 'Show regulatory motif binding scores',
      name  => 'motif_scores',
      value => 'yes',
      raw   => 1,
    });
  }
}

1;
