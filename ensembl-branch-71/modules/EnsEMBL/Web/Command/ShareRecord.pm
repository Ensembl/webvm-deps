# $Id: ShareRecord.pm,v 1.10 2012-11-29 14:40:43 hr5 Exp $

# this will only work for new user code as old user code will return undef for user->get_group

package EnsEMBL::Web::Command::ShareRecord;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self  = shift;
  my $hub   = $self->hub;
  my $user  = $hub->user;
  my $group = $user->get_group($hub->param('webgroup_id'));
  my %url_params;

  if ($group && $user->is_admin_of($group)) {
    foreach (grep $_, $hub->param('id')) {
      my $user_record = $user->get_record($_);

      next unless $user_record;
      
      my $clone = $user_record->clone;
      
      $clone->owner($group);
      $clone->save('user' => $user);
    }
    
    %url_params = (
      type     => 'UserData',
      action   => 'ManageData',
      function => ''
    );
  } else {
    %url_params = (
      type          => 'UserData',
      action        => 'ManageData',
      filter_module => 'Shareable',
      filter_code   => 'no_group',
    );
  }
 
  $self->ajax_redirect($hub->url(\%url_params));
}

1;
