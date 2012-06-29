#########
# Author:        jc3
# Created:       2006-11-08
# Maintainer:    $Author: nb5 $
# Last Modified: $Date: 2009-03-12 10:29:04 $
# Id:            $Id: microrna.pm,v 1.2 2009-03-12 10:29:04 nb5 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/SiteDecor/microrna.pm,v $
# $HeadURL$
#
package SiteDecor::microrna;

use strict;
use warnings;

use SangerPaths qw(intweb); # for RSS-handlers
use base qw(SiteDecor);
use Sys::Hostname;
use HTML::Entities;
use CGI;

our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/gmx); sprintf '%d.'.'%03d' x $#r, @r };
our $JSFILES = {
		'zebra.js'         => q(),
		'sidebar.js'       => q(),
		'toggle.js'        => q(),
		'prototype'        => 'prototype.js',
		'scriptaculous' => 'scriptaculous/scriptaculous.js',
	       };


sub init_defaults {
  my $self   = shift;
  my ($root) = $ENV{'DOCUMENT_ROOT'} =~ m|([a-z0-9_/\.]+)|mix;
  my $dev    = $ENV{'dev'} || q();
  my $query_string = HTML::Entities::encode($ENV{'QUERY_STRING'}) || q();

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
		'swoosh'              => 'default.gif',
		'jsfile'              => [],
		'portlets'            => [],
		'css'                 => (sprintf q(%s/css/wtsi.css?2007), $self->statichost()),
		'coreinifile'         => "$root/core.ini",
		'redirect_delay'      => 5,
		'bannercase'          => 'ucfirst',
		'author'              => 'webmaster',
		'decor'               => 'full',
		'printlink'           => sprintf('?%s;decor=printable', $query_string||q()),
		'menu_implementation' => 'jimmac',
		'menusettings'        => {
					  'top'          => 66,
					  'left'         => 173,
					  'bottom'       => 600,
					  'right'        => 900,
					  'width'        => 100,
					  'behaviour'    => 'onclick',
					 },
	       };

  if(($ENV{'QUERY_STRING'}||$ENV{'REQUEST_URI'}||q()) =~ /decor=printable/mx) {
    $def->{'decor'} = 'printable';
  }

  return $def;
}

