# $Id: Account.pm,v 1.1 2011-10-11 12:10:09 hr5 Exp $

package EnsEMBL::Web::Configuration::Account;

### Configuration for all views based on the Account hub, including
### account management 

use strict;

use  base qw(EnsEMBL::Web::Configuration);

sub get_valid_action {
  my $self = shift;
  return $_[0] if $_[0] eq 'SetCookie';
  return $self->SUPER::get_valid_action( @_ );
}

sub set_default_action {
  my $self = shift;
  my $user = $self->hub->user;
  if ($user && $user->id) {
    $self->{'_data'}{'default'} = 'Links';
  } else {
    $self->{'_data'}{'default'} = 'Login';
  }
}

sub user_tree { return 1; }

sub user_populate_tree {
  return;
  my $self = shift;
  my $hub = $self->hub;  

  if (my $user = $hub->user) {
    my $settings_menu = $self->create_submenu( 'Settings', 'Manage Saved Settings' );

    $settings_menu->append(
      $self->create_node( 'Bookmark/List', "Bookmarks ([[counts::bookmarks]])", [],
        { 'command' => 'EnsEMBL::Web::Command::Account::Interface::Bookmark',
          'availability' => 1, 'concise' => 'Bookmarks' },
      )
    );

    ## Control panel fixes - custom data section is species-specific
    my $species = $hub->species;
    $species = '' if $species !~ /_/;
    $species = $hub->species_defs->ENSEMBL_PRIMARY_SPECIES unless $species;
    
    $settings_menu->append(
      $self->create_node( 'UserData', "Custom data ([[counts::userdata]])",
        [], { 'availability' => 1, 'url' => $hub->species_path($species).'/UserData/ManageData', 'raw' => 1 },
      )
    );

    $settings_menu->append($self->create_node( 'Annotation/List', "Annotations ([[counts::annotations]])",
    [], { 'command' => 'EnsEMBL::Web::Command::Account::Interface::Annotation',
        'availability' => 1, 'concise' => 'Annotations' }
    ));
    $settings_menu->append(
      $self->create_node( 'Newsfilter/List', "News Filters ([[counts::news_filters]])", [],
        { 'command' => 'EnsEMBL::Web::Command::Account::Interface::Newsfilter', 
          'availability' => 1, 'concise' => 'News Filters' },
      )
    );

    my $groups_menu = $self->create_submenu( 'Groups', 'Groups' );
    
    $groups_menu->append(
      $self->create_node( 'MemberGroups', "Subscriptions ([[counts::member]])",
        [qw(
          groups   EnsEMBL::Web::Component::Account::MemberGroups
          details  EnsEMBL::Web::Component::Account::MemberDetails
        )],
        { 'availability' => 1, 'concise' => 'Subscriptions' }
      )
    );
    
    $groups_menu->append(
      $self->create_node( 'Group/List', "Administrator ([[counts::admin]])", [],
        { 'availability' => 1, 'concise' => 'Administrator',
          'command' => 'EnsEMBL::Web::Command::Account::Interface::Group' },
      )
    );

    $groups_menu->append(
      $self->create_node( 'Group/Add', "Create a New Group",
        [],
        { 'availability' => 1, 'concise' => 'Create a Group', 
          'command' => 'EnsEMBL::Web::Command::Account::Interface::Group', }
      )
    );
    
    ## Add "invisible" nodes used by interface but not displayed in navigation
    ## 1. User records
    $self->create_node( 'Annotation', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Annotation',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'Bookmark', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Bookmark',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'UseBookmark', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::UseBookmark',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'Configuration', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Configuration',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'LoadConfig', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::LoadConfig',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'SetConfig', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::SetConfig',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'Newsfilter', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Newsfilter',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'SaveFavourites', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::SaveFavourites',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'ResetFavourites', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::ResetFavourites',
        'filters' => [qw(Owner)]}
    );
    $self->create_node( 'ClearHistory', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::ClearHistory',
        'filters' => [qw(Owner)]}
    );
    ## 1b. Group membership
    $self->create_node( 'SelectGroup', '',
      [qw(select_group EnsEMBL::Web::Component::Account::SelectGroup)],
      { 'no_menu_entry' => 1 }
    );
    $self->create_node( 'ShareRecord', '',
      [], { 'command' => 'EnsEMBL::Web::Command::ShareRecord',
      'no_menu_entry' => 1 }
    );
    $self->create_node( 'Unsubscribe', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Unsubscribe',
        'filters' => [qw(Member)]}
    );
    ## 2. Group admin
    ## 2a. Group details
    $self->create_node( 'ManageGroup', '',
      [qw(manage_group EnsEMBL::Web::Component::Account::ManageGroup)],
      { 'no_menu_entry' => 1 }
    );
    $self->create_node( 'Group', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::Group',
        'filters' => [qw(Admin)]}
    );
    ## 2b. Group members
    $self->create_node( 'Invite', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Invite',
        'filters' => [qw(Admin)]}
    );
    $self->create_node( 'RemoveInvitation', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::RemoveInvitation',
        'filters' => [qw(Admin)]}
    );
    $self->create_node( 'RemoveMember', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::RemoveMember',
        'filters' => [qw(Admin)]}
    );
    $self->create_node( 'ChangeLevel', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::ChangeLevel',
        'filters' => [qw(Admin)]}
    );
    $self->create_node( 'ChangeStatus', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::ChangeStatus',
        'filters' => [qw(Admin)]}
    );
  }  
}

