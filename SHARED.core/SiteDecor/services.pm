#########
# Author:        ab6
# Maintainer:    $Author: jc3 $
# Last Modified: $Date: 2009-04-27 10:20:36 $
#
# decoration for services(dev|test)?.sanger.ac.uk
#
package SiteDecor::services;
use strict;
use warnings;
use Sys::Hostname;
use base qw(SiteDecor);
our $VERSION = do { my @r = (q$Revision: 6.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub init_defaults {
  my $self = shift;
  my $def  = {
	      "redirect_delay" => 5,
	      "bannercase"     => 'ucfirst',
	      "author"         => 'webmaster',
	      "decor"          => 'full',
	     };
  $self->merge($def);
}

sub html_headers {
  my $self   = shift;
  my $title  = $self->title() || "Services";

  my $html_headers = qq(<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb">
  <head>
    <title>$title</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="author" content="Genome Research Limited" />
    <meta name="version" content="$VERSION" />
    <style type="text/css" media="screen">
      \@import url(http://$ENV{'HTTP_X_FORWARDED_HOST'}/stylesheets/stylesheet.css);
    </style>
  </head>
  <body>\n);

  return $html_headers;
}

sub site_footers {
  my $self    = shift;
  my $lastmod = "";
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

  return qq(
  </body>
</html>\n);
}

1;
