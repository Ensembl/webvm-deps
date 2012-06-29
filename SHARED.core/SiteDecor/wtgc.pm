#########
# Author:        rmp
# Maintainer:    team105-web
# Created:       2002-02-26
# Last Modified: $Date: 2010-06-11 09:40:13 $ $Author: nb5 $
# Id:            $Id: wtgc.pm,v 6.9 2010-06-11 09:40:13 nb5 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/SiteDecor/wtgc.pm,v $
# $HeadURL$
#
# decoration for (www|dev).wtgc.org
#
package SiteDecor::wtgc;
use strict;
use warnings;
use base qw(SiteDecor);
use Sys::Hostname;

our $VERSION = do { my @r = (q$Revision: 6.9 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $JSMAP   = {
		'/js/sorttable.js' => 'http://js.sanger.ac.uk/sorttable.js',
	       };

sub init_defaults {
  my $self = shift;
  my $def  = {
	      'stylesheet'     => "http://$ENV{'HTTP_X_FORWARDED_HOST'}/stylesheets/wtgc.css",
	      'redirect_delay' => 5,
	      'bannercase'     => 'ucfirst',
	      'author'         => 'webmaster',
	      'decor'          => 'full',
              'jsfile'         => ['http://js.sanger.ac.uk/urchin.js'],
	     };
  $self->merge($def);
  return;
}

sub html_headers {
  my $self         = shift;
  my $title        = $self->title() || 'WTGC Services';
  my ($hostname)   = hostname =~ /^([^\.]+)/mx;
  my $jsfile       = $self->jsfile() || undef;
  my $seen         = {}; # unique check for stylesheets
  my $html_headers = qq(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <!-- Host: $hostname -->
    <title>$title</title>
    @{[map { qq(<link rel="stylesheet" type="text/css" href="$_" />\n); } grep { !$seen->{$_}++ } @{$self->stylesheet()}]}\n);

  if ((ref $jsfile eq 'ARRAY') && scalar @{$jsfile}) {
    push @{$jsfile}, q(http://js.sanger.ac.uk/zebra.js);
    $html_headers .= join q(),
                     map { qq(<script type="text/javascript" src="@{[$JSMAP->{$_}||$_]}" ></script>\n); }
		     grep { $_ }
		     @{$jsfile};
  }

  my $style = $self->style();
  if($style) {
    $html_headers .= qq(<style type="text/css">$style</style>);
  }

  $html_headers .= qq(</head>
  <body>
 <div id="side_bar">
  <div class="navigation">
   <dl>
   <dt>Organisations</dt>
    <dd><a href="http://www.sanger.ac.uk/">The Wellcome Trust Sanger Institute</a></dd>
    <dd><a href="http://www.ebi.ac.uk/">The European Bioinformatics Institute</a></dd>
    <dd><a href="http://www.hinxton.wellcome.ac.uk/">Hinxton Hall Ltd.</a></dd>
    <dd><a href="http://www.wtconference.org/">Conference Centre</a></dd>
    <dd><a href="/">WTGC Home</a></dd>
   </dl>
  </div>
  <br />
  <div class="navigation">
   <dl>
     <dt>@{[$self->navhead()||'Links']}</dt>\n);

  for my $e ($self->sidebar_entries()) {
    $html_headers .= qq(    <dd>$e</dd>\n);
  }

  $html_headers .= q(</dl></div><br /></div><div id="content"><!-- begin main_content --><br /><img src="/gfx/wtlogo.png" alt="Wellcome Trust Logo" /><br />);

  return $html_headers;
}

sub site_footers {
  my $self    = shift;
  my $lastmod = q();
  my $req_uri = $ENV{'REQUEST_URI'} || q();

  if($ENV{'LAST_MODIFIED'}) {
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
	$lastmod = qq(Last Modified $scriptstamp);
      }
    }
  }

  return qq%<div id="footer">$lastmod</div></div><!--end main_content-->
<script type="text/javascript">
_userv=0;
urchinTracker();
</script>
</body></html>\n%;
}

1;
