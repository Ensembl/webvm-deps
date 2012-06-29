#########
# perl header & footer module designed for mod_perl use
# Author: rmp
# Maintainer: rmp
# Date: 2002-02-26
#

package SangerWeb;
use strict;
use warnings;
use SiteDecor;

our $VERSION = do { my @r = (q$Revision: 6.5 $ =~ /\d+/g); sprintf '%d.'.'%03d' x $#r, @r };
our $AUTOLOAD;

sub new {
  my ($class, $refs) = @_;
  my $self = {};
  bless $self, $class;
  $self->handler($refs);
  return $self;
}

sub handler {
  my ($self, $refs)    = @_;
  $self->{'handler'} ||= SiteDecor->init_handler($refs);

  return $self->{'handler'};
}

#########
# draw a sanger header
#
sub header {
  my ($self, $refs) = @_;

  if(substr(ref($self), 0, 9) ne 'SangerWeb') {
    return SangerWeb->new($self)->header();
  }

  return $self->handler->header($refs);
}

#########
# draw a sanger footer
#
sub footer {
  my ($self, $refs) = @_;

  if(substr(ref($self), 0, 9) ne 'SangerWeb') {
    return SangerWeb->new($self)->footer();
  }

  return $self->handler->footer($refs);
}

#########
# virtual header (useful for generating files offline
#
sub virtual_header {
  return qq(<!--#include virtual="/perl/header"-->\n);
}

#########
# virtual footer (useful for generating files offline
#
sub virtual_footer {
  return qq(<!--#include virtual="/perl/footer"-->\n);
}

#########
#virtual page content tabletop (useful for generating files offline)
#
sub virtual_tabletop {
  return qq(<!--#include virtual="/perl/tabletop"-->\n);
}

#########
#virtual page content tablebottom (useful for generating files offline)
#
sub virtual_tablebottom {
    return qq(<!--#include virtual="/perl/tablebottom"-->\n);
}

sub banner {
  return &heading(@_);
}

#########
# white on blue heading
#
sub heading {
  my ($self, $refs) = @_;

  if(substr(ref($self), 0, 9) ne 'SangerWeb') {
    return SangerWeb->new->banner($self);
  }

  $self->handler->{'banner'} = $refs if($refs);

  return $self->handler->site_banner($refs);
}

#########
# page content tabletop
#
sub tabletop {
  my $self = shift;
  my $refs = shift;
  $refs    = $self if(ref($self) eq 'HASH');
  $refs  ||= {};
#  $refs->{'align'} ||= 'left';

#  return qq(<table border="0" cellspacing="0" cellpadding="0" align="$refs->{'align'}" class="violet1">
  return qq(<fieldset>);
}

#########
# page content tablebottom
#
sub tablebottom {
    return qq(</fieldset>);
}

sub AUTOLOAD {
  my ($self, @args) = @_;
  my ($func)        = $AUTOLOAD =~ /^.*::(.*?)$/;
  return $self->handler->$func(@args);
}

sub devlive {
  my ($self, $str, $devlive) = @_;
  $devlive ||= '';

  if($devlive eq 'live') {
    $str =~ s!/WWW(dev|test|live)?/!/WWWlive/!smg;
  } elsif($devlive eq 'dev') {
    $str =~ s!/WWW(dev|test|live)?/!/WWWdev/!smg;
  } elsif($devlive eq 'test') {
    $str =~ s!/WWW(dev|test|live)?/!/WWWtest/!smg;
  }
  return $str;
}

sub document_root {
  my ($self, $devlive) = @_;
  my ($root)           = $ENV{'DOCUMENT_ROOT'} =~ m|([a-z0-9/\._\-]+)|i;
  return $self->devlive($root, $devlive);
}

sub server_root {
  my ($self, $devlive) = @_;
  my $root             = $self->document_root();
  substr($root, -1, 1) = '' if(substr($root, -1, 1) eq '/'); # strip trailing slash
  $root                =~ s|^(.*)/[^/]+|$1|; # strip trailing directory (usually htdocs)
  return $self->devlive($root, $devlive);
}

sub data_root {
  my ($self, $devlive) = @_;
  my $str              = $self->server_root() . '/data/';
  return $self->devlive($str, $devlive);
}

sub fs_root {
  return '/GPFS/data1';
#  my $self = shift;
#  my $sr   = $self->server_root(); # e.g. /GPFS/data1/WWW/INTWEB_docs
#  $sr      =~ s|([^/]+/){2}$||;
#  return $sr;
}

sub virtualhost {
  return $ENV{'HTTP_X_FORWARDED_HOST'} || $ENV{'HTTP_HOST'} || $ENV{'SERVER_NAME'} || '';
}

sub remoteaddr {
  return $ENV{'HTTP_X_FORWARDED_FOR'} || $ENV{'REMOTE_ADDR'};
}

sub protocol {
  return $ENV{'HTTP_X_FORWARDED_PROTOCOL'} || $ENV{'HTTP_PROTOCOL'} || 'http';
}

sub is_dev {
  return SiteDecor->is_dev();
}

1;

=pod

=head1 NAME

SangerWeb

=head1 VERSION

This document describes version $Revision: 6.5 $ released on $Date: 2007/09/12 14:26:48 $.

=head1 SYNOPSIS

use SangerWeb;

my $sw = SangerWeb->new({});

print $sw->header();

=head1 DESCRIPTION

SangerWeb provides a consistant interface for producing styled web pages. 

See also SiteDecor for additional methods.

=head1 METHODS

=over 4

=item new()

 Function: The object constructor.

 Args: Hash ref <optional>
       Key                      Value         

       author                   <string> The author of the page.
       title                    <string> The page <title/>.
       banner                   <string> visible title (<h1/>) element for the page.
       jsfile                   <arrayref> array of the paths to all the javascript files to be included in <head/>   
       inifile                  <string> Path to the inifile used for general site configuration.
       onload                   <string> javascript function to be called on page load. 
       stylesheet               <arrayref> paths to the stylesheets to be included in the <head/>.
       
 Returns: SangerWeb <object>

 Example: my $sw = SangerWeb->new({
                                   'author' => 'author_name',
                                   'title'  => 'page_title',
                                   'banner' => 'banner_text',
                                  });

=item header()

 Function: Generates the cgi header string followed by the html representing the top banner of the website.    

 Args: Hash reference. 

 Returns: header <string>

 Example: print $sw->header(\%refs);

=item footer()

 Function: Geenrates the html used to create the footer banner of the website. 

 Args: Hash reference

 Returns: footer <string>

 Example: print $sw->footer(\%args);

=item document_root()

 Function: Figures out the current path to the /htdocs directory and de-taints it.

 Args: none

 Returns: document_root <string>

 Example: my $doc_root = $sw->document_root();
 print $doc_root; # /GPFS/data1/WWW/SANGER_docs/htodcs

=item server_root()

 Function: Figures out the current path to the server_root and de-taints it.
 
 Args: none

 Returns: server_root <string>

 Example: my $server_root = $sw->server_root();
 print $server_root; # /GPFS/data1/WWW/SANGER_docs/

=item data_root()

 Function: Figures out the current path to the /data directory and de-taints it.

 Args: none

 Returns: data_root <string>

 Example: my $data_root = $sw->data_root();
 print $data_root; # /GPFS/data1/WWW/SANGER_docs/data/

=item cgi()

 Function: call this method to re-use the cgi object.

 Args: none

 Returns: CGI <object>

 Example: my $cgi = $sw->cgi();
 my @params = $cgi->param();

=back

=head1 DEPENDENCIES

=over 4

=item SiteDecor

=back

=head1 AUTHOR

Roger Pettett (rmp@sanger.ac.uk)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Wellcome Trust Sanger Institute. All rights reserved.
 
 This module is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself. See L<perlartistic>.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

=cut
