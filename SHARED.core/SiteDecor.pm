#########
# Author:        rmp
# Maintainer:    team105-web
# Created:       2002-02-26
# Last Modified: $Date: 2012-03-28 10:44:53 $ $Author: mw6 $
# Id:            $Id: SiteDecor.pm,v 6.51 2012-03-28 10:44:53 mw6 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/SiteDecor.pm,v $
# $HeadURL$
#
# perl header & footer module designed for mod_perl use
#
package SiteDecor;
use strict;
use warnings;

#### use statements trimmed heavily for faster startup,
#    leaving enough to obtain the "SSO" login
#
#use Data::Dumper;
#use Config::IniFiles;
@Config::IniFiles::errors = ("(not loaded)"); # avoid interpolation warning in read_ini
#use SiteDecor::blast;
#use SiteDecor::genedb;
#use SiteDecor::intweb;
#use SiteDecor::intwebtest;
#use SiteDecor::merops;
use SiteDecor::plain;
#use SiteDecor::wtsi;
#use SiteDecor::yourgenome;
#use SiteDecor::Menu::jimmac;
#use SiteDecor::Menu::dreamweaver;
#use Website::portlet::getblast;
#use Website::portlet::bioresources;
#use Website::portlet::dbresources;
#use Website::portlet::news;
#use Website::portlet::calendar;
#use Website::portlet::special;
use Website::SSO::UserConfig;
use Website::SSO::Util;
use Website::Utilities::IdGenerator;
#use Website::DBStore;

use Sys::Hostname;
#use Storable qw(nfreeze thaw);
use CGI;
use base qw(Exporter);
use English qw(-no_match_vars);
use Carp;
use MIME::Base64;

