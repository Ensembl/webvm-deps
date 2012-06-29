package SiteDecor::Menu;
#########
# Author: rmp
# Maintainer: rmp
#
# Menu base class
#
use strict;
use warnings;

sub new {
  my ($class, $ref) = @_;
  my $self = {};
  $ref   ||= {};
  for my $f (qw(data settings dev)) {
    $self->{$f} = $ref->{$f} if($ref->{$f});
  }
  bless $self, $class;
  return $self;
}

sub data {
  my $self = shift;
  return $self->{'data'} || [];
}

sub settings {
  my $self = shift;
  return $self->{'settings'} || {};
}

sub is_dev {
  my $self = shift;
  return $self->{'dev'} || 0;
}

sub leader {
}

sub trailer {
}

1;
