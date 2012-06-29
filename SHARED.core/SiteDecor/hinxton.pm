#########
# Author:        nb5
# Created:       2006-11-08
# Maintainer:    $Author: nb5 $
# Last Modified: $Date: 2010-06-29 12:18:54 $
# Id:            $Id: hinxton.pm,v 1.110 2010-06-29 12:18:54 nb5 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/SiteDecor/hinxton.pm,v $
# $HeadURL$
#
package SiteDecor::hinxton;

use strict;
use warnings;

use SangerPaths qw(core hinxton);
use base qw(SiteDecor);
use Sys::Hostname;
use HTML::Entities;
use CGI;

our $VERSION = do { my @r = (q$Revision: 1.110 $ =~ /\d+/gmx); sprintf '%d.'.'%03d' x $#r, @r };

sub init_defaults {
  my $self   = shift;
  my $dev    = $ENV{'dev'} || q();
  my $def    = {
		'charset'             => 'utf-8',
		'jsfile'              => ['/js/validateForm.js', 
		                          '/js/calendar.js',
					  '/js/search.js',
					  '/js/events_output.js',
					  '/js/events_globals.js',
					  "http://js$dev.sanger.ac.uk/urchin.js", 
					  "http://js$dev.sanger.ac.uk/jquery-1.4.2.min.js"],
		'css'                 => '/css/hinxton.css',
		'redirect_delay'      => 5,
		'bannercase'          => 'ucfirst',
		'author'              => 'webmaster',
		'title'               => 'hinxton.org'
	       };

  return $def;
}

sub html_headers {
  my $self     = shift;
  my $title    = $self->title()       || 'Hinxton.org';
  my $jsfile   = $self->jsfile()      || [];
  my $desc     = $self->description() || qq();
  my $keywords = $self->keywords()    || qq();
  my $html_headers = 
    qq|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
  <title>$title</title>
  <link rel="alternate" type="application/atom+xml" title="Hinxton RSS feed" href="/cgi-bin/rss" />
  <link rel="stylesheet" type="text/css" href="/css/hinxton.css" />
  |;
  $html_headers .= fix_js($jsfile);
  $html_headers .= qq| 
</head>
<body>|;
  return $html_headers;
}

sub fix_js { # make sure all the js files are sourced in the right order!
  my $jsa      = shift;
  my @js       = @{$jsa};
  my $html     = '';
  my @jssanger = ();
  
  for ( reverse @js ) {
    $html .= qq|<script language="javascript" src="$_"></script>\n|;
  }
  return $html;
}

sub site_headers {
  my $self     = shift;
  my $dev      = $ENV{'dev'} || q();
  my $title    = $self->title()       || 'Hinxton.org';
  my $jsfile   = $self->jsfile()      || [];
  my $desc     = $self->description() || qq();
  my $keywords = $self->keywords()    || qq();
my $site_headers = qq|
  <div id="page">
  
  <div id="header">
    <div id="header-top">
      <div id="header-top-text-title"><b>Hinxton</b>.org</div>
      <div id="header-top-text-lower">Courses and Conferences</div>
    </div>
    <div id="header-bottom-left">
      <img src="/gfx/masthead_1_really_small.jpg" class="img1"><img src="/gfx/masthead_2_really_small.jpg" class="img2"><img src="/gfx/wtgc_pan_72.jpg" class="img3">
    </div>
    <div id="header-bottom-right">
      <div id="header-bottom-text">A directory of scientific events at the<br />Wellcome Trust Genome Campus</div>
    </div>
    <div id="navbar">
      <a href="/index.shtml">Home</a>
      <a href="/faq.shtml">FAQ</a>
      <a href="/testimonials.shtml">Testimonials</a>
      <a href="/contact.shtml">Contact</a>
      <a href="/gallery.shtml">Gallery</a>
    </div>
  </div>
  
  <div id="sidebar">
    <h6>Organisers' Colour Key</h6>
    <table class="sidebar-box-colour-key">
      <tr class="colour-key-content">
       <td><img src="/gfx/circle.png" /></td><td style="color: #202174" class="key-item" id="category-1">WT Advanced Courses</td>
      </tr>
      <tr class="colour-key-content">
       <td><img src="/gfx/rhombus.png" /></td><td style="color: #666fbe" class="key-item" id="category-2">WT Scientific Conferences</td>
      </tr>
      <tr class="colour-key-content">
       <td><img src="/gfx/square.png" /></td><td style="color: #0b62a9" class="key-item" id="category-3">Sanger Events</td>
      </tr>
      <tr class="colour-key-content">
       <td><img src="/gfx/triangle.png" /></td><td style="color: #007281" class="key-item" id="category-4">EMBL-EBI Events</td>
      </tr>
      <tr class="colour-key-content">
       <td><img src="/gfx/pentagon.png" /></td><td style="color: #1187ec" class="key-item" id="category-5">Campus Seminars</td>
      </tr>
      <tr><td colspan='2' style="padding: 5px; text-align: center">Click on the organisers' names to view all their events</td></tr>
    </table>
  
    <br/ >
  
    <h6>Search events</h6>
    <div class="sidebar-box">
      <p>
        <label for="category">Search category</label><br>
        <select name="category">
          <option value="all">all</option>
  	  <option value="39">Courses</option>
  	  <option value="40">Conferences</option>
          <option value="41">Workshops</option>
	  <option value="42">Seminars</option>
	  <option value="archive">Archive</option>
        </select>
  
        <br />
        <br />
  
        <label for="expression">For</label><br />
        <input type="text" size="16" name="expression"><br />
  
        <br />
  
        <img src="/gfx/search_btn.png" border="0" class="key-item" id="search">
        <br />
        <br />
        <br />
        <img src="/gfx/show_all_btn.png" border="0" class="key-item" id="all">
        <br />
        <br />
        <a rel="alternate" type="application/atom+xml" href="/cgi-bin/rss"><img src="/gfx/rss_btn.png" /></a>
      </p>
    </div>
  
    <br />
    <div class="sidebar-box">
      <div id="evtcal">
        <div id="calendar"><!-- dynamically filled --></div>
      </div>
    </div>
  </div>\n|;

  return $site_headers;
}

sub site_footers {
  return qq(<div id="footer">
<a href="http://www.ebi.ac.uk"><img src="/gfx/embl-ebi-logo-white_bgk.png"></a>
<a href="http://www.wellcome.ac.uk"><img src="/gfx/wt-logo-white_bgk.png"></a>
<a href="http://www.sanger.ac.uk"><img src="/gfx/wtsi-logo-white_bgk.png"></a>
<br />
<a href="http://www.sanger.ac.uk/feedback">feedback</a> | <a href="/copyright.shtml">copyright</a>
</div>
<script type="text/javascript">
  _userv=0;
  urchinTracker();
</script>
</div>
</body>
</html>
);
}

1;
