# $Id: Configurator.pm,v 1.5 2011-05-04 14:41:09 sb23 Exp $

package EnsEMBL::Web::Document::Page::Configurator;

use strict;

use base qw(EnsEMBL::Web::Document::Page::Popup);

sub initialize_HTML {
  my $self = shift;

  return $self->initialize_JSON if $self->renderer->{'_modal_dialog_'};
  
  $self->include_navigation(1);
  
  # General layout for popup pages
  $self->add_head_elements(qw(
    title      EnsEMBL::Web::Document::Element::Title
    stylesheet EnsEMBL::Web::Document::Element::Stylesheet
    links      EnsEMBL::Web::Document::Element::Links
    meta       EnsEMBL::Web::Document::Element::Meta
  ));

  $self->add_body_elements(qw(
    logo            EnsEMBL::Web::Document::Element::Logo
    tabs            EnsEMBL::Web::Document::Element::ModalTabs
    navigation      EnsEMBL::Web::Document::Element::Navigation
    tool_buttons    EnsEMBL::Web::Document::Element::ModalButtons
    content         EnsEMBL::Web::Document::Element::Configurator
    body_javascript EnsEMBL::Web::Document::Element::BodyJavascript
  ));
}

sub initialize_JSON {
  my $self = shift;
  
  $self->add_body_elements(qw(
    tabs         EnsEMBL::Web::Document::Element::ModalTabs
    navigation   EnsEMBL::Web::Document::Element::Navigation
    tool_buttons EnsEMBL::Web::Document::Element::ModalButtons
    content      EnsEMBL::Web::Document::Element::Configurator
  ));
}
1;
