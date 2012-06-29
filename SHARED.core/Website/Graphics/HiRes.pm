# Author: jc3
# Created: 2007-03-28
# Maintainer: $Author: jc3 $
# Last Modified: $Date: 2007/07/02 13:11:48 $
# $Revision: 1.10 $ - $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/Graphics/HiRes.pm,v $

package Website::Graphics::HiRes;
# [H]igh Resolution [I]mage [RES]ource

use strict;
use warnings;
use Template;

our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $DEBUG = 0;

sub new {
  my ($class,$args) = @_;
  my $self = {
              'zoom_start' => '1',
              'width'      => '750', 
              'height'     => '550', 
             };
  bless $self, $class;
  $self->_load($args);
  return $self;
}

sub _load {
  my ($self,$args) = @_;
  for my $k (qw(zoom_start width height model)){
    $self->$k($args->{$k}) if defined $args->{$k};
  }
  return;
}

sub model {
  my ($self,$model) = @_;
  $self->{'model'} = $model if defined $model;
  return $self->{'model'};
}

sub zoom_start {
  my ($self,$zs) = @_;
  $self->{'zoom_start'} = $zs if defined $zs;
  return $self->{'zoom_start'};

}

sub width {
  my ($self,$w) = @_;
  $self->{'width'} = $w if defined $w;
  return $self->{'width'};

}

sub height {
  my ($self,$h) = @_;
  $self->{'height'} = $h if defined $h;
  return $self->{'height'};
}

sub render {
  my ($self) = @_;
  my $output = q{};
  my $tt = Template->new;
  $tt->process(\*DATA,{'image'   => $self->model,
                       'display' => $self },\$output) or die $tt->error();
  return $output;
}

1;

__DATA__
<div id="[% image.hash %]" style="width:[% display.width %]px;height:[% display.height %]px;"></div>

<script type="text/javascript">
  function create_map () {
    if (GBrowserIsCompatible()) {
      var map = new GMap2(document.getElementById("[% image.hash %]"));

      var copyCollection = new GCopyrightCollection("Image");
      var copyright = new GCopyright(1, new GLatLngBounds(new GLatLng(-90, -180),
                                    new GLatLng(90, 180)), 0,
                                    "&copy; [% image.copyright %]");
      copyCollection.addCopyright(copyright);

      var tilelayers = [new GTileLayer(copyCollection,[% image.zoom_minimum %], [% image.zoom_maximum %])];
      tilelayers[0].getTileUrl = CustomGetTileUrl;

      var projection = new EuclideanProjection(18);

      var custommap = new GMapType(tilelayers, projection,
                               "Image", {errorMessage:""});
      map.addMapType(custommap);
      map.addControl(new GLargeMapControl());
      /* map.addControl(new GOverviewMapControl()); */

      var center = projection.fromPixelToLatLng(new GPoint([% image.pixel_width %] / 2,[% image.pixel_height %] / 2),[% image.zoom_maximum %]);
      
      map.setCenter(center,[% display.zoom_start %], custommap);
      map.enableDoubleClickZoom();
      map.enableContinuousZoom();
      map.enableScrollWheelZoom();
    }
  }

  function CustomGetTileUrl(a,b) {
    var z = b;
    var f = "/imaging/[% image.hashdir %]/" + z + "/"+ a.x + "x" + a.y + ".png";
    return f;
  }

  function EuclideanProjection(a){
    this.pixelsPerLonDegree=[];
    this.pixelsPerLonRadian=[];
    this.pixelOrigo=[];
    this.tileBounds=[];
    var b=256;
    var c=1;
    for(var d=0;d<a;d++){
      var e=b/2;
      this.pixelsPerLonDegree.push(b/360);
      this.pixelsPerLonRadian.push(b/(2*Math.PI));
      this.pixelOrigo.push(new GPoint(e,e));
      this.tileBounds.push(c);
      b*=2;
      c*=2;
    }
  }

  EuclideanProjection.prototype=new GProjection();

  EuclideanProjection.prototype.fromLatLngToPixel=function(a,b){
    var c=Math.round(this.pixelOrigo[b].x+a.lng()*this.pixelsPerLonDegree[b]);
    var d=Math.round(this.pixelOrigo[b].y+(-2*a.lat())*this.pixelsPerLonDegree[b]);
    return new GPoint(c,d);
  };

  EuclideanProjection.prototype.fromPixelToLatLng=function(a,b,c){
    var d=(a.x-this.pixelOrigo[b].x)/this.pixelsPerLonDegree[b];
    var e=-0.5*(a.y-this.pixelOrigo[b].y)/this.pixelsPerLonDegree[b];
    return new GLatLng(e,d,c);
  };

  EuclideanProjection.prototype.tileCheckRange=function(a,b,c){
    var tileBounds = Math.pow(2,b);
    if (a.y<0 || a.y >= tileBounds) {return false;}
    if (a.x<0 || a.x >= tileBounds) {return false;}
    return true; 
  }
 
  EuclideanProjection.prototype.getWrapWidth=function(zoom) {
    return this.tileBounds[zoom]*256;
  }

</script>
