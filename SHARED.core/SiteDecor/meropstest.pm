#########
# perl header & footer module designed for mod_perl use
# Author: rmp
# Maintainer: rmp
# Date: 2002-02-26
#

package SiteDecor::meropstest;
use strict;
use warnings;
use Carp;
use base qw(SiteDecor);
use Website::DBStore;
our $H_CACHE = {};
our $H_ID    = {};

sub init_defaults {
  my $self = shift;
  my $def  = {
	      author      => 'webmaster',
	      decor       => 'full',
	      bannercase  => 'ucfirst',
          title       => 'MEROPS - the Peptidase Database',
	      stylesheet  => ['/css/main.css'],
          body_class  => q(),
          jsfile      => ['http://js.sanger.ac.uk/urchin.js'],
	     };
  $self->merge($def);
  return;
}

sub fields {
  my $self = shift;
  my @fields = $self->SUPER::fields;
  push @fields, qw( lastmod body_class content_class );
  return @fields;
}

sub html_headers {
  my $self   = shift;
  my $html_headers = $self->SUPER::html_headers();

#############################################
# Determine $config_file
  if($self->ini_loaded()) {
    return;
  }
  my ($sidebar,$id) = $self->stuff();

  my $content = ($self->{content_class})?$self->{content_class}:'content';

  $html_headers .= qq(  <div class="sidebar"$id>
      $sidebar
  </div><!-- end sidebar -->
  <div class="$content">\n);

  return $html_headers;
}

