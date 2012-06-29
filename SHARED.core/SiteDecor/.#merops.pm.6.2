#########
# perl header & footer module designed for mod_perl use
# Author: rmp
# Maintainer: rmp
# Date: 2002-02-26
#

package SiteDecor::merops;
use strict;
use warnings;
use base qw(SiteDecor);

sub init_defaults {
  my $self = shift;
  my $def  = {
	      "author"     => 'webmaster',
	      "decor"      => 'full',
	      'bannercase' => 'ucfirst',
	     };
  $self->merge($def);
}

sub html_headers {
  my $self = shift;
  my $html_headers = qq(
<html>
  <head>
    <title>MEROPS: the Peptidase Database</title>
    <link rel="stylesheet" type="text/css" href="/styles/meropsbl.css" />
    <link rel="stylesheet" type="text/css" href="/styles/meropsseq.css" />
    <script language="javascript" src="/javascripts/scripts.js"></script>
    <script type="text/javascript" src="http://js.sanger.ac.uk/urchin.js" ></script>
    <style type="text/css">
.violet1 {
  background-color: #EEE8AA;
}

.violet2 {
  background-color: #EEE8AA;
}

.violet3 {
  background-color: #EEE8AA;
}

.barialwbg {
  background-color: #CCCC88;
}

    </style>
  </head>
  <body>\n);
  return $html_headers;
}

sub site_headers {
  my $self = shift;
  my $site_headers = "";

  if(defined $self->{'banner'}) {
    my $banner = "";
    if($self->{'bannercase'} eq "uc") {
      $banner = uc($self->{'banner'});
    } elsif($self->{'bannercase'} eq "ucfirst") {
      $banner = ucfirst($self->{'banner'});
    } else {
      $banner = lc($self->{'banner'});
    }
    $site_headers .= $self->site_banner($banner);
  }

  return $site_headers;
}

sub site_banner {
  my ($self, $heading) = @_;

  return qq(<h1>$heading</h1>);
}

sub site_footers {
  my $self = shift;
  return qq(
    <script type="text/javascript">
      _userv=0;
      urchinTracker();
    </script>
  </body>
</html>\n);
}

1;
