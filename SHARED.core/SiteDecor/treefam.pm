#########
# Author: rmp
# Maintainer: rmp
# Date: 2004-12-15
#
# Treefam site decoration
#
package SiteDecor::treefam;
use strict;
use warnings;
use Sys::Hostname;
use base qw(SiteDecor);

sub init_defaults {
  my $self = shift;
  my $def  = {
	      "author" => 'webmaster',
	      "decor"  => 'full',
	     };
  return $def;
}

sub html_headers {
  qq(<html>
  <head>
    <title>TreeFam</title>
    <link rel="stylesheet" type="text/css" href="/treefam.css" />
  </head>
  <body>\n);
}

sub site_headers {
  my $self  = shift;
  my $title = $self->title() || "";
  my $site_headers = qq(    <table border="0" width="100%" cellspacing="0" cellpadding="6">
      <tr bgcolor="#000070" style="color:#FFFFFF">
        <td align="center">
          <font size="5"><b>TreeFam : <font color="#85a3da">Tree fam</font>ilies database</b></font>
        </td>
      </tr>
      <tr bgcolor="#000070" style="color:#FFFFFF">
        <th align="left">$title</th>
      </tr>
      <tr bgcolor="#6a8ee0">
        <th align="left" class="headerlinks">
          [<a class="headerlinks" href="/">Home</a>]
          [<a class="headerlinks" href="/cgi-bin/search.pl">Search</a>]
          [<a class="headerlinks" href="/cgi-bin/TFinfo.pl?all">Browse</a>]
        </th>
      </tr>
    </table><br clear="all" />\n);

  return $site_headers;
}

sub site_footers {
  my $self    = shift;
  my $lastmod = "";

  if(defined $ENV{"LAST_MODIFIED"}) {
    $lastmod = qq(Last Modified $ENV{"LAST_MODIFIED"});
    
  } elsif(defined $ENV{"SCRIPT_FILENAME"}) {
    $ENV{"SCRIPT_FILENAME"} =~ /^(.*)$/;
    my $filename    = $1;
    my ($mtime)     = (stat($filename))[9];
    my $scriptstamp = localtime($mtime);
    $lastmod        = qq(Last Modified $scriptstamp) if(defined $scriptstamp);
    my $hostnum     = substr(&hostname(), -2, 2) || "";
    $lastmod       .= qq( ($hostnum));
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
                 <a href="http://www.sanger.ac.uk/feedback/">webmaster\@treefam.org</a>
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
