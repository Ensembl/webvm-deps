#########
# Author: rmp
# Created: ????-??-??
# Last Modified: $Date: 2008/01/18 13:05:03 $
# Maintainer: $Author: jc3 $
# $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/portlet/miniad.pm,v $ - $Id: miniad.pm,v 1.2 2008/01/18 13:05:03 jc3 Exp $
package Website::portlet::miniad;
use strict;
use warnings;
use base qw(Website::portlet);
our $ADURI = "/miniads/sidebar";
our $DEBUG = 0;

sub run {
  my $self     = shift;
  my ($adroot) = (($ENV{'DOCUMENT_ROOT'}||'').$ADURI) =~ m|([a-z0-9_/\.]+)|i;
  my @files;

  eval {
    my $dh;
    opendir($dh, $adroot)    or die "opening $adroot: $!";
    @files = grep {
      /\.s?html?$/
    } readdir($dh);
    closedir($dh)            or die "closing $adroot: $!";
  };
  $DEBUG && warn $@ if($@);

  return '' unless(@files);

  my $pick   = $files[int(rand(scalar @files))];
  ($pick)    = $pick =~ /([a-z0-9\.]+)/;

  my $miniad = '';
  eval {
    my $fh;
    open($fh, "$adroot/$pick") or die "opening $adroot/$pick";
    local $/ = undef;
    $miniad  = <$fh>;
    close($fh)                 or die "closing $adroot/$pick";
  };
  warn $@ if($@);

  $miniad or return '';

  return qq(<div class="portlet">
  <div class="portlethead">Featured Link</div>
  <div class="portletitem">
$miniad
  </div>
</div>\n);
}

1;
