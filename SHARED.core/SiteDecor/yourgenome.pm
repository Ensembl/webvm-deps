#########
# Author:        ab6
# Maintainer:    $Author: mw6 $
# Last Modified: $Date: 2010-01-21 14:08:07 $
# Id:            $Id: yourgenome.pm,v 6.16 2010-01-21 14:08:07 mw6 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/SiteDecor/yourgenome.pm,v $
# $HeadURL$
#
# decoration for (www|dev).yourgenome.org
#
package SiteDecor::yourgenome;
use strict;
use warnings;
use Sys::Hostname;
use base qw(SiteDecor);

our $VERSION = do { my @r = (q$Revision: 6.16 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

sub init_defaults {
  my $self = shift;
  my $def  = {
	      'redirect_delay' => 5,
	      'bannercase'     => 'ucfirst',
	      'author'         => 'webmaster',
	      'decor'          => 'full',
              'jsfile'         => ['http://js.sanger.ac.uk/urchin.js'],
	     };
  return $self->merge($def);
}

sub html_headers {
  my $self     = shift;
  my $title    = $self->title()       || 'YourGenome.org';
  my $jsfile   = $self->jsfile()      || [];
  my $desc     = $self->description() || qq(The YourGenome.org - http://www.yourgenome.org - website holds information on the public awareness of genome science produced by the Wellcome Trust Sanger Institute. The definitive source for information, news and discussion in the field of genome science, www.yourgenome.org answers questions like What is the Human Genome? Why research it? How can it be used? Who owns it?);
  my $keywords = $self->keywords()    || qq(wellcome trust sanger institute, genes, proteins, dna, rna, bioinformatics, human genome project);
  my $html_headers = qq(<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb">
  <head>
    <title>$title</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="author"  content="Genome Research Limited" />
    <meta name="version" content="$VERSION" />
    <meta name="description" content="$desc" />
    <meta name="keywords" content="$keywords" />
    <link rel="icon" href="/favicon.ico" type="image/x-icon" />
    <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
    <style type="text/css" media="all">
      \@import url(/css/yg.css);
    </style>
    <style type="text/css" media="print">
      \@import url(/css/printer-styles.css);
    </style>);

    if (@{$jsfile}) {
      $html_headers .= join "\n", map { qq(<script type="text/javascript" src="$_" ></script>\n) } @{$jsfile};
    }

  $html_headers .= qq(\n);

  return $html_headers;
}

sub site_footers {
  return qq(<\n);
}

1;
