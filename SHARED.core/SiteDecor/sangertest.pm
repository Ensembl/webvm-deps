#########
# Author:        jc3
# Created:       2006-11-08
# Maintainer:    $Author: nb5 $
# Last Modified: $Date: 2009-08-20 09:30:59 $
# Id:            $Id: sangertest.pm,v 1.39 2009-08-20 09:30:59 nb5 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/SiteDecor/sangertest.pm,v $
# $HeadURL$
#
package SiteDecor::sangertest;

use strict;
use warnings;

use SangerPaths qw(core); # for RSS-handlers
use base qw(SiteDecor);
use Sys::Hostname;
use HTML::Entities;
use CGI;

our $VERSION = do { my @r = (q$Revision: 1.39 $ =~ /\d+/gmx); sprintf '%d.'.'%03d' x $#r, @r };
our $JSFILES = {
		'jquery' => 'jquery-1.3.2.min..js',
	       };


sub init_defaults {
  my $self   = shift;
  my ($root) = $ENV{'DOCUMENT_ROOT'} =~ m|([a-z0-9_/\.]+)|mix;
  my $dev    = $ENV{'dev'} || q();

  #########
  # detaint $ENV{'dev'}
  #
  for my $dt (qw(dev test)) {
    if($dev =~ /$dt/mx) {
      $ENV{'dev'} = $dt;
    }
  }

  my $def    = {
		'charset'             => 'utf-8',
		'jsfile'              => ['/res/js/jquery.core.132.js','/res/js/thickbox.js','/res/js/cb.js',
					  '/res/js/quickmenu.js','/res/js/jquery.ui.172.js','/res/js/jquery.easing.1.3.js',
					  '/res/js/jquery.hrzAccordion.js','/res/js/jquery.hrzAccordion.examples.js',
					  '/res/js/jquery.tablesorter.200.js','/res/js/sanger-initialise.js'],
		'css'                 => ['/res/css/sanger-reset.css', '/res/css/sanger-layout.css', '/res/css/boxes.css', 
		                          '/res/css/sanger-formatting.css', '/res/css/jquery.ui.172.css', '/res/css/thickbox.css',
					  '/res/css/jquery.hrzAccordion.defaults.css', '/res/css/accordion.css'],
		'redirect_delay'      => 5,
		'author'              => 'webmaster',
		'title'               => 'Wellcome Trust Sanger Institute',
	       };
  return $def;
}

sub html_headers {
  my $self     = shift;
  my $title    = $self->title()       || 'Wellcome Trust Sanger Institute';
  my $cssfile  = $self->css()         || [];
  my $jsfile   = $self->jsfile()      || [];
  my $desc     = $self->description() || qq();
  my $keywords = $self->keywords()    || qq();
  my $html_headers = qq|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <title>$title</title>
|;

  for(@{$cssfile}) {
      $html_headers .= qq(<link rel="stylesheet" type="text/css" href="$_" media="screen"/>\n);
  }

  $html_headers .= qq(  
    <!--[if lt IE 7]>
      <link rel="stylesheet" type="text/css" href="/res/css/ie6.css"/>
    <![endif]-->
  );

  if (@{$jsfile}) {
    $html_headers .= join "\n", map { qq(<script type="text/javascript" src="$_"></script>) } @{$jsfile};
  }

  $html_headers .= qq|
</head>

<body>

|;
  return $html_headers;
}


sub site_headers {
  my $self = shift;
  my $dev        = $ENV{'dev'} || q();
  my $site_headers = qq(
  <!-- use id on body to control layouts ie landing, home, listing3col, listing4col, 2colLeft, 2colRight-->
    <div id="header">
      <div id="logo">
        <a href="x"><img src="/res/gfx/sanger_logo.gif" alt="Sanger logo" /></a>
        <h1>Wellcome Trust Sanger Institute</h1>
      </div><!-- /end logo -->
      <div id="search">
        <p class="searchLinks"><a href="/about/contact/contact.shtml">Contact us</a> <a href="/about/contact/find.shtml">Find us</a> <a href="#">Sitemap</a> <a href="#">Webmail</a></p>
        
          <form action="#" method="post">
            <input type="text" size="18" /> <input  type="submit" value="Search" />
          </form>
            
      </div><!-- /end search -->

    </div><!-- /End header -->
    
    <div id="navTabs">
      <ul id="navLeft">
        <li id="home"><a href="/">Home</a></li>
        <li id="research"><a href="/research/">Research</a></li>
        <li id="resources"><a href="/resources/">Scientific Resources</a></li>  
        <li id="careers"><a href="/careers/">Careers</a></li>
        <li id="about"><a href="/about/">About Us</a></li>
      </ul>
      
      <div id="navRight">
        <ul id="jsddm">
          <li ><a href="#"><img src="/res/gfx/rss_sm.gif" align="left" alt="RSS" />&nbsp;RSS feeds</a>
            <ul>
              <li><a href="#">RSS for this page</a></li>
              <li><a href="#">Directory of feeds</a></li>
            </ul>
          </li>
          <li ><a href="#">Quick links</a>
            <ul id="rss">
              <li><a href="#">Drop Down Menu here</a></li>
              <li><a href="#">jQuery Plugin</a></li>
              <li><a href="#">Ajax Navigation</a></li>
            </ul>
          </li>
        </ul>
      </div>
    </div><!-- end navTabs -->
    
    <div id="secondaryNavTabs">
      <!-- these change when the primary folder changes -->
      <ul id="secondaryTabs">
        <li id="overview"><a href="index.shtml">Overview</a></li>
      </ul>
    </div><!-- /end secondaryNavTabs --> 
    
    <!-- create rounded top rounded corners -->
    <div id="wrapTop">
      <div id="wrapTopLeft"></div>
      <div id="wrapTopRight"></div>
    </div>
    <!-- end rounded top rounded corners -->
    <!-- wrapper is the outer page canvas-->
    <div id="wrapper">
    
  <!-- content is the inner page canvas -->    
  <div id="content">
  );
  return $site_headers;
}

sub site_footers {
  my $self    = shift;
  my $lastmod = q();
  my $dev     = $ENV{'dev'}         || q();
  my $req_uri = $ENV{'REQUEST_URI'} || q();

  if($ENV{'LAST_MODIFIED'}) {
    $lastmod = qq(Last Modified $ENV{'LAST_MODIFIED'});

  }

  return qq(
</div><!-- /end content -->
  </div><!-- /end wrapper -->
    <!-- create rounded bottom rounded corners -->
    <div id="wrapBottom"><div id="wrapBottomLeft"></div><div id="wrapBottomRight"></div></div>
    <!-- end rounded bottom rounded corners -->
  <div id="footer">
    <div id="footerLeft"><p class="links"><a href="#">Feedback</a>   <a href="#">Copyright</a>   <a href="#">Conditions of use</a>   <a href="#">Terms &amp; Conditions</a></p>
    <p>Wellcome Trust Genome Campus, Hinxton, Cambridge, CB10 1SA, UK (<a href="#">map</a>)<br />
      Tel:+44 (0)1223 834244 <br />
      <a href="#">contact\@sanger.ac.uk</a>
    </p>
    <p>Registered charity number 210183</p>
    </div><!--/end footerLeft -->
    <div id="footerRight">
      <p id="lastModified">Last modified: 16th April 2009</p>
    </div><!--/end footerRight -->
  </div><!-- /end footer -->
  </body>
</html>
  );
}

sub doc_type {
  return qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n);
}

1;
