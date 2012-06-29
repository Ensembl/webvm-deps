#########
# Author: rmp
#
package Website::portlet::ssosignon;
use strict;
use Website::portlet;
use vars qw(@ISA);
@ISA = qw(Website::portlet);

sub fields { qw(username); }

sub run {
  my $self = shift;

  if($self->{'username'}) {
    #########
    # logged in
    #
    return qq(<div class="portlet">
  <div class="portlethead">Logged in as $self->{'username'}</div>
  <div class="portletitem">
    <ul>
      <li><a href="http://www$ENV{'dev'}.sanger.ac.uk/cgi-bin/utils/ssoman">Edit your profile</a></li>
      <li><a href="/logout">Logout</a></li>
    </ul>
  </div>
</div>\n);

  } else {
    return qq(<div class="portlet">
  <div class="portlethead">Login</div>
  <div class="portletitem">
    <form method="POST" action="/LOGIN">
      <INPUT TYPE="hidden" NAME="destination" VALUE="$ENV{'REQUEST_URI'}" />\n
      Username: <INPUT TYPE="text"     NAME="credential_0" SIZE="10" MAXLENGTH="10" /><br />
      Password: <INPUT TYPE="password" NAME="credential_1" SIZE="10" MAXLENGTH="10" /><br />
      <input type="submit" value="login" />
    </form>
  </div>
</div>\n);
  }
}

1;
