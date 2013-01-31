# $Id: Help.pm,v 1.33 2012-07-16 10:40:25 ap5 Exp $

package EnsEMBL::Web::Configuration::Help;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub short_caption {
  return 'Help';
}

sub caption {
  return 'Help';
}

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Search';
}

sub modify_page_elements {
  my $self = shift;
  my $page = $self->page;
  
  $page->remove_body_element('tabs');
  $page->remove_body_element('navigation') if $self->hub->action eq 'ListVegaMappings';
}

sub populate_tree {
  my $self = shift;

  my $T = $self->create_node( 'Search', "Search",
    [qw(
      search    EnsEMBL::Web::Component::Search::New
    )],
    { 'availability' => 1}
  );
  my $topic_menu = $self->create_submenu( 'Topics', 'Help topics' );
  $topic_menu->append($self->create_node( 'Faq', "Frequently Asked Questions",
    [qw(
      faq    EnsEMBL::Web::Component::Help::Faq
    )],
    { 'availability' => 1}
  ));
  $topic_menu->append($self->create_node( 'Movie', "Video Tutorials",
    [qw(
      movie    EnsEMBL::Web::Component::Help::Movie
    )],
    { 'availability' => 1}
  ));
  $topic_menu->append($self->create_node( 'Glossary', "Glossary",
    [qw(
      glossary    EnsEMBL::Web::Component::Help::Glossary
    )],
    { 'availability' => 1}
  ));

  $self->create_node( 'Contact', "Contact HelpDesk",
    [qw(contact    EnsEMBL::Web::Component::Help::Contact)],
    { 'availability' => 1}
  );

  ## Add "invisible" nodes used by interface but not displayed in navigation
  $self->create_node( 'Preview', '',
    [qw(contact    EnsEMBL::Web::Component::Help::Preview)],
    { 'availability' => 1, 'no_menu_entry' => 1 }
  );
  $self->create_node( 'MovieFeedback', '',
    [qw(contact    EnsEMBL::Web::Component::Help::MovieFeedback)],
    { 'availability' => 1, 'no_menu_entry' => 1 }
  );
  $self->create_node( 'FeedbackPreview', '',
    [qw(contact    EnsEMBL::Web::Component::Help::FeedbackPreview)],
    { 'availability' => 1, 'no_menu_entry' => 1 }
  );
  $T->append($self->create_subnode( 'EmailSent', '',
    [qw(sent EnsEMBL::Web::Component::Help::EmailSent)],
      { 'no_menu_entry' => 1 }
  ));
  $T->append($self->create_subnode( 'Results', '',
    [qw(sent EnsEMBL::Web::Component::Help::Results
        )],
      { 'no_menu_entry' => 1 }
  ));
  $T->append($self->create_subnode( 'ArchiveList', '',
    [qw(archive EnsEMBL::Web::Component::Help::ArchiveList
        )],
      { 'no_menu_entry' => 1 }
  ));
  $T->append($self->create_subnode( 'Permalink', '',
    [qw(archive EnsEMBL::Web::Component::Help::Permalink
        )],
      { 'no_menu_entry' => 1 }
  ));
  $T->append($self->create_subnode( 'View', 'Page Help',
    [qw(archive EnsEMBL::Web::Component::Help::View
        )],
      { 'no_menu_entry' => 1 }
  ));

   ## And command nodes
  $self->create_node( 'DoSearch', '',
    [],
    { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Help::DoSearch'}
  );
  $self->create_node( 'Feedback', '',
    [],
    { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Help::Feedback'}
  );
  $self->create_node( 'SendEmail', '',
    [],
    { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Help::SendEmail'}
  );
  $self->create_node( 'MovieEmail', '',
    [],
    { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Help::MovieEmail'}
  );

  #to enable the ListVegaMappings page, a menu itme is needed. We do not want ListVegaMappings in the help menu so so a hidden menu item is added.
  $self->create_node('ListVegaMappings', 'Vega',
   [qw( ListVegaMappings EnsEMBL::Web::Component::Help::ListVegaMappings )],
    { 'class'=>'modal_link', 'availability' => 1, 'concise' => 'ListVegaMappings', 'no_menu_entry' => 1 }
  );  
}

1;
