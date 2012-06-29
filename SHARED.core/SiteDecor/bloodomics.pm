#########
# perl header & footer module designed for mod_perl use
# Author: rmp
# Maintainer: rmp
# Date: 2002-02-26
#

package SiteDecor::bloodomics;
use strict;
use warnings;
use base qw(SiteDecor);

sub init_defaults {
  my $self = shift;
  my $def  = {
	      "stylesheet"     => [qw(http://www.bloodomics.org/css/bloodomics.css
				    http://www.bloodomics.org/css/style.css)],
	      "redirect_delay" => 5,
	      "bannercase"     => 'ucfirst',
	      "author"         => 'webmaster',
	      "decor"          => 'full',
	     };
  if($self->is_dev()) {
    if(ref($def->{'stylesheet'})) {
      my @st = map { $_ =~ s/www/dev/; $_ } @{$def->{'stylesheet'}};
      $def->{'stylesheet'} = \@st;

    } else {
      $def->{'stylesheet'} =~ s/www/dev/;
    }
  }
  return $def;
}

sub html_headers {
  my $self = shift;
  my @stylesheet = ();
  if($self->{'stylesheet'}) {
    if(ref($self->{'stylesheet'})) {
      push @stylesheet, @{$self->{'stylesheet'}};
    } else {
      push @stylesheet, $self->{'stylesheet'};
    }
  }
    
  return qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>Bloodomics</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<META HTTP-EQUIV="expires" CONTENT="Tue, 04 Dec 1993 21:29:02 GMT">
@{[map { qq(<link href="$_" rel="stylesheet" type="text/css">\n) } @stylesheet]}
</head>

<body leftmargin="0" topmargin="0" marginheight="0" marginwidth="0">\n);

}

sub site_headers {
  my $self = shift;
  my $site_headers = qq(<table width="100%"  border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="11"><img src="/gfx/top_left_grey.gif" width="11" height="17" alt="" /></td>
    <td background="/gfx/top_grey.gif">&nbsp;</td>
  </tr>
  <tr>
    <td width="11"><img src="/gfx/space.gif" width="11" height="142" alt="" /></td>
    <td height="142"><img src="/gfx/knubbel.jpg" alt="logo" width="206" height="142"><img src="/gfx/logo.gif" alt="logo" width="272" height="142" alt="" /><img src="/gfx/image.jpg" alt="laboratory-image" width="297" height="142" /></td>
  </tr>
  <tr>
    <td><img src="/gfx/space.gif" width="11" height="8" alt="" /></td>
    <td background="/gfx/line.gif"><img src="/gfx/space.gif" width="1" height="8" alt="" /></td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td><table width="790" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td width="206" valign="top">\n);

  for my $e ($self->sidebar_entries()) {

    my ($ltld) = $e =~ m|href\s*=\s*"?/([^/]+)/.*?"|i;
    $ltld    ||= "/";
    my ($rtld) = $ENV{'REQUEST_URI'} =~ m|/([^/]+)/|;
    $rtld    ||= "/";
    
    my $colour = "grey";
    if($ltld eq $rtld) {
      $colour = "red";
      $e      =~ s/sidebar/sidebar_hi/;
    }

    $site_headers .= qq(<table width="206" height="22" border="0" cellpadding="0" cellspacing="0">
          <tr>
            <td width="20" background="/gfx/nav_$colour.gif"><img src="/gfx/pfeil_$colour.gif" width="20" height="22" alt="" /></td>
            <td width="186" background="/gfx/nav_$colour.gif">&nbsp;$e</td>
          </tr>
          <tr>
            <td><img src="/gfx/space.gif" width="20" height="5" alt="" /></td>
            <td><img src="/gfx/space.gif" width="20" height="5" alt="" /></td>
          </tr>
        </table>);
  }
  $site_headers .= qq(          <br /></td>
        <td valign="top"><table width="100%"  border="0" cellspacing="0" cellpadding="5">
          <tr>
            <td valign="top">);
  return $site_headers;
}

sub site_footers {
  my $self = shift;
  return qq(</tr>
        </table></td>
      </tr>
    </table></td>
  </tr>
</table>
</body>
</html>\n);
}

1;
