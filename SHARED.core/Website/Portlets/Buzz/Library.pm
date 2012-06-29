#########
# Author: rmp@psyphi.net
#
package Website::Portlets::Buzz::Library;
use strict;
use Website::Portlets::Buzz::Base;
use Website::Portlets::Buzz::Feed;
use vars qw(@ISA);
@ISA = qw(Website::Portlets::Buzz::Base);

sub new {
  my ($class, @args) = @_;
  my $self = {};
  $self->{'dbh'} = $args[0]->{'dbh'} if(@args && $args[0]->{'dbh'});
  bless $self, $class;
  $self->init(@args);
  return $self;
}

sub feeds { print STDERR qq(feeds method unimplemented\n); }
1;