our $AUTOLOAD;
our $VERSION        = do { my @r = (q$Revision: 6.51 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $SSO_COOKIE     = 'WTSISignOn';
our $SESSION_DEBUG  = 0;
our $SESSION_COOKIE = 'swsessionid';
our @EXPORT_OK      = qw($SSO_COOKIE);

#########
# List sites here which support the single-sign-on
# As the cookie is a domain cookie, there's no need to list more than one site with the same subdomain
#
our $SSO_SITES  = [qw(www.sanger.ac.uk www.wtgc.org www.treefam.org www.mitocheck.org www.acedb.org www.yourgenome.org www.eucomm.org intweb.sanger.ac.uk microrna.sanger.ac.uk)];

sub init_handler {
  my ($class, $refs) = @_;
  my $server_name    = $class->server_name();

  my $handlers       = {
			q(.*)                              => 'plain',     # default
			'acedb.org'                        => 'acedb',
			'.eucomm.org'                      => 'eucomm',
			'genedb.org'                       => 'genedb',
			'.hinxton.org'                     => 'hinxton',
			'intweb(dev)?.sanger.ac.uk'        => 'intweb',
      'intwebtest.sanger.ac.uk'          => 'intwebtest',
      'mw6-site1.sandbox.sanger.ac.uk'   => 'merops',
      'merops(test|.staging|.dev)?.sanger.ac.uk' => 'merops',
			'test.sanger.ac.uk'                => 'sangertest',
			'yourgenome.org'                   => 'yourgenome',
		       };

  for my $h (sort { length $b <=> length $a } keys %{$handlers}) {
    if($server_name =~ /$h/mx) {
      my $handlername = sprintf 'SiteDecor::%s', $handlers->{$h};

      my $handler;

      eval {
	$handler = $handlername->new($refs) or croak;
      };

      if($handler && !$EVAL_ERROR) {
	return $handler ;
      } else {
	carp "Could not load handler for $server_name: $EVAL_ERROR\n";
      }
    }
  }

  return SiteDecor::plain->new($refs);
}

sub fields {
  return qw(coreinifile inifile
            nph noHEAD decor
            redirect redirect_delay
            title description keywords robots jsfile script onload stylesheet css style cookie
            navigator navigator2 navigator3 navigator_header navhead heading swoosh
            navigator_align navigator2_align navigator3_align
            banner bannercase
            author headerimg headeralt
            navbar1 navbar2
            server_name
            rss atom ical portlets
            remote_addr phogolink
            drp cou cgi
            flash_var show_menu
            menu_implementation menus menusettings
            charset printlink
            searches);
}

sub new {
  my ($class, $refs) = @_;
  my $self           = {
			'_session'       => {}, # to store non-sso session data
			'_sessioncookie' => undef, # to store any sessionid cookie we create
		       };
  bless $self, $class;
  $self->{'cgi'} ||= CGI->new();

  #########
  # set up single sign on
  #
  my $cgi          = $self->{'cgi'};
  my $cookie       = $cgi?$cgi->cookie($SSO_COOKIE):q();

  if($cookie) {
    eval {
      my $decoded = Website::SSO::Util->decode_token($cookie);
      my ($username, $sesskey) = split /:/mx, $decoded, 2;

      if($username && $sesskey) {
	$self->{'username'} = $username;
	$self->{'sesskey'}  = $sesskey;
      }
    };
  }

  my $def = $self->init_defaults();
  $self->merge($def);     # defaults for this site style

  #########
  # need to pre-set inifile for this call
  #
  if($refs->{'inifile'}) {
    $self->{'inifile'} = $refs->{'inifile'};
  }

  $self->load();          # load from inifile
  $self->merge(\%ENV);    # load from SSI environment
  $self->merge($refs);    # load from method arguments
  $self->init($refs);     # Site style A.O.B.

  #########
  # fix ups for strings vs. arrays
  #
  if($self->portlets()) {
    if(!ref $self->portlets()) {
      $self->portlets([split /[\s,]+/mx, $self->portlets()||q()]);
    }
  }

  $self->init_env();

  return $self;
}

sub merge {
  my ($self, $src) = @_;

  if(!$src) {
    return;
  }

  for my $k ($self->fields()) {
    if(exists $src->{$k}) {
      $self->$k($src->{$k});
    }
  }
  return;
}

# keep init() virtual!
sub init          { return; };
sub init_defaults { return; };

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($func) = $AUTOLOAD =~ /^.*::(.*?)$/mx;

  if(scalar @args) {
    if(scalar @args > 1) {
      $self->{$func} = \@args

    } else {
      $self->{$func} = $args[0];
    }
  }

  return $self->{$func} || q();
}

#########
# ensure all usernames are returned lowercase
#
sub username {
  my ($self, $arg) = @_;

  if(scalar @_ > 1) {
    $self->{'username'} = $arg;
  }

  return lc($self->{'username'} || q());
}

sub init_env {
  my $self = shift;

  my @clientrealms = split /[,\s]+/mx, ($ENV{'HTTP_CLIENTREALM'}||q());
  for my $cr (grep { $_ ne 'null' } @clientrealms) {
    $ENV{$cr} = $cr;
  }
  return;
}

sub http_headers {
  my $self         = shift;
  my $http_headers = q();

  if($ENV{'SCRIPT_NAME'} =~ /nph\-/mx) {
    $self->{'nph'} = 1;
  }

  if(!($self->{'nph'} || defined $self->{'noHEAD'})) {
    my $cookie = $self->cookie();
    if($cookie) {
      if(ref $cookie eq 'ARRAY') {
        for my $c (@{$cookie}) {
	  if($c) {
	    $http_headers .= qq(Set-Cookie: $c\n);
	  }
	}
      } else {
        $http_headers .= qq(Set-Cookie: $cookie\n);
      }
    }

    #########
    # remember where this request was generated
    #
    my ($hostname) = (hostname()) =~ /^([^\.]+)/mx;

    my $route = q{};
    if ($hostname =~ /.*?-.*?-.*-?/){
      my @parts = split q(-), $hostname;
      for my $part (@parts) {
        if ($part =~ /^\d*$/){
          $route .= substr $part, 0, 2;
        }
        else {
          $route .= substr $part, 0, 1;
        }
      }
    }
    else {
      my $host = $hostname;
      $host =~ s/-//g;
      $route = substr($host,-4,4);
    }

    $cookie = $self->{'cgi'}->cookie(
					    '-name'    => 'backend',
					    '-value'   => "balancer.$route",
					    '-expires' => '+1h',
					   );
    $http_headers .= qq(Set-Cookie: $cookie\n);

    if($self->{'_sessioncookie'}) {
      $http_headers .= qq(Set-Cookie: $self->{'_sessioncookie'}\n);
    }

    # if logged in, need to not cache pages in the browser.
    if($self->username()) {
      $http_headers .= "Cache-Control: max-age=0, no-cache, no-store, must-revalidate\n";
      $http_headers .= "Pragma: no-cache\n";
      $http_headers .= "Expires: Wed, 11 Jan 1984 05:00:00 GMT\n";
    }

    my $charset    = $self->{'charset'}?"; charset=$self->{'charset'}":q();
    $http_headers .= "Content-type: text/html$charset\n\n";
  }




  return $http_headers;
}

sub html_headers {
  my $self         = shift;
  my $html_headers = q();
  my ($hostname)   = (hostname()) =~ /^([^\.]+)/mx;

  my $heads = {
	       'robots'       => $self->robots()      ?qq(    <meta name="robots" content="@{[$self->robots()]}" />\n):q(),
	       'keywords'     => $self->keywords()    ?qq(    <meta name="keywords" content="@{[$self->keywords()]}" />\n):q(),
	       'description'  => $self->description() ?qq(    <meta name="description" content="@{[$self->description()]}" />\n):q(),
	       'script'       => $self->script()      ?qq(    <script type="text/javascript">@{[$self->script()]}</script>\n):q(),
	       'style'        => $self->style()       ?qq(    <style type="text/css">@{[$self->style()]}</style>\n):q(),
	       'metaredirect' => q(),
	      };

  #########
  # sort out html headers
  #
  if($self->{'redirect'}) {
    my $redirect             = q();

    if($self->{'redirect'} ne q()) {
      $redirect              = qq(;url=$self->{'redirect'});
    }

    my $redirect_delay       = $self->{'redirect_delay'} || $self->{'redirect_delay'};
    $heads->{'metaredirect'} = qq(
    <meta name="robots" content="noindex,follow" />
    <meta http-equiv="refresh" content="$redirect_delay$redirect" />\n);
  }

  if(!($self->{'noHEAD'} ||
       ($self->{'decor'} &&
	$self->{'decor'} eq 'none'))) {

    my $title = $self->title();
    $title    =~ s/<.*?>//smgx;
    my $seen  = {};

    $html_headers .= $self->doc_type();
    $html_headers .= qq(<!-- version: $VERSION -->
<!-- host: $hostname -->
<html>
  <head>
    <title>$title</title>
$heads->{'robots'}$heads->{'keywords'}$heads->{'description'}$heads->{'metaredirect'}$heads->{'script'}$heads->{'style'}
@{[map { qq(<link rel="stylesheet" type="text/css" href="$_" />\n); } grep { !$seen->{$_}++ } (@{$self->css()}, @{$self->stylesheet()})]});

    for my $f (qw(rss atom)) {
      for my $a (@{$self->$f()}) {
	my $name = ref($a)?$a->[0]:'Latest News';
	my $feed = ref($a)?$a->[1]:$a;
	my $num  = 5;

	if($name =~ /^(.*?)\s(\d+)$/mx) {
	  $name  = $1;
          $num   = $2;
        }

	$html_headers .= qq(<link rel="alternate" type="application/$f+xml" title="$name" href="$feed" />\n);

	push @{$self->{'portlets'}}, {
				      'portlet' => 'news',
				      'name'    => $name,
				      'feed'    => $feed,
                                      'limit'   => $num,
				     };
      }
    }

    if(scalar @{$self->ical()||[]}) {
      push @{$self->{'portlets'}}, {
				    'portlet' => 'calendar',
				    'ical'    => $self->ical(),
				   };
    }

    my $protocol   = $self->protocol();
    my $zmenu      = 0;
    my $dev        = $self->is_dev();
    if ($dev =~ /test/) { $dev = 'dev' };


    $html_headers .= qq(@{[map {
      if($_ =~ /zmenu.js/mx) {
        $zmenu = 1;
        $_ = "$protocol://js$dev.sanger.ac.uk/zmenu.js";
      }
      qq(<script type="text/javascript" src="$_" ></script>\n);
    } @{$self->jsfile()}]});

    $html_headers .= ($self->menu() && $self->decor() eq 'full')?$self->menu->leader():q();
    $html_headers .= qq(  </head>\n);
    $html_headers .= $self->site_body_tag;

    if($zmenu) { # need to roll z-index into JSTools.pm
      $html_headers .= qq(<div id="jstooldiv" style="position:absolute;visability:hidden;z-index:1000;"></div>\n);
    }
  }
  return $html_headers;
}

sub site_body_tag {
  my $self   = shift;
  my $onload = $self->onload() || q();
  if(grep { m|/js/sidebar.js|mx } @{$self->jsfile()}) {
    $onload = "sidebar_default(); $onload;";
  }
	$onload  = $onload?qq( onload="$onload"):q(),
  return qq(  <body $onload>);
}


sub site_headers {
  return q();
}

sub site_footers {
  return qq(
  </body>
</html>\n);
}

sub begin_content { return q(); }
sub end_content   { return q(); }

#########
# draw a sanger header
#
sub header {
  my ($self, $refs) = @_;

  $self->merge($refs);              # settings per call (OO)

  return $self->http_headers() . $self->html_headers() . $self->site_headers() . $self->rlogin_data() . $self->begin_content();
}

sub footer {
  my $self         = shift;

  my $end_content  = $self->end_content() || q();
  my $site_footers = $self->site_footers() || q();
  if($self->decor() eq 'printable') {
    return $end_content . $site_footers;
  }
  my $site_menu    = $self->site_menu()   || q();
  my $menu_trailer = ($self->menu?$self->menu->trailer():q()) || q();
  return $end_content . $site_menu . $menu_trailer . $site_footers;
}

sub server_name {
  my $self = shift;

  if(!ref $self) {
    $self = {};
  }

  if(!$self->{'_server_name'}) {
    $self->{'_server_name'} = $ENV{'OVERRIDE_HOST'} || $ENV{'HTTP_X_FORWARDED_HOST'};
    if(!defined $self->{'_server_name'} || $self->{'_server_name'} eq q() || $self->{'_server_name'} eq 'unknown') {
      $self->{'_server_name'} = $ENV{'HTTP_X_HOST'};
      if(!defined $self->{'_server_name'} || $self->{'_server_name'} eq q() || $self->{'_server_name'} eq 'unknown') {
	$self->{'_server_name'} = $ENV{'SERVER_NAME'};
      }
    }
  }
  return $self->{'_server_name'}||q();
}

sub is_dev {
  my ($devtest) = ($ENV{'HTTP_X_FORWARDED_HOST'} || $ENV{'HTTP_HOST'} || q()) =~ /^[^\.]*?(dev|test)\./mx;
  $devtest    ||= q();
  return $devtest;
}

#########
# set up ini files
# short back and sidebars please
#
sub load {
  my $self    = shift;
  my $req_uri = $ENV{'REQUEST_URI'} || q();
  my $inifile = $self->{'inifile'};

  if($self->ini_loaded()) {
    return;
  }

  if(!$inifile && $req_uri =~ /^\/(perl|cgi\-bin)/mx) {
    return;
  }

  my ($header_global, $header);

  if($inifile) {
    #########
    # determine full path to configured header files
    #
    my ($tld)      = $inifile =~ /^$ENV{'DOCUMENT_ROOT'}\/(.+?)\//mx;
    $tld           = $tld?"$tld/":q();
    $header_global = "$ENV{'DOCUMENT_ROOT'}/${tld}header_global.ini";
    ($header)      = $inifile =~ /([a-zA-Z0-9\/\_\-\.]+)/mx;
    $header      ||= q();

  } else {
    #########
    # try to automatically determine header files
    #
    my ($directory) = $req_uri =~ /^(.+)\//mx;
    my ($tld)       = $req_uri =~ /^(.+?)\//mx;
    $directory    ||= q();
    $tld          ||= q();
    my $dr          = $ENV{'DOCUMENT_ROOT'} ||q();
    $header_global  = qq($dr$tld/header_global.ini);
    $header         = qq($dr$directory/header.ini);
  }

  $header_global =~ s|//|/|mxg;
  $header        =~ s|//|/|mxg;

  if(-f $header_global) {
    $self->read_ini($header_global);
    $self->ini_loaded(1);
  }

  if(-f $header) {
    $self->read_ini($header);
    $self->ini_loaded(1);
  }
  return;
}

#########
# fix up options which can take multiple entries
#
sub _multi_format_input {
  my ($self, $f, $in) = @_;
  my $mangled = [];
  my @processed;
  my @unprocessed = grep { defined } ($in, $self->{$f});

  while(my $arg = shift @unprocessed) {
    if(ref $arg eq 'ARRAY') {
      if(!scalar @{$arg}) {
	next;
      }
      unshift @unprocessed, grep { $_ } @{$arg};

    } elsif($arg =~ /,/mx) {
      unshift @unprocessed, grep { $_ } split /\s*,\s*/mx, $arg;

    } elsif($arg =~ /\s/mx) {
      #########
      # rather than using split here we can do something more useful, allowing:
      # atom=Version Tracker http://www.sanger.ac.uk/fetch/versiontracker/atom.xml
      # rather than
      # atom=VersionTracker http://www.sanger.ac.uk/fetch/versiontracker/atom.xml
      #
      my ($string, $uri) = $arg =~ /^(.*)\s+([^\s]+)$/mx;
      push @processed, [$string, $uri];

    } else {
      push @processed, $arg;
    }
  }

  my $seen = {};
  if(scalar @processed) {
    $self->{$f} = [grep { !$seen->{$_}++ } @processed];
  }

  return $self->{$f}||[];
}

sub rss        { my $self = shift; return $self->_multi_format_input('rss',        @_); }
sub atom       { my $self = shift; return $self->_multi_format_input('atom',       @_); }
sub jsfile     { my $self = shift; return $self->_multi_format_input('jsfile',     @_); }
sub ical       { my $self = shift; return $self->_multi_format_input('ical',       @_); }
sub stylesheet { my $self = shift; return $self->_multi_format_input('stylesheet', @_); }
sub css        { my $self = shift; return $self->_multi_format_input('css',        @_); }
sub searches   { my $self = shift; return $self->_multi_format_input('searches',   @_); }

sub config {
  my $self = shift;
  return $self->{'ini'};
}

sub read_ini {
  my ($self, $inifile) = @_;
  my $ini;

  $self->{'ini_cache'} ||= {};

  my $ci = $self->coreinifile();
  if($ci && !exists $self->{'ini_cache'}->{$ci} && -f $ci) {
    $self->{'ini_cache'}->{$ci} = Config::IniFiles->new(
							-file => $ci,
						       );
  }

  if(!exists $self->{'ini_cache'}->{$inifile}) {
    if(-f $inifile) {
      $self->{'ini_cache'}->{$inifile} = Config::IniFiles->new(
							       -file   => $inifile,
							       -import => ($ci && !$self->{'coreiniloaded'}++)?$self->{'ini_cache'}->{$ci}:undef,
							      );
    } else {
      carp qq(SiteDecor: $inifile does not exist);
    }
  }

  if(!exists $self->{'ini_cache'}->{$inifile}) {
    if(-f $inifile) {
      $self->{'ini_cache'}->{$inifile} = Config::IniFiles->new(
							       -file => $inifile,
							      );
    } else {
      carp qq(SiteDecor: $inifile does not exist);
    }
  }
  $ini = $self->{'ini_cache'}->{$inifile};

  if(!defined $ini) {
    carp qq(SiteDecor: failed to load ini file $inifile: @Config::IniFiles::errors);
    return;
  }

  #########
  # pull out globals
  #
  for my $g ($self->fields()) {
    if($g eq 'navigator'  ||
       $g eq 'navigator2' ||
       $g eq 'navigator3' ||
       $g eq 'stylesheet' ||
       $g eq 'jsfile'     ||
       $g eq 'css'        ||
       $g eq 'rss'        ||
       $g eq 'atom') {
      next;
    }

    if(defined $ini->val('general', $g)) {
      $self->$g(join q(), $ini->val('general', $g));
    }
  }

  #########
  # deal with multiples for jsfile & stylesheet
  #
  for my $g (qw(stylesheet jsfile css rss atom)) {
    if($ini->val('general', $g)) {
      push @{$self->{$g}}, $ini->val('general', $g);
    }
  }

  #########
  # configure menu data structures
  #
  $self->{'_menus'} ||= [];

  my $subs = {
	      'SSOSTATE' => $self->{'username'}?'Sign Out':'Sign In',
	      'SSOURL'   => $self->{'username'}?'/logout':'https://enigma.sanger.ac.uk/sso/login',
	     };


  for my $menu (split /[,\s]+/mx, $self->menus()) {
    if(!$ini->SectionExists($menu)) {
      next;
    }
    my $title   = $ini->val($menu, 'title') || $menu;
    my $link    = $ini->val($menu, 'link')  || q();
    my @items   = $link?qq(<a href="$link">$title</a>):$title;
    my @params  = grep { $_ ne 'title' && $_ ne 'link' } $ini->Parameters($menu);
    my $iconson = grep { $_ =~ /\s+/mx } map { $ini->val($menu, $_); } @params;

    push @items, map {
      my $val  = $_;
      my $link = $ini->val($menu, $val);
      my $env;

      #########
      # Decode the following:
      # Menu Text|localuser=/topsecretdata
      #
      if($val =~ /\|/mx) {
	($val, $env) = split /\|/mx, $val;
      }

      if($env && !$ENV{$env}) {
	undef;

      } else {

	#########
	# perform any substitutions required
	#
	$link =~ s/XXX_(.*?)_XXX/$subs->{$1}/smgx;
	$val  =~ s/XXX_(.*?)_XXX/$subs->{$1}/smgx;

	$link?qq(<a href="$link">$val</a>):$val;
      }
    } @params;

    push @{$self->{'_menus'}}, \@items;

  }

  for my $n (qw(navigator navigator2 navigator3)) {
    #########
    # set this up to close the sidebar table correctly
    #
    $self->{'navigator'} = 1;

    #########
    # start with a clean slate
    #
    if($ini->SectionExists($n)) {
      $self->{'navlist'}->{$n} = [];
    }

    #########
    # build the sidebar list
    #
    for my $p ($ini->Parameters($n)) {

      my $val = undef;

      if(substr($p, 0, 7) eq 'Include') {
	my $t = q() . $ini->val($n, $p);
	$t    =~ s/^\s+//sgmx;
	$t    =~ s/\s+$//sgmx;
	$val  = $t;

      } else {
	my $text = $p || q();
	my $link = $ini->val($n, $p) || q();

	if($text =~ /\|/mx) {
	  my ($envvar, $envok, $inverttest);
	  ($text, $envvar) = split /\|/mx, $text;

	  if(substr($envvar, 0, 1) eq q(!)) {
	    $envvar     = substr $envvar, 1, (length $envvar)-1;
	    $inverttest = 1;
	  }

	  if((!$inverttest && (exists $ENV{$envvar})) ||
	     ($inverttest && (!exists $ENV{$envvar}))) {
	    push @{$self->{'navlist'}->{$n}}, {
					       'text' => $text,
					       'link' => $link,
					      };
	    next;
	  }
	} else {
	  $val = {
		  'text' => $text,
		  'link' => $link,
		 };
	}
      }

      if(defined $val) {
	push @{$self->{'navlist'}->{$n}}, $val;
      }

      #########
      # remove from self so it doesn't get reprocessed
      #
#      delete($self->{$n});
    }
  }

  $self->{'ini'} = $ini;

  return;
}

sub site_menu {
  my $self = shift;
  return ($self->menu()?$self->menu->menu():q())||q();
}

sub site_banner {
  my ($self, $heading) = @_;
  return qq(<h1>$heading</h1>);
}

sub sidebar_entries {
  my ($self, $nav)  = @_;
  my @entries = ();

  if(!$nav) {
    for my $n (qw(navigator navigator1 navigator2 navigator3)) {
      push @entries, $self->sidebar_entries($n);
    }
    return @entries;
  }

  #########
  # navigatorX present but wasn't initialised so must be loaded from script or %ENV
  #
  if($self->{$nav} && $self->{$nav} ne '1') {
    $self->{'navlist'}->{$nav} = [];

    for my $line (split /,/mx, $self->{$nav}) {
      $line =~ s/^\s+//sigmx;

      my ($text, $link) = ($line,q());
      if($line =~ /\|\|/mx) {
        ($text, $link) = split /\|\|/mx, $line;

      } else {
	if($line =~ /;/mx) {
	  ($text, $link) = $line =~ /^(.*);(.*?)$/smx;
	}
      }

      if($text =~ /\|/mx) {
        my ($envvar, $envok, $inverttest);
        ($text, $envvar) = split /\|/mx, $text, 2;

        if((substr $envvar, 0, 1) eq q(!)) {
          $envvar     = substr $envvar, 1, (length $envvar)-1;
          $inverttest = 1;
        }

        if((!$inverttest && (exists $ENV{$envvar})) ||
	   ($inverttest && !(exists $ENV{$envvar}))) {
          push @{$self->{'navlist'}->{$nav}}, {
					       'text' => $text,
					       'link' => $link,
					      };
        }
      } else {
        push @{$self->{'navlist'}->{$nav}}, {
					     'text' => $text,
					     'link' => $link,
					    };
      }
    }
  }

  for my $item (@{$self->{'navlist'}->{$nav}}) {
    my ($text, $link) = (q(),q());

    if(ref $item eq 'HASH') {
      $text = $item->{'text'};
      $link = $item->{'link'};

    } else {
      $text = $item;
    }

    if(defined $link && $link ne q()) {
      $text = qq(<a class="sidebar" href="$link">$text</a>);
    }
    push @entries, $text;
  }

  return @entries;
}

sub menu {
  my ($self) = @_;
  my $impl   = $self->menu_implementation();

  if(!$impl) {
    return;
  }

  my $class  = "SiteDecor::Menu::$impl";
  $self->{'_menu'} ||= $class->new({
				    'data'     => $self->{'_menus'},
				    'settings' => $self->menusettings(),
				    'dev'      => $self->is_dev(),
				   });
  return $self->{'_menu'};
}

sub portlet_content {
  my $self    = shift;
  my $content = q();

  if(!ref $self->{'portlets'}) {
    $self->{'portlets'} = [split /[\s,]/mx, $self->{'portlets'}];
  }

  $content .= qq(<!--begin portlet prologue -->\n). (Website::portlet->prologue()||q()) . qq(<!--end portlet prologue -->\n);

  for my $p (@{$self->{'portlets'}}, 'special') {
    my $data = {};
    if(ref $p eq 'HASH') {
      $data = $p;
      $p    = $data->{'portlet'};
    }

    #########
    # copy useful bits of data into the config for each portlet
    #
    $data->{'username'}   = $self->{'username'}||q();
    $data->{'cgi'}        = $self->{'cgi'};

    if($self->{'username'}) {
      $data->{'userconfig'} = Website::SSO::UserConfig->new({
							     'username' => $self->{'username'}||q(),
							    });
    }

    if($p eq 'special') {
      $data->{'skip'} = [map { (ref $_ eq 'HASH')?$_->{'portlet'}:$_ } @{$self->{'portlets'}}];
    }

    $content .= qq(<!-- begin $p -->\n);
    my $pkg = "Website::portlet::$p";
    my $obj;
    eval "require $pkg";
    if($EVAL_ERROR) {
      carp $EVAL_ERROR;
      $content .= qq(  <!-- error loading -->\n);
      next;
    }
    eval {
      $obj = $pkg->new($data);
    };
    if($EVAL_ERROR) {
      carp $EVAL_ERROR;
      $content .= qq(  <!-- error initialising -->\n);
      next;
    }
    eval {
      $content .= ($obj->run()||q());
    };
    if($EVAL_ERROR) {
      carp $EVAL_ERROR;
      $content .= qq(  <!-- error executing -->\n);
    }

    $content .= qq(\n<!-- end $p -->\n);
  }
  return $content;
}

sub protocol {
  my $self = shift;
  return $ENV{'HTTP_X_FORWARDED_PROTOCOL'} || 'http';
}

sub rlogin_data {
  # This method now returns nothing as we dont want to use this
  # feature anymore. It is a potential security risk.
  return q( );
}

sub sessionid {
  my ($self, $id) = @_;
  #########
  # If an id wasn't specified then we need to either:
  # a) find it from the cgi cookie block
  # b) make one up
  #
  $id ||= $self->{'_sessionid'} ||
    ($self->{'cgi'}?$self->{'cgi'}->cookie($SESSION_COOKIE):undef) ||
      Website::Utilities::IdGenerator->get_unique_id();

  #########
  # detaint as this could later be used to pull stuff off disk
  #
  ($id) = $id =~ /([a-z0-9]+)/mix;

  #########
  # remember what id we've made up (best stored back in the cookie block)
  #
  if($self->{'cgi'}) {
      $self->{'_sessioncookie'} = $self->{'cgi'}->cookie(
							 '-name'    => $SESSION_COOKIE,
							 '-value'   => $id,
							 '-expires' => '+24h',
							 '-path'    => q(/),
							);
  }

  $self->{'_sessionid'} = $id;
  $SESSION_DEBUG and print {*STDERR} qq($self ::sessionid returning $id\n);
  return $id;
}

sub session {
  my ($self, $data) = @_;

  #########
  # find out the session id for this request (might be made up)
  #
  my $id = $self->sessionid();

  if($data) {
    #########
    # if data passed in, then save it *IN MEMORY*
    #
    $self->{'_session'} = $data;
    $SESSION_DEBUG and print {*STDERR} qq($self ::session: set data\n);

  } elsif(!$self->{'_session_loaded'}) {
    #########
    # Otherwise we're being expected to trawl it off disk
    #
    $self->load_session();
    $SESSION_DEBUG and print {*STDERR} qq($self ::session: load data\n);

  } else {
    $SESSION_DEBUG and print {*STDERR} qq($self ::session: returning existing data\n);
  }
  return exists($self->{'_session'})?$self->{'_session'}:{};
}

sub load_session {
  my $self = shift;
  my $id   = $self->sessionid() || 'broken';
  my $tmp  = $self->dbstore->get($id);

  if($tmp) {
    $self->{'_session'} = thaw($tmp);
  }

  $self->{'_session_loaded'}++;

  $SESSION_DEBUG and print {*STDERR} 'Load: '.Dumper($self->{'_session'});
  return;
}

sub has_session {
  my $self = shift;
  return exists $self->{'_session'};
}

sub save_session {
  my $self = shift;

  #########
  # Double-check: don't save if there's no data
  #
  if(!$self->{'_session'}) {
    return;
  }

  my $id  = $self->sessionid() || 'broken';
  my $tmp = nfreeze($self->{'_session'});

  if($tmp) {
    $self->dbstore->set($tmp, $id, 24);
  }

  $SESSION_DEBUG and print {*STDERR} 'Save: '.Dumper($self->{'_session'});
  return;
}

sub dbstore {
  my ($self, $dbstore) = @_;

  if($dbstore) {
    $self->{'dbstore'} = $dbstore;
  }

  $self->{'dbstore'} ||= Website::DBStore->new();
  return $self->{'dbstore'};
}

sub document_root {
  my ($docroot) = $ENV{'DOCUMENT_ROOT'} =~ m|([a-z0-9_/\-]+)|mix;
  return $docroot || q();
}

sub doc_type {
  return q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">);
}

sub DESTROY {
  my $self = shift;
  if(keys %{$self->{'_session'}} && !$self->{'_saved_session'}++) {
    $SESSION_DEBUG and carp "$self ::DESTROY: saving session";
    $self->save_session();
  }
  return;
}

1;

__END__

=head1 NAME

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 init_env - Initialise realm-based environment variables

  $sw->init_env();

  Called from SiteDecor::new() init_env uses the HTTP_CLIENTREALM
  environment variable which is based on a request header added by
  mod_headers on the front-end reverse proxy. This is used for
  determining from which (known) locations a remote client is
  connecting from. Commonly used for detecting whether a user is on
  site or not with the check if($ENV{'localuser'}) { ... }

=head2 dbstore - Get/set accessor for our Website::DBStore instance

  $oSW->dbstore(Website::DBStore->new());

  #########
  # Retrieve a previously set dbstore or create a new one
  #
  my $oDBStore = $oSW->dbstore();

=head2 is_dev - gives 'dev', 'test' or '' based on HTTP_X_FORWARDED_HOST or HTTP_HOST environment variables

  my $sLocation = $oSW->is_dev() || 'live';

  This used to be based on $ENV{'dev'} but people couldn't resist
  modifying its contents, which messes up mod_perl.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE AND COPYRIGHT

=cut
