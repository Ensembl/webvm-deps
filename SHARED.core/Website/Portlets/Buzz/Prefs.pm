#########
# Author: rmp@psyphi.net
#
package Website::Portlets::Buzz::Prefs;
use strict;
use Website::Portlets::Buzz::Feed;
use Website::Portlets::Buzz::Base;
use vars qw(@ISA);
@ISA = qw(Website::Portlets::Buzz::Base);

sub new {
  my ($class, $refs) = @_;
  my $self = {};
  bless $self, $class;

  for my $f ($self->fields()) {
    $self->{$f} = $refs->{$f} if($refs->{$f});
  }

  $self->init($refs);
  return $self;
}

sub fields {}

sub feeds {
  my ($self, $ref) = @_;

  return map { Website::Portlets::Buzz::Feed->new({
						   'feed' => $_,
						   'dbh'  => $self->{'dbh'},
						  }); } $self->_feeds($ref);
}

1;