sub html_headers {
  my $self = shift;

  #########
  # fix up stylesheets (+css), javascript
  #
  my (@st, @js);
  my $s    = $self->stylesheet();
  my $c    = $self->css();
  my $j    = $self->jsfile();
  my $dev  = $ENV{'dev'} || q();
  $dev = ($dev =~ /test/)?'dev':$dev;

  if($c) {
    if(ref $c) {
      push @st, @{$c};
    } else {
      push @st, $c;
    }
  }

  if($s) {
    if(ref $s) {
      push @st, @{$s};
    } else {
      push @st, $s;
    }
  }

  if($j) {
    if(ref $j) {
      push @js, @{$j};
    } else {
      push @js, $j;
    }
  }

  my $protocol = $self->protocol();
  for my $j (sort keys %{$JSFILES}) { # sorted specifically to make prototype appear before scriptaculous!
    if(!grep { /$j/mx } @js) {
      push @js, sprintf q(%s://js%s.sanger.ac.uk/%s), $protocol, $dev, $JSFILES->{$j}||$j;
    }
  }

  $self->stylesheet(\@st);
  $self->jsfile(\@js);
  return $self->SUPER::html_headers();
}

sub statichost {
  my $self = shift;
  my $dev  = $ENV{'dev'} || q();
  return sprintf q(%s://%s%s.sanger.ac.uk),
                 $self->protocol(),
		 ($self->protocol() eq 'http')?'www':'enigma',
		 $dev;
}

sub site_headers {
  my $self = shift;

  if($self->decor() eq 'printable') {
    return $self->site_banner();
  }

  my $dev        = $ENV{'dev'} || q();
  my $statichost = $self->statichost();
  my ($navhead, $navtxt, $heading);

  if($self->navhead()) {
    ($navhead, $navtxt) = split /[\s,]+/mx, $self->navhead(), 2;
    $navhead ||= q();
    $navtxt  ||= q();
    $navhead   = sprintf q(<img class="img" src="%s/gfx/navigator/%s" title="%s" alt="%s" height="40" width="170" />),
                 $statichost,
		 $navhead,
		 $navtxt,
		 $navtxt;
  }

  $navhead ||= q();
  $heading   = $self->heading()?$self->heading():q();

  my $ssokey       = $self->{'username'}?'/logout':"https://enigma$dev.sanger.ac.uk/sso/login";
  my $site_home    = ($self->server_name() =~ /search/mx)?"http://www$dev.sanger.ac.uk/":q(/);
  my $printlink    = $self->printlink() || q();
  my $icons        = $self->{'username'}?'logout.gif':'key.gif';
  my $login_title  = $self->{'username'}?'Log out':'Login to WTSI resources';
  my $loginjs      = $self->{'username'}?q():q(id="loginLink");
  my $site_headers = qq(
    <div id="collapseHEAD" style="background:url($statichost/header-icons/swoosh/@{[$self->swoosh()]}) no-repeat top left;" >
      <a href="/"><img src="/gfx/blank.gif" width="200" height="60" alt="" /></a>
      <!--search box start here-->
      <div id="searchbox">
        <form action="http://search$dev.sanger.ac.uk/cgi-bin/exasearch" name="sitesearch">
          <input type="text"   name="_q" value="" size="12" maxlength="100" id="q" class="sitequery" />
          <input type="hidden" name="_l" value="en" />
          <input type="hidden" name="_options" value="0" />
          <input type="submit" value="Search" name="search" class="searchbutton"/>
        </form>
      </div><!--search box end-->
    </div> <!-- end of collapseHEAD div -->
     <div id="nav_bar">
      <a href="http://www$dev.sanger.ac.uk/feedback/"><img src="/icons/navigation/email.gif" alt="Contact WTSI Webmaster" title="Contact WTSI Webmaster" /></a>
      <a href="$printlink"><img src="/icons/navigation/printer.gif" alt="Printer friendly format" title="Printer friendly format" /></a>
      <a href="$ssokey" $loginjs><img src="/icons/navigation/$icons" alt="$login_title" title="$login_title" /></a>
      <a href="http://www$dev.sanger.ac.uk/shared/news-report/atom/20020211150255"><img src="/icons/navigation/rss.gif" alt="WTSI RSS feed" title="WTSI RSS feed" /></a>
    </div>);

  my $nav_entries = {
		     '1' => [$self->sidebar_entries('navigator')],
		     '2' => [$self->sidebar_entries('navigator2')],
		    };
  push @{$nav_entries->{'1'}}, $self->sidebar_entries('navigator1'); # just in case

  my $is_hidden = $self->{'cgi'}?$self->{'cgi'}->cookie('hidden'):0;

  if(@{$nav_entries->{'1'}} || @{$nav_entries->{'2'}} || $self->heading()) {

    #########
    # Only add a navigator3 if there's existing sidebar content
    #
    $nav_entries->{'3'} = [
			   qq(<a href="http://search$dev.sanger.ac.uk/">Website Search</a>),
			   qq(<a href="http://www$dev.sanger.ac.uk/Teams/name.shtml">People Search</a>),
			   qq(<a href="http://library$dev.sanger.ac.uk/">Library Services</a>),
			   qq(<a href="http://www$dev.sanger.ac.uk/sitemap/">Site Map</a>),
			   qq(<a href="http://www$dev.sanger.ac.uk/feedback/">Feedback / Help</a>),
			  ];


    my $protocol = 'http';
    if ($ENV{'SERVER_PROTOCOL'} && $ENV{'SERVER_PROTOCOL'} !~ /INCLUDED/mx) {
      ($protocol) = $ENV{'SERVER_PROTOCOL'} =~ m|(.*)/|mx;
      $protocol   = lc $protocol;
    }

    my $uri = HTML::Entities::encode($ENV{'REQUEST_URI'}) || q();
    
    $site_headers .= qq(
      <div id="navblock" @{[$is_hidden?qq(class="collapsed"):qq(class="expanded")]}>
        <div id="sidebar" @{[$is_hidden?qq(class="collapsed"):qq(class="expanded")]} style="@{[$is_hidden?qq(display:none):qq(display:block)]}" >
          <div id="navigation">
            <div id="login_box" style="display:none">
              <form autocomplete="off" name="ssologin" action="https://enigma$dev.sanger.ac.uk/LOGIN" method="post" >
                <input type="hidden" name="destination" value="$protocol://$ENV{'SERVER_NAME'}$uri" />
                <label for="credential_0">Username:</label> 
                <input type="text" name="credential_0" maxlength="128" class="field"/>
                <label for="credential_1">Password:</label> 
                <input type="password" name="credential_1" maxlength="20" class="field"/>
                <input type="submit" value="Login" />
              </form>
            </div>
           <div id="navhead">
             $navhead
             $heading
           </div>\n);

    for my $which (qw(1 2 3)) {
      my @nav = @{$nav_entries->{$which}};
      if(@nav) {
	my $class = ($which == 2)?'2':q();
	$site_headers .= qq(
          <div class="navigator$class">
            <ul>@{[map { qq(<li>$_</li>\n) } @nav]}</ul>
          </div>\n);
      }
    }

    #########
    # work out top level directory
    # for adding tld-specific content like the sidebar tab images
    #
    my $tld = q();
    my $req = $self->{'inifile'} || $ENV{'REQUEST_URI'};
    $req    =~ s/$ENV{'DOCUMENT_ROOT'}//mx;

    if($req =~ m!/(cgi-bin|perl)/([^/]+)/!mx) {
      $tld = $2;

    } elsif($req !~ /(cgi-bin|perl)/mx) {
      ($tld) = $req =~ m|/([^/]+)/|mx;
    }
    $tld = lc $tld;

    $site_headers .= qq(
    </div><!-- end navigation -->
<!--begin portlets-->
  <div id="portlets">
  @{[$self->portlet_content()]}
  </div>
<!--end portlets-->
  </div><!-- end sidebar -->
  <div id="navtab" @{[$is_hidden?qq(class="collapsed"):qq(class="expanded")]}>
     <script type="text/javascript">
        var sidebar_images     = new Array(2);
        sidebar_images['hide'] = "$statichost/gfx/hide_nav.png";
        sidebar_images['show'] = "$statichost/gfx/show_nav.png";
        var sidebar_string     = "<a href='javascript:toggle()'><img src='"+sidebar_images['@{[$is_hidden?'show':'hide']}']+"' alt='' title='@{[$is_hidden?'Show':'Hide']} the side bar' id='nav_tab'><\\/a>";
        document.write(sidebar_string);
      </script>
    </div>
  </div><!--end navblock-->);

  }

  $site_headers .= qq(     <!--start main-->\n);

  #########
  # need to add check here to see if navigator is present. if not hide navtab and expand main
  #
  if(@{$nav_entries->{'1'}} || @{$nav_entries->{'2'}} || $self->heading()) {
      $site_headers .= qq(       <div id="main" @{[$is_hidden?qq(class="expanded"):qq(class="collapsed")]}>);
   } else {
     $site_headers .= q( <div id="main" class="expanded" >);
   }

   $site_headers .= qq(   <div id="collapseBANNER">\n);

  if(defined $self->{'banner'}) {
    my $banner = q();
    if($self->{'bannercase'} eq 'uc') {
      $banner = uc $self->{'banner'};

    } elsif($self->{'bannercase'} eq 'ucfirst') {
      $banner = ucfirst $self->{'banner'};

    } elsif($self->{'bannercase'} eq 'none') {
      $banner = $self->{'banner'};

    } else {
      $banner = lc $self->{'banner'};
    }
    $site_headers .= $self->site_banner($banner);
  }
  return $site_headers;
}

sub begin_content {
  return qq(</div> <!-- end of collapseBANNER div -->
<div id="content">\n);
}

sub end_content {
  return q(</div><!-- end content -->);
}

sub site_footers {
  my $self    = shift;
  my $lastmod = q();
  my $dev     = $ENV{'dev'}         || q();
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
	$lastmod      = qq(Last Modified $scriptstamp);
      }
    }
  }

  return qq(
    <div id="collapseFOOT">
      <div id="contact">
        <p id="email"><a href="http://www$dev.sanger.ac.uk/feedback/">webmaster\@sanger.ac.uk</a></p>
        <p>Wellcome Trust Genome Campus, Hinxton, Cambridge, CB10 1SA, UK&nbsp;&nbsp;Tel:+44 (0)1223 834244</p>
      </div>
      <div id="legal">
        <p class="right">$lastmod</p>
        <p class="left">Registered charity number 210183</p>
        <p class="middle">@{[($self->decor() eq "printable")?q():qq(<a href="http://www$dev.sanger.ac.uk/notices/release-policy.shtml">Data Release Policy</a> | <a href="http://www$dev.sanger.ac.uk/notices/use-policy.shtml">Conditions of Use</a> | <a href="http://www$dev.sanger.ac.uk/notices/copyright.shtml">Copyright</a>)]}</p>
      </div>
    </div> <!-- end of collapseFOOT div -->
    </div><!-- end main -->
  </body>
</html>\n);
}

sub site_banner {
  my ($self, $heading) = @_;
  return qq(<div class="banner">$heading</div>\n);
}

sub doc_type {
  return qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n);
}

1;
