#########
# Author: rmp
#
# Who's currently logged in?
#
package Website::portlet::logins;
use strict;
use warnings;
use base qw(Website::portlet);
use Website::SSO::User;

sub requires_authorisation { 1; }

sub authorised_users {
  [qw(rmp jc3 ab6 jws)];
}

sub authorised_run {
  my $self     = shift;
  my $user     = Website::SSO::User->new();

  return qq(<div class="portlet" id="portlet_logins">
  <div class="portlethead">Logins</div>
  <div class="portletitem">@{[map {
    my $un  = $_->username();
    my $str = sprintf("%s: %s [%s]",
                      $un,
                      $_->realname() || '',
                      $_->note());
    qq(<a href="http://intweb.sanger.ac.uk/cgi-bin/utils/useradmin?action=report;username=$un"><img border="0" src="http://intweb.sanger.ac.uk/cgi-bin/phonebook.pl?uid=$un;action=photo" width="30" alt="$str" title="$str" /></a>);
  } grep { $_->username() !~ /\@/ } $user->logins() ]}</div>
</div>\n);
}

1;

