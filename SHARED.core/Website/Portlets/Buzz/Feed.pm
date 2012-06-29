#########
# Author: rmp@psyphi.net
#
package Website::Portlets::Buzz::Feed;
use strict;
use base qw(Website::Portlets::Buzz::Base);
use XML::FeedLite::Normalised;
use IO::Scalar;
use Data::Dumper;

our $HTTP_PROXY = "http://webcache.sanger.ac.uk:3128/";

sub new {
  my ($class, $ref) = @_;
  my $self = {};

  if($ref && ref($ref) eq "HASH") {
    for my $f (qw(feed dbh)) {
      $self->{$f} = $ref->{$f} if(defined $ref->{$f});
    }
  } elsif($ref && !ref($ref)) {
    $self->{'feed'} = $ref;
  }
  $self->{'fmt'} = "";
  bless $self, $class;
  $self->init();
  return $self;
}

sub dbcache {
  eval "require DBI";
  return $@?0:1;
}

sub feed {
  my ($self, $ref) = @_;
  $self->{'feed'}  = $ref if($ref);
  $self->{'feed'}  =~ s/([^\s]+)/$1/;
  return $self->{'feed'};
}

sub xfl {
  my $self = shift;
  my $feed = $self->feed();
  $self->{'xfl'} ||= XML::FeedLite::Normalised->new({
						     'timeout'    => 5,
						     'url'        => $feed,
						     'http_proxy' => $HTTP_PROXY,
						    });
  return $self->{'xfl'};
}

sub fetch {
  my ($self)     = @_;
  return if($self->{'_fetched'});
  my $feed       = $self->feed() || "";
  my @errors     = ();

  my $data       = $self->xfl->entries();
  my $status     = $self->xfl->statuscodes->{$feed}||"";

  if($status !~ /^[23]/) {
    push @errors, qq(HTTP Response: $status);
  }

  $self->{'_fetched'} = 1;
}

sub title {
  my $self  = shift;

  return $self->xfl->title($self->feed())||"";
}

sub stories {
  my ($self, $num) = @_;

  my @stories = @{$self->xfl->entries->{$self->feed()}};

  if($num) {
    @stories = @stories[0..($num-1)];
  }
  return map { $_->{'link'} = $_->{'link'}->[0]; $_; }
  grep { ref($_) eq "HASH" && $_->{'title'} } @stories;
}

1;