sub stuff {
  my $self    = shift;

# key = $req_uri+$ENV{'DOCUMENT_ROOT'}+$inifile

  my $inifile = $self->{'inifile'};
  my $req_uri = $ENV{'REQUEST_URI'} || q(); # path to script
  if(!$inifile && $req_uri =~ /^\/(perl|cgi\-bin)/mx) {
    #  return;
  }

  my ($header,$header_direct,$header_global);
# my $header_file = 'default_sidebar.yml';

  if($inifile) {
    #########
    # determine full path to configured header files
    #
    my $tld;
    # Strip cgi-bin or perl:
    if($req_uri =~ m{/(cgi-bin|perl)/([^/]+)/}mx) {
      $tld = $2;
    } elsif($req_uri !~ /(cgi-bin|perl)/mx) {
      ($tld) = $req_uri =~ m{/([^/]+)/$}mx;                      # last part of path (?)
    }
    $tld           = $tld?"$tld/":q();                       # add a backslash

    ($header)      = $inifile =~ /([a-zA-Z0-9\/\_\-\.]+)/mx; # anything from inifile
    my $dr          = $ENV{'DOCUMENT_ROOT'} ||q();
    $header_direct  = qq($dr/$header);
    $header         = qq($dr/$tld$header);
    $header_global  = qq($dr/default_sidebar.yml);           # just look at root for default sidebar
  }
  else {
    #########
    # try to automatically determine header files
    #
    my ($directory) = $req_uri =~ /^(.+)\//mx;
    my ($tld)       = $req_uri =~ /^(.+?)\//mx;
    $directory    ||= q();
    $tld          ||= q();
    my $dr          = $ENV{'DOCUMENT_ROOT'} ||q();
    $header         = qq($dr$directory/sidebar.yml);
    $header_global  = qq($dr/default_sidebar.yml);
  }

  $header        =~ s{//}{/}mxg;


  my $sidebar    = q();
  my $sidebar_id = q();

  my $header_file = q();#/Users/mw6/webcvs/MEROPS_docs/htdocs/default_sidebar.yml);

  # Only use files that exist = a file op.
#  if ($header && -f $header) {
#    $header_file = $header;
#  }
#  elsif ($header_direct && -f $header_direct) {
#    $header_file = $header_direct;
#  }
#  elsif (-f $header_global) {
#    $header_file = $header_global;
#  }
  $header_file = $header || $header_direct || $header_global;
  unless (-f $header_file) {
    $header_file = $header_direct || $header_global;
    unless (-f $header_file) {
      $header_file = $header_global;
      unless (-f $header_file) {
        $header_file = q();
        $sidebar = q(You need a default_sidebar.yml);
        carp "Not found: $header_file";
        return ($sidebar,$sidebar_id);
        }
      }
    }

  # warn 'H='.$header_file;
  if ($H_CACHE->{$header_file}) {
    # warn "got from self";
    my $sidebar    = $H_CACHE->{$header_file}->{sidebar};
    my $sidebar_id = $H_CACHE->{$header_file}->{id};
    return ($sidebar,$sidebar_id);
  }

  #   if (!$self->{dbstore}) {
  #     $self->{dbstore} = Website::DBStore->new();
  #   }
  #  my $dbstore= $self->{dbstore};
  #   if ($sidebar = $dbstore->get($header_file)) {
  #     warn "got from database";
  #     $self->{sidebar}->{$header_file} = $sidebar;
  #   } else {

  eval {
    my $config = YAML::LoadFile($header_file);
    $sidebar = q();
    for my $entry (@{$config}) {
      if ($entry->{'html_sidebar_id'}) {
        $sidebar_id = q( id=').$entry->{'html_sidebar_id'}.q(');
      } else {
        $sidebar .= $self->create_menu($entry);
      }
    }
  };
  if ($@) {
    carp "Problems : $@";
    }

  # warn " $header_file / sidebar = ".length($sidebar);

  # warn "Saving..";
  # $dbstore->set($sidebar,$header_file,5); # 5 minutes
  $H_CACHE->{$header_file}->{sidebar} = $sidebar;
  $H_CACHE->{$header_file}->{id}         = $sidebar_id || q();
# warn "$sidebar_id | $header_file";

  $self->ini_loaded(1);
  return ($sidebar,$sidebar_id);
}

sub site_body_tag {
  my $self   = shift;
  my $onload = $self->onload() || q();
  my $class  = $self->body_class() || q{};
  $class     = $class?qq( class="$class"):q{};

  if(grep { m{/js/sidebar.js}mx } @{$self->jsfile()}) {
    $onload = "sidebar_default(); $onload;";
  }
	$onload  = $onload?qq( onload="$onload"):q();
  return sprintf q(  <body%s%s>), $class, $onload;
}

sub site_headers {
  my $self = shift;
  my $site_headers = q{};

  if(defined $self->{'banner'}) {
    my $banner = q();
    if($self->{'bannercase'} eq 'uc') {
      $banner = uc $self->{'banner'};
    } elsif($self->{'bannercase'} eq 'ucfirst') {
      $banner = ucfirst $self->{'banner'};
    } else {
      $banner = lc $self->{'banner'};
    }
    $site_headers .= $self->site_banner($banner);
  }

  return $site_headers;
}

sub site_banner {
  my ($self, $heading) = @_;

  return qq(<h1>$heading</h1>);
}

sub get_time {
  my ( $time ) = @_;
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = gmtime $time; #gmtime($time);
  my $month = qw (January February March April May June July August September October November December)[$mon];
     $year = $year + 1900;
  return sprintf '%2d-%s-%4d',$mday,$month,$year;
}

sub site_footers {
  my $self = shift;

  my $lastmod = q();
  my $req_uri = $ENV{'REQUEST_URI'} || q();

  if ($self->{lastmod}) {
    $lastmod = q(Page created ).($self->{'lastmod'}->{'text'} || (get_time($self->{'lastmod'}->{'time'})));
  }
  elsif($ENV{'LAST_MODIFIED'}) {
    $lastmod = qq(Last Modified $ENV{'LAST_MODIFIED'});
  }
  elsif($req_uri =~ m{/(cgi-bin|perl)/([^/]+)}mx) {
    eval {
      my ($conf_file) = ($ENV{'DOCUMENT_ROOT'}.'/../data/sitedefs.yml') =~ m{([a-z\d\./_]+)}mix;
      my $config = YAML::LoadFile($conf_file);
      my $date = $config->{merops_rel_date};
      if ($date) { $lastmod = 'Page created '.$date }
      };
  }

  if (not $lastmod) {
    #########
    # Look for the request_uri document
    #
    my ($fn) = "$ENV{'DOCUMENT_ROOT'}/$req_uri" =~ m{([a-z\d\./_]+)}mix;

    #########
    # If that doesn't exist try the script_filename
    #
    if($fn && !-e $fn) {
      ($fn) = $ENV{'SCRIPT_FILENAME'}||q() =~ m{([a-z\d\./_]+)}mix;
    }

    if($fn && -e $fn) {
      my ($mtime)     = (stat $fn)[9];
      if ($mtime) {
        $lastmod = 'Page created '. get_time($mtime);
      }
    }
  }


  return qq(
      <div class="footer">
        <p class="right"><a href='/cgi-bin/feedback'>feedback</a><br />$lastmod</p>
        <p class="left"><img src="/gfx/wtlogo.gif" alt="Wellcome Trust logo" /><br />Funding from the <a href="http://www.wellcome.ac.uk">Wellcome Trust</a></p>
        <p class="middle">&copy; 2011 WTSI<br /><a href="/about/availability.shtml">Terms of use</a></p>
      </div>
    </div><!-- end class content -->
    <script type="text/javascript">
      _userv=0;
      urchinTracker();
    </script>
  </body>
</html>\n);
}

sub create_menu {
  my ($self,$entry) = @_;
  my $output = q{};
  while ((my $key, my $value) = each %{$entry}) {
    if (ref $value eq 'HASH') {

      my $is_li = 0;
      my ($has_children_s,$has_children_e) = (q(),q());
      if ($value->{'class'} && $value->{'class'} ne 'title' && $value->{'class'} ne 'switch' && $value->{'class'} !~ /^bigtext/xm )
        {
        if ($is_li && $value->{'sub'} && @{$value->{'sub'}})
          {
          $has_children_s = '<ul>';
          $has_children_e = '</ul>';
          $is_li = 1;
          }
        }

      my $class = ($value->{'class'}) ? qq( class="$value->{'class'}"): q();
      my $title = ($value->{'title'}) ? qq( title="$value->{'title'}"): q();

      $output .= $is_li ? qq($has_children_s<li>):q();
      my $close_line = q();

      if ($value->{'link'})
        {
        $output .= qq(<a href="$value->{'link'}"$class$title>$key</a>);
        $close_line = qq(\n);
        }
      else
        {
        $output .= qq(<p$class>$key</p>);
        $close_line = qq(\n);
        }
      $close_line .= $is_li ? qq(</li>$has_children_e):q();
      if ($value->{'sub'} && @{$value->{'sub'}})
        {
        $output .= "\n<ul>\n";
        for my $sub (@{$value->{'sub'}}) {
          $output .= q(  ).list_items($self,$sub);
          }
        $output .= '</ul>';
        }
      $output .= $close_line."\n";
    }
    else {
      if ($value)
        {
        $output.= qq(<a href="$value">$key</a>\n);
        }
      else
        {
        $output.= $key."\n";
        }
    }
  }
  return $output;
}

sub list_items
{
  my ($self,$entry) = @_;
  my $output = q{};
  while ((my $key, my $value) = each %{$entry}) {
    if (ref $value eq 'HASH') {

      my $class = ($value->{'class'}) ? qq( class="$value->{'class'}"): q();
      my $title = ($value->{'title'}) ? qq( title="$value->{'title'}"): q();

      my $close_line = q();
      if ($value->{'link'})
        {
        $output .= qq(<li><a href="$value->{'link'}"$class$title>$key);
        $close_line = q(</a></li>);
        }
      else
        {
        $output .= "<li$class>".$key;
        $close_line = qq(</li>\n);
        }
      if ($value->{'sub'} && @{$value->{'sub'}})
        {
        $output .= "<ul>\n";
        for my $sub (@{$value->{'sub'}}) {
          $output .= q(  ).list_items($self,$sub);
          }
        $output .= '</ul>';
        }
      $output .= $close_line."\n";
    }
  }
  return $output;
}

sub doc_type {
  return qq^<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n^;
#  return qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n);
}

1;
