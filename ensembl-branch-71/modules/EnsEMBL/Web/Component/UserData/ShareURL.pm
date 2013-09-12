# $Id: ShareURL.pm,v 1.7 2012-07-09 08:53:38 ap5 Exp $

package EnsEMBL::Web::Component::UserData::ShareURL;

use strict;

use EnsEMBL::Web::Tools::Encryption qw(checksum);

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my @shares    = grep $_, $hub->param('share_id');
  my $share_ref = join ';', map { $_ =~ /^\d+$/ ? "share_ref=000000$_-" . checksum($_) : "share_ref=$_" } @shares;
  my $reload    = $hub->param('reload') ? '<div class="modal_reload"></div>' : '';
  my $url       = $hub->referer->{'absolute_url'};
     $url      .= $url =~ /\?/ ? ';' : '?' unless $url =~ /;$/;
     $url      .= $share_ref;
     
  return qq{
    <p class="space-below">To share this data, use the URL:</p>
    <p class="space-below">$url</p>
    <p class="space-below">Please note that this link will expire after 72 hours.</p>
    $reload
  };
}

1;
