# $Id: Blast.pm,v 1.2 2010-09-28 15:17:24 sb23 Exp $

package EnsEMBL::Web::Controller::Blast;

use strict;

use base qw(EnsEMBL::Web::Controller);

sub renderer_type   { return 'Apache';    }
sub content :lvalue { $_[0]->{'content'}; }

sub init {
  my $self = shift;
  my $page = $self->page;
  
  $page->include_navigation(0);
  
  $page->add_head_elements(qw(
    title      EnsEMBL::Web::Document::Element::Title
    stylesheet EnsEMBL::Web::Document::Element::Stylesheet
    javascript EnsEMBL::Web::Document::Element::Javascript
    links      EnsEMBL::Web::Document::Element::Links
    meta       EnsEMBL::Web::Document::Element::Meta
  ));
  
  $page->add_body_elements(qw(
    logo             EnsEMBL::Web::Document::Element::Logo
    search_box       EnsEMBL::Web::Document::Element::SearchBox
    tools            EnsEMBL::Web::Document::Element::ToolLinks
    content          EnsEMBL::Web::Document::Element::Content
    modal            EnsEMBL::Web::Document::Element::Modal
    acknowledgements EnsEMBL::Web::Document::Element::Acknowledgements
    copyright        EnsEMBL::Web::Document::Element::Copyright
    footerlinks      EnsEMBL::Web::Document::Element::FooterLinks
    body_javascript  EnsEMBL::Web::Document::Element::BodyJavascript
  ));
  
  $page->_init;
}

1;
