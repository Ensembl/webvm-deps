package Website::Utilities::IdGenerator;
#########
# Author: rmp
# Maintainer: $Author: jc3 $
# Created: a long time ago
# Last Modified: $Date: 2008/11/04 16:57:33 $ 
# Useful for generating fairly unique ids
#
use strict;
use warnings;
use Sys::Hostname;
use Time::HiRes qw/gettimeofday/;
use Digest::SHA qw(sha256_base64);

sub new {
  my $class = shift;
  my $self  = {};
  bless($self, $class);
  return $self;
}

#########
# shamelessly ripped from jws's routine in EnsWeb.pm
#
sub get_unique_id {
  my ($hostname) = &hostname() =~ /^([^\.]+)/;
  $hostname      =~ s/\-//g;
  $hostname      = substr($hostname,-3);
  my ($seconds, $microseconds) = gettimeofday;

  my $numid    = $$.$seconds.$microseconds.int(rand(99));
  my %letters;
  @letters{(10..36 , 40..66)} = ('A'..'Z','a'..'z');

  my $packednum;
  for my $pair (unpack ("A2" x (1+length($numid)/2),$numid)){
    $packednum .= $letters{$pair} || $pair;
  }

  return qq($hostname$packednum);
}

sub get_hashed_id {
  my $self = shift;
  my $id = $self->get_unique_id();
  my $digest = sha256_base64($id); 
  return $digest;
}

1;
