#########
# perl header & footer module designed for mod_perl use
# Author: rmp
# Maintainer: rmp
# Date: 2002-02-26
#

package SiteDecor::efamily;
use strict;
use warnings;
use base qw(SiteDecor);

sub init_defaults {
  my $self = shift;
  my $def  = {
	      "stylesheet"     => "http://www.efamily.org.uk/css/efamily.css",
	      "redirect_delay" => 5,
	      "bannercase"     => 'ucfirst',
	      "author"         => 'webmaster',
	      "decor"          => 'full',
	     };
  if($self->is_dev()) {
    $def->{'stylesheet'} =~ s/www/dev/;
  }
  return $def;
}

#sub html_headers {
#  my $self = shift;
#  my $html_headers = qq(
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
#<html>
#  <head>
#    <title>$self->{'title'}</title>
#    <meta name="description" content="Hosted by The Wellcome Trust Sanger Institute">
#    <meta name="keywords" content="Mitocheck,Phosphorylation,cell cycle,Wellcome Trust,Sanger Institute,Sanger Centre,
#Human Genome Project,Information,human,genetics,uk,sequencing,analysis,genomes,worm,ensembl,genome browser,cancer,micr
#oarrays,functional genomics,bioinformatics,Ensembl,annotation">
#    <link rel="stylesheet" type="text/css" href="$self->{'stylesheet'}">
#  </head>
#  <body>\n);
#  return $html_headers;
#}

sub site_headers {
  my $self = shift;
  #In this header we open both the main and content div, but do not close them as this is done by the footer
  #The aim of this set up is to allow slightly more felxibility in the pages which is controlled by the style sheet, 
  #rather than the header/footer sections.

  #first lets do the very top of the page
  my $site_headers = qq( 
      <div id="imgheader">
      <a href="http://www.efamily.org.uk"><img alt="eFamily" src="/gfx/efamily-medium-sml.png"></a>
      </div>

      <div id="content">
        <div id="nav">
        <ul>\n);

  for my $e ($self->sidebar_entries()) {
    $site_headers .= qq(<li id="menu1">$e</li>\n);
  }
  $site_headers .= qq(
	</ul>
	</div>\n);
   
  if(defined $self->{'title'}) {
    my $banner = "<div id=header>";
    if($self->{'bannercase'} eq "uc") {
      $banner = uc($self->{'title'});
    } elsif($self->{'bannercase'} eq "ucfirst") {
      $banner = ucfirst($self->{'title'});
    } else {
      $banner = lc($self->{'title'});
    }
    $site_headers .= $self->site_banner($banner)."</div>";
  }


  $site_headers .= qq(<div id="main">);
  return $site_headers;
}


sub site_banner {
  my ($self, $heading) = @_;
  $heading =~ s/efamily/eFamily/ismg;
  return qq(<h2>$heading</h2>\n);
}


sub site_footers {
  my $self = shift;

  #The footer closes the main div and the content div

  my $site_footer =  qq(</div><div id="footer">
			<a href="http://www.mrc.ac.uk/"><img alt="MRC" src="/gfx/mrc.gif"></a>
			<a href="http://www.sanger.ac.uk/"><img alt="WTSI" src="/gfx/wtsi_new.gif"></a>
			</div>
			</div>
			</body>
                        </html>\n);
  return $site_footer;
}

1;
