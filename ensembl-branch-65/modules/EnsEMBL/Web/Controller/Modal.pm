# $Id: Modal.pm,v 1.2 2011-05-04 14:35:58 sb23 Exp $

package EnsEMBL::Web::Controller::Modal;

use strict;

use base qw(EnsEMBL::Web::Controller::Page);

sub page_type { return 'Popup'; }
sub request   { return 'modal'; }

sub init {
  my $self = shift;
  
  $self->builder->create_objects unless $self->page_type eq 'Configurator' && !scalar grep $_, values %{$self->hub->core_params};
  $self->renderer->{'_modal_dialog_'} = $self->r->headers_in->{'X-Requested-With'} eq 'XMLHttpRequest'; # Flag indicating that this is modal dialog panel, loaded by AJAX
  $self->page->initialize; # Adds the components to be rendered to the page module
  $self->configure;
  $self->render_page;
}

1;