sub populate_tree {
  my $self = shift;

  if (my $user = $self->hub->user) {
#     $self->create_node( 'Links', 'Quick Links',
#       [qw(links EnsEMBL::Web::Component::Account::Links)],
#       { 'availability' => 1 },
#     );
#     $self->create_node( 'User/Display', 'Your Details', [],
#       { 'availability' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::User' }
#     );
#     $self->create_node( 'ChangePassword', 'Change Password',
#       [qw(password EnsEMBL::Web::Component::Account::Password)], 
#       { 'availability' => 1 }
#     );
#     $self->create_node( 'ResetPassword', '', [],
#       { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::SavePassword',
#         'filters' => [qw(LoginValid)]}
#     );
#     $self->create_node( 'Message', '',
#       [qw(message EnsEMBL::Web::Component::Account::Message)], 
#       { 'no_menu_entry' => 1 }
#     );
    $self->create_node( 'Preferences', "User Preferences",
      [qw(account EnsEMBL::Users::Component::Account::Preferences)],
      { 'availability' => 1 }
    );
  } else {
    $self->create_node( 'Login', "Log in",
      [qw(account EnsEMBL::Users::Component::Account::Login)],
      { 'availability' => 1 }
    );
    $self->create_node( 'Register', 'Register',
      [qw(register EnsEMBL::Users::Component::Account::Register)],
      { 'availability' => 1 },
    );
    $self->create_node( 'LostPassword', "Lost Password",
      [qw(account EnsEMBL::Users::Component::Account::LostPassword)],
      { 'availability' => 1 }
    );
  }

  ## Nodes that need to be available, whether or not the user is logged in
  $self->create_node( 'SetCookie', '', [],
    { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::SetCookie',
      'filters' => [qw(LoginValid)]}
  );
  $self->create_node( 'Logout', '', [],
      { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Users::Command::Account::LogOut'}
  );
#   $self->create_node( 'User', '', [],
#     { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::Interface::User' }
#   );
#   $self->create_node( 'Activate', "",
#     [qw(password EnsEMBL::Web::Component::Account::Password)], 
#     { 'no_menu_entry' => 1, 'filters' => [qw(Activation)] }
#   );
#   $self->create_node( 'SendActivation', '', [],
#     { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::SendActivation'}
#   );
#   $self->create_node( 'ActivationSent', 'Activation Sent',
#     [qw(password EnsEMBL::Web::Component::Account::ActivationSent)], 
#     { 'no_menu_entry' => 1 }
#   );
#   $self->create_node( 'SavePassword', '', [],
#     { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::SavePassword'}
#   );
#   $self->create_node( 'Accept', '', [],
#     { 'no_menu_entry' => 1, 'command' => 'EnsEMBL::Web::Command::Account::AcceptInvitation',
#       'filters' => [qw(Invitation)]}
#   );
}

sub tree_cache_key {
  my ($self, $user, $session) = @_;
  
  ## Default trees for logged-in users and 
  ## for non logged-in are defferent
  ## but we cache both:
  my $class = ref $self;
  my $key = ($self->hub->user)
             ? "::${class}::TREE::USER"
             : "::${class}::TREE";

  ## If $user was passed this is for
  ## user_populate_tree (this user specific tree)
  $key .= '['. $user->id .']'
    if $user;

  return $key;
}

1;
