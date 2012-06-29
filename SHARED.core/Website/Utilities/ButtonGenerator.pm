#########
# Sanger/Ensembl-stylee GD Button Generator
# Author:        rmp
# Maintainer:    rmp
# Created:       2004-03-18
# Last Modified: 2005-08-26 (Added FONTPATH scan)
#
# Modularised from a script written long, long ago...
#
package Website::Utilities::ButtonGenerator;
use strict;
#use SangerPaths qw(ensembl);
use Sanger::Graphics::ColourMap;
use GD;
use vars qw($FONTPATH);
$FONTPATH = [qw(/usr/local/share/fonts/ttfonts
		/usr/share/fonts/monotype/TrueType)];

sub button {
  my ($self, $str, $opts) = @_;
  $opts     ||= {};
  my $cmap    = Sanger::Graphics::ColourMap->new();
  my $width   = $opts->{'width'}        || 100;
  my $height  = $opts->{'height'}       || 20;
  my $ptsize  = $opts->{'ptsize'}       || 10;
  my $font    = $opts->{'font'}         || "arial";
  my $bcol1   = $opts->{'bevelcolour'}  || 40;
  my $bcol2   = $bcol1*1.2;
  my $bdepth  = $opts->{'beveldepth'}   || 2;
  my $gd      = GD::Image->new($width, $height);

  if($opts->{'bgcolour'}) {
    if($opts->{'bgcolour'} =~ /^[0-9a-f]{6}$/i) {
      $cmap->add_hex($opts->{'bgcolour'});
    }
  }

  if($opts->{'fgcolour'}) {
    if($opts->{'fgcolour'} =~ /^[0-9a-f]{6}$/i) {
      $cmap->add_hex($opts->{'fgcolour'});
    }
  }

  if(substr($font, 0, 1) ne "/") {
    for my $dir (@{$FONTPATH}) {
      if(-f "$dir/$font") {
	$font = "$dir/$font";
	last;
      } elsif(-f "$dir/$font.ttf") {
	$font = "$dir/$font.ttf";
	last;
      }
    }
  }


  my $bghex    = $cmap->hex_by_name($opts->{'bgcolour'} || "rust");
  my $fghex    = $cmap->hex_by_name($opts->{'fgcolour'} || "white");

  my $highhex1 = [$cmap->tint_by_rgb([$cmap->rgb_by_hex($bghex)], $bcol1, $bcol1, $bcol1)];
  my $highhex2 = [$cmap->tint_by_rgb([$cmap->rgb_by_hex($bghex)], $bcol2, $bcol2, $bcol2)];
  my $lowhex1  = [$cmap->tint_by_rgb([$cmap->rgb_by_hex($bghex)], -$bcol1, -$bcol1, -$bcol1)];
  my $lowhex2  = [$cmap->tint_by_rgb([$cmap->rgb_by_hex($bghex)], -$bcol2, -$bcol2, -$bcol2)];

  my $bg       = $gd->colorAllocate($cmap->rgb_by_hex($bghex));
  my $fg       = $gd->colorAllocate($cmap->rgb_by_hex($fghex));
  my $high1    = $gd->colorAllocate(@{$highhex1});
  my $high2    = $gd->colorAllocate(@{$highhex2});
  my $low1     = $gd->colorAllocate(@{$lowhex1});
  my $low2     = $gd->colorAllocate(@{$lowhex2});

  #########
  # draw bevel
  #
  for (my $d=1; $d <= $bdepth; $d++) {
    $gd->line($d-1, $d-1, $width-$d, $d-1, $high2);          # top
    $gd->line($d-1, $d-1, $d-1, $height-$d, $high1);         # left
    $gd->line($d, $height-$d, $width-$d, $height-$d, $low2); # bottom
    $gd->line($width-$d, $d, $width-$d, $height-$d, $low1);  # right
  }

  #########
  # draw text
  # initially draw one off the screen so we can pick up the boundaries
  #
  my @bounds = $gd->stringFT($fg, $font, $ptsize, 0, 0, -100, $str);

  my $x1 = $bounds[6];
  my $y1 = $bounds[7];
  my $x2 = $bounds[2];
  my $y2 = $bounds[3];

  if(!defined $x1 || !defined $x2 || !defined $y1 || !defined $y2) {
    print STDERR qq(Looks like TTF support is broken here\n);
    $gd->string(gdSmallFont, ($width/2)-(length($str)*2), ($height/2)-6, $str, $fg);

  } else {
    my $x  = ($width  - ($x2 - $x1))/2;
    my $y  = ($height + $ptsize)/2;
    
    $gd->stringFT($fg, $font, $ptsize, 0, $x, $y, $str);
  }

  if($opts->{'fn'}) {
    my $fout;
    open($fout, ">$opts->{'fn'}") or die "could not open $opts->{'fn'}";
    binmode $fout;
    print $fout $gd->png();
    close $fout;

  } else {
    print $gd->png();
  }
}

1;
