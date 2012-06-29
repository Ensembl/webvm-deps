#########
# Author: rmp
# Created: 2006-05-04 
# Last Modified: $Date: 2008/04/30 09:22:34 $
# Maintainer: $Author: jc3 $
# $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/portlet/news.pm,v $ - $Id: news.pm,v 1.3 2008/04/30 09:22:34 jc3 Exp $

package Website::portlet::news;
use strict;
use warnings;
use base qw(Website::portlet);
use Website::Portlets::Buzz::Feed;

sub fields { qw(name feed limit); }

sub run {
  my $self  = shift;
  my $atom  = $self->{'feed'};
  my $limit = $self->{'limit'} || 5;

  return unless($atom);
  my @a;

  if(ref($atom)) {
    push @a, @{$atom};
  } else {
    push @a, $atom;
  }

  my $content = '';
  if(@a) {
    my $host = $ENV{'HTTP_X_FORWARDED_HOST'}||'';
    for my $url (map { (substr($_, 0, 1) eq "/")?"http://$host/$_":$_; } @a) {
      my $feed    = Website::Portlets::Buzz::Feed->new({
							'feed' => $url,
						       });
      my @stories = ();
      next;
      eval {
	@stories = $feed->stories($limit);
      };
      warn $@ if($@);
      next unless (scalar @stories);
      $content .= qq(<div class="portlet"><div class="portlethead">$self->{'name'}</div><div class="portletitem"><ul>@{[map {qq(<li><a href="$_->{'link'}">$_->{'title'}</a></li>\n) } @stories]}</ul></div></div>);
    }
  }
  return $content;
}

1;
