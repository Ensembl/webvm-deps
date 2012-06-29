#########
# perl header & footer module designed for mod_perl use
# Author: rmp
# Maintainer: rmp
# Date: 2002-02-26
#

package SiteDecor::mitocheck;
use strict;
use warnings;
use base qw(SiteDecor);
use Sys::Hostname;

sub init_defaults {
  my $self = shift;
  my $def  = {
	      "stylesheet"     => "http://$ENV{'HTTP_X_FORWARDED_HOST'}/css/mitocheck.css",
	      "redirect_delay" => 5,
	      "bannercase"     => 'ucfirst',
	      "author"         => 'webmaster',
	      "decor"          => 'full',
	     };
  return $def;
}

#sub html_headers {
#  my $self = shift;
#  my $html_headers = qq(
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
#<html>
#  <head>
#    <title>$self->{'title'}</title>
#    <meta name="description" content="Hosted by The Wellcome Trust Sanger Institute">
#    <meta name="keywords" content="Mitocheck,Phosphorylation,cell cycle,Wellcome Trust,Sanger Institute,Sanger Centre,
#Human Genome Project,Information,human,genetics,uk,sequencing,analysis,genomes,worm,ensembl,genome browser,cancer,micr
#oarrays,functional genomics,bioinformatics,Ensembl,annotation">
#    <link rel="stylesheet" type="text/css" href="$self->{'stylesheet'}">
#  </head>
#  <body>\n);
#  return $html_headers;
#}

sub site_headers {
  my $self = shift;
  my $site_headers = qq(    <table border="0" cellpadding="4" width="800">
      <tr>
        <td colspan="2">
          <table border="0" cellpadding="0" class="header" width="100%">
            <tr valign="middle" align="center">
              <td width="110" rowspan="2"><img src="/gfx/mitocheck-logo-82.gif" height="82" width="83" alt="Mitocheck" title="Mitocheck" /></td>
              <td colspan="5"><img src="/gfx/banner.jpg" border="0" width="384" height="82" alt="" title="" style="border:solid 1px #ffffff;" /></td>
            </tr>
            <tr valign="middle" align="center">
              <td>
                <div id="headlinks">
                  <a href="/">Home</a>
                </div>
              </td>
              <td>
                <div id="headlinks">
                  <a href="/training/">Training</a>
                </div>
              </td>
              <td>
                <div id="headlinks">
                  <a href="/cgi-bin/mtc">Database</a>
                </div>
              </td>
              <td>
                <div id="headlinks">
                  <a href="/meetings.shtml">Meetings</a>
                </div>
              </td>
              <td>
                <div id="headlinks">
                  <a href="/contacts.shtml">Contacts</a>
                </div>
              </td>
            </tr>
          </table>
        </td>
      </tr>
      <tr>
        <td valign="top" align="center" width="110">
      <div id="navlist">
        <ul>\n);

  for my $e ($self->sidebar_entries()) {
    $site_headers .= qq(<li id="menu1">$e</li>\n);
  }
  $site_headers .= qq(
	</ul>
      </div>
    </td>
    <td valign="top" width="690">\n);

  if(defined $self->{'title'}) {
    my $banner = "";
    if($self->{'bannercase'} eq "uc") {
      $banner = uc($self->{'title'});
    } elsif($self->{'bannercase'} eq "ucfirst") {
      $banner = ucfirst($self->{'title'});
    } else {
      $banner = lc($self->{'title'});
    }
    $site_headers .= $self->site_banner($banner);
  }

  return $site_headers;
}

sub site_banner {
  my ($self, $heading) = @_;
  return qq(<div class="banner">$heading</div>\n);
#  return qq(<h3>$heading</h3>\n);
}

sub site_footers {
  my $self    = shift;
  my $lastmod = "";
  my $req_uri = $ENV{'REQUEST_URI'} || q();

  if(defined $ENV{'LAST_MODIFIED'} && $ENV{'LAST_MODIFIED'} ne q{}) {
    $lastmod = qq(Last Modified $ENV{'LAST_MODIFIED'});

  } else {
    #########
    # Look for the request_uri document
    #
    my ($fn) = "$ENV{'DOCUMENT_ROOT'}/$req_uri" =~ m|([a-z\d\./_]+)|mix;

    #########
    # If that doesn't exist try the script_filename
    #
    if($fn && !-e $fn) {
      ($fn) = $ENV{'SCRIPT_FILENAME'}||q() =~ m|([a-z\d\./_]+)|mix;
    }

    if($fn && -e $fn) {
      my ($mtime)     = (stat $fn)[9];
      my $scriptstamp = localtime $mtime;

      if(defined $scriptstamp) {
	$lastmod      = qq(Last Modified $scriptstamp);
      }
    }
  }
  
  return qq(
         </td>
       </tr>
       <tr>
         <td colspan="2">
           <table border="0" cellpadding="4" width="100%" class="footer">
             <tr>
               <td width="33%">
                 Hosted by the <a href="http://www.sanger.ac.uk/">Wellcome Trust Sanger Institute</a>
               </td>
               <td width="33%" align="center">$lastmod</td>
               <td width="33%" align="right">
                 <a href="http://www.sanger.ac.uk/feedback/">webmaster\@mitocheck.org</a>
               </td>
             </tr>
           </table>
         </td>
       </tr>
     </table>
  </body>
</html>\n);
}

1;
