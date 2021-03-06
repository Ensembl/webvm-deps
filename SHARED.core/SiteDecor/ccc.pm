#########
# Author:        rmp
# Maintainer:    mw6
# Last Modified: $Date: 2012-11-23 11:45:55 $ $Author: mw6 $
# Id:            $Id: ccc.pm,v 6.34 2012-11-23 11:45:55 mw6 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/SiteDecor/ccc.pm,v $
# $HeadURL$
#
# decoration for (www|dev).wtccc.org and ccc.sanger.ac.uk
#
package SiteDecor::ccc;
use strict;
use warnings;
# use SangerPaths qw(ccc);
use base qw(SiteDecor);
use Sys::Hostname;
# use ccc::AppKit::allowed_url;  # in testing: a bit faster

our $VERSION = do { my @r = (q$Revision: 6.34 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $JSFILES = {
                '/js/urchin.js'   => q(),
               };

sub init_defaults {
  my $self = shift;
  my $def  = {
              stylesheet     => ['/css/wtccc.css'],
              redirect_delay => 5,
              jsfile         => ['/js/menus.js'],
              bannercase     => 'ucfirst',
              author         => 'webmaster',
              decor          => 'full',
              onload         => 'mw6setformfocus()',
             };
  $self->merge($def);
}

sub html_headers {
  my $self   = shift;
  my $banner = $self->{'banner'} || q();
  my $title  = $self->{'title'}  || $banner || 'WTCCC: The Wellcome Trust Case Control Consortium';

  my ($hostname)   = (hostname()) =~ /^([^\.]+)/mx;
  my $heads = {
               'robots'       => $self->robots()      ?qq(    <meta name="robots" content="@{[$self->robots()]}" />\n):q(),
               'keywords'     => $self->keywords()    ?qq(    <meta name="keywords" content="@{[$self->keywords()]}" />\n):q(),
               'description'  => $self->description() ?qq(    <meta name="description" content="@{[$self->description()]}" />\n):q(),
               'script'       => $self->script()      ?qq(    <script type="text/javascript">@{[$self->script()]}</script>\n):q(),
               'style'        => $self->style()       ?qq(    <style type="text/css">@{[$self->style()]}</style>\n):q(),
               'metaredirect' => q(),
              };
  if($self->{'redirect'}) {
    my $redirect             = q();

    if($self->{'redirect'} ne q()) {
      $redirect              = qq(;url=$self->{'redirect'});
    }

    my $redirect_delay       = $self->{'redirect_delay'} || $self->{'redirect_delay'};
    ##no critic (Literal line breaks) 
    $heads->{'metaredirect'} = qq(
    <meta name="robots" content="noindex,follow" />
    <meta http-equiv="refresh" content="$redirect_delay$redirect" />\n);
    ##use critic (Literal line breaks)
  }
###
  #########
  # fix up stylesheets (+css), javascript
  #
  my @js;
  my $j    = $self->jsfile();
  my $dev  = $ENV{'dev'} || q();
  $dev = ($dev =~ m/test/ixm)?'dev':$dev;

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
      push @js, sprintf q(%s), $JSFILES->{$j}||$j;
    }
  }

  $self->jsfile(\@js);

  my $html_headers = $self->doc_type().qq(<html>
  <head>
    <title>$title</title>
$heads->{'robots'}$heads->{'keywords'}$heads->{'description'}$heads->{'metaredirect'}
@{[map {qq(    <link rel="stylesheet" type="text/css" href="$_" />\n); } @{$self->stylesheet()}]}
@{[map {qq(    <script type="text/javascript" src="$_" ></script>\n);  } @{$self->jsfile()}]}
  </head>
<body onload="$self->{'onload'}"><!-- host: $hostname-->);
  return $html_headers;
}

sub site_headers {
    my $self = shift;

return qq(<div class="pagehead">
  <div class="banner"><span class="wt">Wellcome Trust</span> Case Control Consortium</div>
  <div class="mbar">
    @{[join '', @{$self->_menu_items()}]}
  <div class="spacer">&nbsp;</div></div><!-- end mbar -->
</div><!-- end pagehead -->
<div id="main_content">\n);
# '<div id="wrapper">'.ccc::leftbar->new($self);
}

