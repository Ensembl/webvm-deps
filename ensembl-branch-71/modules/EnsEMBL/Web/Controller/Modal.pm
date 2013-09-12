# $Id: Modal.pm,v 1.3 2013-01-11 17:25:31 hr5 Exp $

package EnsEMBL::Web::Controller::Modal;

use strict;

use base qw(EnsEMBL::Web::Controller::Page);

sub page_type { return 'Popup'; }
sub request   { return 'modal'; }

sub init {
  my $self = shift;
  
  $self->builder->create_objects unless $self->page_type eq 'Configurator' && !scalar grep $_, values %{$self->hub->core_params};
  $self->renderer->{'_modal_dialog_'} = $self->r->headers_in->{'X-Requested-With'} eq 'XMLHttpRequest' || $self->hub->param('X-Requested-With') eq 'iframe'; # Flag indicating that this is modal dialog panel, loaded by AJAX/hidden iframe
  $self->page->initialize; # Adds the components to be rendered to the page module
  $self->configure;
  $self->render_page;
}

1;
