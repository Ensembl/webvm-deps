package SiteDecor::Menu::jimmac;
#########
# Author:        rmp
# Maintainer:    $Author: jc3 $
# Created:       2004
# Last Modified: $Date: 2008/11/11 12:09:05 $
#
use strict;
use warnings;
use base qw(SiteDecor::Menu);
our $VERSION  = do { my @r = (q$Revision: 6.1 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub leader {
  my $self    = shift;
  my $i       = 1;
  my $data    = $self->data();
  my $n       = scalar @{$data};
  return '' unless($n);
  my $top     = $self->settings->{'top'}          || 0;
  my $left    = $self->settings->{'left'}         || 0;
  my $width   = $self->settings->{'width'}        || 90;
  my $maccent = $self->settings->{'menubgaccent'} || "#aaaaaa";
  my $taccent = $self->settings->{'menuaccent'}   || "#000000";
  my $dev     = $self->is_dev()||"";

  my $subdomain = ($dev =~ /test/)?'test':"www$dev"; 

  my $source  = "http://$subdomain.sanger.ac.uk";
  my $leader  = qq(
<link rel="stylesheet" type="text/css" href="$source/css/menus/jimmac.css"/>
<script type="text/javascript" src="$source/js/menus/jimmac.js"></script>
<script type="text/javascript">\n);

  my $totwidth = 0;
  for (my $i=0; $i<scalar $n; $i++) {
    #########
    # left top width height
    # need to estimate height & width dynamically!
    #
    my $nitems    = scalar @{$data->[$i]};
    my ($heading) = $data->[$i]->[0] =~ />([^<]+)</;
    $leader      .= qq(new ypSlideOutMenu("menu@{[$i+1]}","down",@{[$left+$totwidth]},@{[$top+18]},$width,@{[$nitems*25]})\n);
    $totwidth    += $width;
  }
  $leader .= qq(</script>\n);

  return $leader;
}

sub menu {
  my $self      = shift;
  my $data      = $self->data();
  my $n         = scalar @{$data};
  return '' unless($n);
  my $top       = $self->settings->{'top'}       || 0;
  my $left      = $self->settings->{'left'}      || 0;
  my $bottom    = $self->settings->{'bottom'}    || 0;
  my $right     = $self->settings->{'right'}     || 0;
  my $width     = $self->settings->{'width'}     || 90;
  my $behaviour = $self->settings->{'behaviour'} || "onmouseover";
  my $content   = '';

  $content .= qq(
<div class="menubar" id="menubar">
  <div class="menutext">
    <table border="0" cellpadding="0" cellspacing="0" class="slickmenu">
      <tr>@{[map {
        my $menuid      = $_;
        my $onmouseout  = '';
        my $onmouseover = '';
	my $link        = $data->[$menuid-1]->[0] || '';
	$onmouseout     = qq(onmouseout="ypSlideOutMenu.hover_out('menu$menuid');ypSlideOutMenu.hideMenu('menu$menuid')");
        $onmouseover    = qq(onmouseover="ypSlideOutMenu.hover_in('menu$menuid')");

	if($behaviour eq "onclick") {
	  $link        =~ s/href=\"[^\"]+\"//i;
          $onmouseout  = qq(onmouseout="ypSlideOutMenu.hover_out('menu$menuid')");
	  $onmouseover = qq(onmouseover="ypSlideOutMenu.hover_in('menu$menuid');ypSlideOutMenu.toggleMenu('menu$menuid', 0)");
	}

        #########
        # switch the close tag for our menu behaviour
        #
	$link    =~ s|(/?)>| $behaviour="ypSlideOutMenu.toggleMenu('menu$menuid', 1);" $onmouseover $onmouseout$1>|;

        #########
        # switch the open tag for our element id
        #
	$link    =~ s|<a |<a id="amenu$menuid"|i;

	qq(    <td>$link</td>\n);
      } (1..$n)]}</tr>
      <tr>@{[map {
	qq(<td><img src="/gfx/blank.gif" height="1" width="${width}" alt="" /></td>\n);
      } (1..$n)]}</tr>
    </table>
  </div>
</div>
<div class="submenus" id="submenus">\n);

  my $id = 1;
  for my $menu (@{$data}) {
    my @copy = @{$menu};
    shift @copy;
    my $toggle = 0;
    $content  .= qq(<div id="menu${id}Container">
  <div id="menu${id}Content" style="position: relative; left: 0; filter:alpha(opacity=93); text-align: left;">
    <table cellpadding="0" cellspacing="0" border="0">\n@{[map {
      $toggle = !$toggle;
      qq(<tr class="@{[$toggle?"hi":"lo"]}"><td class="slickmenu">@{[$_||'']}</td></tr>\n);
    } @copy]}\n
    </table>
  </div>
</div>\n);

    $id++;
  }
  $content .= qq(</div>\n);
  return $content;
}

1;
