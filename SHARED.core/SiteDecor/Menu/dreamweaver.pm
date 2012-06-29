package SiteDecor::Menu::dreamweaver;
#########
# Author: rmp
# Maintainer: rmp
#
use strict;
use warnings;
use base qw(SiteDecor::Menu);

sub leader {
  my $self    = shift;
  my $i       = 1;
  my $data    = $self->data();
  my $n       = scalar @{$data};
  return "" unless($n);
  my $width   = $self->settings->{'width'}        || 90;
  my $maccent = $self->settings->{'menubgaccent'} || "#aaaaaa";
  my $taccent = $self->settings->{'menuaccent'}   || "#000000";
  my $menucol = $self->settings->{'menucolor'}    || "#ffffff";
  my $source  = $self->is_dev()?"http://wwwdev.sanger.ac.uk":"http://www.sanger.ac.uk";
  my $leader  = qq(
<link rel="stylesheet" type="text/css" href="$source/css/menus/dreamweaver.css">
<script language="javascript" src="$source/js/menus/dreamweaver.js"></script>
<script language="javascript">
  function mmLoadMenus() {
    if (window.mm_menu_1) return;\n);

  my $totwidth = 0;
  for (my $i=0; $i<scalar $n; $i++) {
    #########
    # left top width height
    # need to estimate height & width dynamically!
    #
    my @items     = @{$data->[$i]};
    my $nitems    = scalar @items;
    my $m         = $i+1;
    my ($heading) = $data->[$i]->[0] =~ />([^<]+)</;
    $leader      .= qq(window.mm_menu_$m = new Menu("root",111,15,"Verdana, Arial, Helvetica, sans-serif",11,"#ffffff","#ffffff","#004080","#996666","left","middle",2,0,1000,0,0,true,true,true,0,false,true)\n);

    shift @items;

    $leader .= qq(@{[map {
      my ($link, $text) = $_ =~ /href="([^\"]+)"[^>]*>(.*)</i;
      qq(mm_menu_$m.addMenuItem("$text","location='$link'")\n);
    } @items]});

    $leader .= qq(   mm_menu_$m.hideOnMouseOut=true; mm_menu_$m.bgColor='$menucol';\n);
		     
    $totwidth += $width+4;
  }
  $leader .= qq(mm_menu_1.writeMenus();\n}\n</script>\n);

  return $leader;
}

sub menu {
  my $self    = shift;
  my $data    = $self->data();
  my $n       = scalar @{$data};
  return "" unless($n);
  my $width   = $self->settings->{'width'}       || 90;
  my $barbg   = $self->settings->{'barbgcolor'}  || '#aaaaaa';
  my $menubg  = $self->settings->{'menubgcolor'} || '#cccccc';
  my $barcol  = $self->settings->{'barcolor'}    || '#000000';
  my $menucol = $self->settings->{'menucolor'}   || '#000000';
  my $stretch = $self->settings->{'stretch'}     || "yes";
  my $content = qq(<script language="JavaScript1.2">mmLoadMenus();</script>
<table style="background-color: $barbg;" align="center" border="0" cellpadding="0" cellspacing="0" width="700">
  <tr>@{[map {
    my $nitems     = (scalar @{$data->[$_-1]})-1;
    my $menuactive = $nitems?qq(onMouseOut="MM_startTimeout()" onMouseOver="MM_showMenu(window.mm_menu_$_,0,24,null,'anchor$_');"):"";
    my $link       = $data->[$_-1]->[0];
    $link          =~ s|<a |<a name="anchor$_" class="menuhead" style="color: $barcol;" $menuactive |i;

    qq(    <td style="width=@{[$width+4]}px; color: $barcol;">$link</td>\n);
  } (1..$n)]}</tr>
<tr>@{[map {
  qq(<td><img src="/gfx/blank.gif" height="1" width="${width}" alt="" /</td>\n);
} (1..$n)]}</tr>
   </table>\n);

  return $content;
}

1;
