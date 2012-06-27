# $Id: MultiTop.pm,v 1.5 2011-11-16 13:13:10 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Location::MultiTop;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;

  $self->set_defaults({
    show_top_panel => 'yes'
  });
  
  $self->add_image_config('MultiTop', 'nodas');
  $self->title = 'Multi-species Overview';
  
  $self->set_defaults({
    opt_join_genes => 'off',
  });
}

sub form {
  my $self = shift;
  
  $self->add_fieldset('Comparative features');
  
  $self->add_form_element({
    type  => 'CheckBox', 
    label => 'Join genes',
    name  => 'opt_join_genes',
    value => 'on',
  });
  
  $self->add_fieldset('Display options');
  
  $self->add_form_element({ type => 'YesNo', name => 'show_top_panel', select => 'select', label => 'Show panel' });
}

1;