sub site_footers {
  my $self = shift;
  return qq(
  <script type="text/javascript">
    _userv=0;
    urchinTracker();
  </script>
  <div><a href="http://www.sanger.ac.uk/legal/cookiespolicy.html">Cookies Policy</a></div>
</div><!-- end main_content -->
</body>
</html>\n);
}

# To make all links https
sub process_link
{
my $old_link = shift;
if ( $old_link =~ m/^http:/ixm )
  {
  $old_link =~ s/^http:/https:/ixm ;
  }
elsif (0 == (index $old_link, q(/) ))
  {
  $old_link = 'https://' . $ENV{'HTTP_HOST'} . $old_link;
  }
return $old_link;
}

# _menu_items
#  now processes text as:
# '__' - display only if not logged in
#  '_' -              if user allowed url

sub _menu_items { # requires username
my $self = shift;
# my $user = $self->username();
my $url_cache;
# if ($user) { $url_cache = ccc::AppKit::Allowed_Url->new($user) };
my $navlist = $self->{'navlist'}; # was $self->{'handler'}{'navlist'}
#print "!",Dumper(\$navlist),"!<BR>",Dumper(\$self);

my %menu; my %popup; my $subject; my @subjects;
foreach ( qw(navigator navigator2 navigator3) ) {
  if ('ARRAY' eq ref $navlist->{$_}) {
    my (@content) = @{$navlist->{$_}};
    foreach (@content) {
      if ('HASH' eq ref $_ ) {
        my ($text, $link) = ($_->{'text'},$_->{'link'});
        my $display =0;
        # Only print when not logged in.
        if (0 == (index $text,'__'))
          {
          $text = substr $text,2;
          $display = 1;# if (not $user);
          }
        # Only print when logged in.
        elsif (0 == (index $text,'_'))
          {
#          $text = substr($text,1);
#          $display = 1 if ($user && $url_cache->allowed_url($link));
          }
        # Normal cases
        else
          {
          $display = 1;
          }
        if ($display)
          {
          $link = process_link($link);
          $popup{$subject} .= "    <a href='$link'>$text</a>\n";
          };
      }
    else {
      $subject = $_; # used later when we get a hash
#      my $legend = ($user && 'Registered access' eq $subject) ? qq( title="$user logged in") : q();
      my $legend = q();
      $menu{$_} = "  <div$legend>$_</div>\n";
      $popup{$_} = q();
      push @subjects,$_;
      }
    } # next content
  } # end if ARRAY
} # next navigator

#$popup{'Registered access'} .= ($user) ?
#                                   qq(    <a title="logout $user" href="/logout">Logout</a>\n)
#                                 : qq(    <a accesskey="l" href="/login.shtml">Login</a>\n);

my $i=0;
my @menu_items = ();
foreach (@subjects) {
  if ($popup{$_}) {
    push @menu_items,qq[<div class="menu" id="menu$i" onmouseover="mw6show($i)" onmouseout="mw6hide($i)">\n$menu{$_}];
    push @menu_items,qq[  <div class="popup" id="popup$i" onmouseover="mw6show($i)" onmouseout="mw6hide($i)">\n$popup{$_}  </div>\n</div>\n]; }
  else {
    push @menu_items,qq[<div class="menu">\n  $menu{$_}</div>\n];
    }
  $i++;
  }
return \@menu_items;
#  return join q(),@{$self->my_menu_items}; #empty string
}

sub stylesheet {
  my $self = shift;
  if (@_) {
    $self->{'stylesheet'} = [];
    foreach (@_)
      {
      if ('ARRAY' eq ref $_)
        {
        foreach (@{$_})
          {
          push @{$self->{'stylesheet'}}, $_
          }
        }
      else
        {
        push @{$self->{'stylesheet'}}, $_
        }
      }
  };
  return $self->{'stylesheet'};
}

sub jsfile {
  my $self = shift;
  if (@_) {
    my @flatten;
    foreach (@_)
      {
      if ('ARRAY' eq ref $_)
        { push @flatten, @{$_} }
      elsif ('_CLEAR' eq $_ )
        { $self->{'jsfile'} = [] }
      else
        { push @flatten, $_      }
      }

    my %defined = map { $_ => 1 } @{$self->{'jsfile'}};
    push @{$self->{'jsfile'}},grep { not $defined{$_} } @flatten;
    }
  return $self->{'jsfile'};
}

sub doc_type {
  return qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">\n);
}

1;
