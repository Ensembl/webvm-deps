# $Id: FlankingSequence.pm,v 1.2 2011-11-16 13:13:10 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Variation::FlankingSequence;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  
  $self->set_defaults({
    flank_size      => 400,
    show_mismatches => 'yes',
    display_type    => 'align'
  });

  $self->title = 'Flanking sequence';
}

sub form {
  my $self = shift;
  
  $self->add_form_element({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'Length of reference flanking sequence to display',
    name   => 'flank_size',
    values => [
      { value => '100',  name => '100bp'  },
      { value => '200',  name => '200bp'  },
      { value => '300',  name => '300bp'  },
      { value => '400',  name => '400bp'  },
      { value => '500',  name => '500bp'  },
      { value => '500',  name => '500bp'  },
      { value => '1000', name => '1000bp' },
    ]
  });  
  
  $self->add_form_element({
    type   => 'DropDown',
    select =>, 'select',
    label  => 'Type of display when flanking sequence differs from reference',
    name   => 'display_type',
    values => [
      { value => 'align',  name => 'NW alignment' },
      { value => 'basic',  name => 'Basic' },
    ]
  });
  
  $self->add_form_element({
    type  => 'CheckBox',
    label => 'Highlight differences between source and reference flanking sequences',
    name  => 'show_mismatches',
    value => 'yes',
    raw   => 1,
  });
}

1;
