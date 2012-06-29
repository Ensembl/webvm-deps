#########
# Author:        rmp
# Maintainer:    rmp
# Last Modified: $Date: 2007/03/01 09:12:10 $ $Author: rmp $
# Id:            $Id: BasicUser.pm,v 1.2 2007/03/01 09:12:10 rmp Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/Utilities/BasicUser.pm,v $
# $HeadURL$
#
package Website::Utilities::BasicUser;
use strict;
use warnings;
use Carp;

our $DEBUG   = 0;
our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

sub new {
  my ($class, $defs) = @_;
  my $self = {};
  bless $self, $class;

  for my $f ('util', $self->fields()) {
    if(defined $defs->{$f}) {
      $self->{$f} = $defs->{$f};
    }
  }
  return $self;
}

sub fields {
  return qw(username);
}

sub util {
  my $self = shift;
  if(!$self->{'util'}) {
    croak qq(No utility object available @{[caller]});
  }
  return $self->{'util'};
}

sub username {
  my ($self, $username) = @_;
  if(defined $username) {
    $self->{'username'} = $username;
  }
  return $self->{'username'};
}

1;
