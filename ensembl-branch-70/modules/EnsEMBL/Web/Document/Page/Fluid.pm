# $Id: Fluid.pm,v 1.2 2012-09-13 09:28:08 ap5 Exp $

package EnsEMBL::Web::Document::Page::Fluid;

### A simplified dynamic page with a more variable layout

use strict;

use base qw(EnsEMBL::Web::Document::Page);

sub initialize_HTML {
  my $self = shift;

  $self->include_navigation(0);
  
  # General layout for dynamic pages
  $self->add_head_elements(qw(
    title      EnsEMBL::Web::Document::Element::Title
    stylesheet EnsEMBL::Web::Document::Element::Stylesheet
    links      EnsEMBL::Web::Document::Element::Links
    meta       EnsEMBL::Web::Document::Element::Meta
  ));
  
  $self->add_body_elements(qw(
    logo             EnsEMBL::Web::Document::Element::Logo
    account          EnsEMBL::Web::Document::Element::AccountLinks
    search_box       EnsEMBL::Web::Document::Element::SearchBox
    tools            EnsEMBL::Web::Document::Element::ToolLinks
    tabs             EnsEMBL::Web::Document::Element::Tabs
    content          EnsEMBL::Web::Document::Element::Content
    modal            EnsEMBL::Web::Document::Element::Modal
    copyright        EnsEMBL::Web::Document::Element::Copyright
    footerlinks      EnsEMBL::Web::Document::Element::FooterLinks
    body_javascript  EnsEMBL::Web::Document::Element::BodyJavascript
  ));
}

sub initialize_Text {
  my $self = shift; 
  $self->add_body_elements(qw(content EnsEMBL::Web::Document::Content));
  $self->_init;
}

sub initialize_XML {
  my $self = shift;
  my $doctype_version = shift || 'xhtml';
  
  $self->set_doc_type('XML', $doctype_version);
  $self->add_body_elements(qw(content EnsEMBL::Web::Document::Content));
  $self->_init;
}

sub initialize_TextGz { shift->initialize_Text; }
sub initialize_Excel  { shift->initialize_Text; }
sub initialize_JSON   { shift->initialize_Text; }
sub initialize_DAS    { shift->initialize_XML(@_); }

sub initialize_error {
  my $self = shift;
  
  $self->include_navigation(1);
  
  $self->add_head_elements(qw(
    title      EnsEMBL::Web::Document::Element::Title
    stylesheet EnsEMBL::Web::Document::Element::Stylesheet
    links      EnsEMBL::Web::Document::Element::Links
    meta       EnsEMBL::Web::Document::Element::Meta
  ));
  
  $self->add_body_elements(qw(
    logo             EnsEMBL::Web::Document::Element::Logo
    search_box       EnsEMBL::Web::Document::Element::SearchBox
    tools            EnsEMBL::Web::Document::Element::ToolLinks
    tabs             EnsEMBL::Web::Document::Element::Tabs
    content          EnsEMBL::Web::Document::Element::Content
    modal            EnsEMBL::Web::Document::Element::Modal
    copyright        EnsEMBL::Web::Document::Element::Copyright
    footerlinks      EnsEMBL::Web::Document::Element::FooterLinks
    body_javascript  EnsEMBL::Web::Document::Element::BodyJavascript
  ));
}

1;
