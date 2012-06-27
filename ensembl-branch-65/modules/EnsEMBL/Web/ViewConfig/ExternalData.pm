# $Id: ExternalData.pm,v 1.11 2011-11-16 13:13:09 sb23 Exp $

package EnsEMBL::Web::ViewConfig::ExternalData;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->set_defaults({ map { $_->logic_name => 'off' } values %{$self->hub->get_all_das} });
  $self->code = $self->type . '::ExternalData';
  $self->title = 'External Data';
}

sub form {
  my $self    = shift;
  my $hub     = $self->hub;
  my $view    = $hub->type . '/ExternalData';
  my @all_das = sort { lc $a->label cmp lc $b->label } grep $_->is_on($view), values %{$hub->get_all_das};
  
  $self->add_fieldset('DAS sources');
  
  foreach my $das (@all_das) {
    $self->add_form_element({
      type  => 'DASCheckBox',
      das   => $das,
      name  => $das->logic_name,
      value => 'yes'
    });
  }
  
  $self->get_form->force_reload_on_submit if $hub->param('reset');
}

1;
