# $Id: Shareable.pm,v 1.10 2011-04-04 12:56:08 ap5 Exp $

package EnsEMBL::Web::Filter::Shareable;

use strict;

use base qw(EnsEMBL::Web::Filter);

### Checks if user has any shareable data

sub init {
  my $self = shift;
  
  $self->messages = {
    no_group      => 'Could not find this group. Please try again',
    none          => 'You have no shareable data. Please add some data to your account in order to share it with colleagues or collaborators.',
    shared        => 'The selected record(s) are already shared with this group.',
    not_shareable => 'Some of the selected records could not be shared with the group, as they have not been saved to your user account. Please correct this and try again.'
  };
}

sub catch {
  my $self = shift;
  my $hub  = $self->hub;
  my $user = $hub->user;
  
  $self->redirect = '/UserData/SelectFile';
  
  my @temp_uploads = $hub->session->get_data(type => 'upload');
  my @user_uploads = $user ? $user->uploads : ();

  my @temp_urls = $hub->session->get_data(type => 'url');
  my @user_urls = $user ? $user->urls : ();

  $self->error_code = 'none' unless @temp_uploads || @user_uploads ||
                                    @temp_urls || @user_urls;

}

1;
