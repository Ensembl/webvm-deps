#########
# Author: rmp
#
package SiteDecor::acedb;
use strict;
use warnings;
use base qw(SiteDecor::external);

sub init_defaults {
  my $self = shift;
  my $def  = $self->SUPER::init_defaults();
  $def->{'navbar2'} = [];
  $def->{'author'}  = 'webmaster@acedb.org';
  $def->{'jsfile'}  = ['http://js.sanger.ac.uk/urchin.js'];
  return $def;
}

sub site_footers {
  my $self      = shift;
  my $content   = "";
  my $sangerurl = "http://www.acedb.org";
  $sangerurl    = "http://dev.acedb.org" if($self->is_dev());

  if($self->{'decor'} eq "full") {
    #########
    # short back and sidebars please
    #
    if(defined $self->{'navigator'}) {
      $content .= qq(
        <br /></td>
        <td><img src="/gfx/blank.gif" width="6" height="6" alt="" /></td>
      </tr>
    </table>\n);
    }

    my $lastmod   = "";
    my $req_uri = $ENV{'REQUEST_URI'} || "";

    if($ENV{'LAST_MODIFIED'}) {
      $lastmod = qq(Last Modified $ENV{'LAST_MODIFIED'});
     
    } else {
      #########
      # Look for the request_uri document
      #
      my ($fn) = "$ENV{'DOCUMENT_ROOT'}/$req_uri" =~ m|([a-z\d\./_]+)|i;

      #########
      # If that doesn't exist try the script_filename
      #
      if($fn && !-e $fn) {
        ($fn) = $ENV{'SCRIPT_FILENAME'}||"" =~ m|([a-z\d\./_]+)|i;
      }

      if($fn && -e $fn) {
        my ($mtime)     = (stat($fn))[9];
        my $scriptstamp = localtime($mtime);
        $lastmod        = qq(Last Modified $scriptstamp) if(defined $scriptstamp);
      }
    }

    my $mail = $self->{'author'};
    $mail ||= 'acedb-bug@sanger.ac.uk';

    if($mail !~ /\@/) {
      $mail .= qq(\@sanger.ac.uk);
    }

    $content .= qq(
<!-- page content ends here -->
    <table border="0" cellpadding="0" cellspacing="0" width="100%" align="center">
      <tr valign="top">
        <td colspan="2" class="headerfooterseparator"><img src="/gfx/blank.gif" height="1" width="640" alt="" /></td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="footerbackground"><img src="/gfx/blank.gif" height="2" width="640" alt="" /></td>
      </tr>
      <tr valign="top" class="footerbackground">
        <td align="left"  class="headerinactive" nowrap>&nbsp;$lastmod</td>
        <td align="right" class="headerinactive"><a href="$sangerurl/feedback/">$mail</a>&nbsp;</td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="footerbackground"><img src="/gfx/blank.gif" height="2" width="640" alt="" /></td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="headerfooterseparator"><img src="/gfx/blank.gif" height="1" width="640" alt=""></td>
      </tr>
    </table>
    <script type="text/javascript">
      _userv=0;
      urchinTracker();
    </script>
  </body>
</html>\n);
  }
  return $content;
}

1;
