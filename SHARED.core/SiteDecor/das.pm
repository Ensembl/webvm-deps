#########
# perl header & footer module designed for mod_perl use
# Author: rmp
# Maintainer: rmp
# Date: 2002-02-26
#

package SiteDecor::das;
use strict;
use warnings;
use base qw(SiteDecor);

sub init_defaults {
  my $self = shift;
  my $def = {
	     "author"         => 'webmaster',
	     "decor"          => 'full',
	    };
  $self->merge($def);
}

sub html_headers {
  my $self = shift;
  my $html_headers = qq(
<html>
  <head>
    <title>WTSI DAS Services</title>
    <link rel="stylesheet" type="text/css" href="/stylesheets/das.css" />
  </head>
  <body>\n);
  return $html_headers;
}

sub html_footers {
  my $self = shift;
  return qq(
  </body>
</html>\n);
}

1;
