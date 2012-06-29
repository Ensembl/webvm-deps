#########
# Author: rmp
#
# Who's currently logged in?
#
package Website::portlet::pdfconvertor;
use strict;
use warnings;
use base qw(Website::portlet);

sub requires_authorisation { 1; }

sub is_authorised {
  return $ENV{'localuser'};
}

sub authorised_run {
  my $self     = shift;
  my $user     = Website::SSO::User->new();
  return qq(<div class="portlet">
  <div class="portlethead">DOC/PPT to PDF Convertor</div>
  <div class="portletitem">
    <form action="http://intweb$ENV{'dev'}.sanger.ac.uk/cgi-bin/utils/doc2pdf" method="POST" enctype="multipart/form-data">
      <input type="file" name="docdata" size="8" />
      <input type="submit" value="convert!" />
    </form>
  </div>
</div>\n);
}

1;
