#########
# Author:        jc3
# Maintainer:    $Author: jc3 $
# Created:       2009-04-09
# Last Modified: $Date: 2009-04-09 11:39:13 $
# Revision: $Revision: 1.4 $ 
# Id: $Id: StopIPs.pm,v 1.4 2009-04-09 11:39:13 jc3 Exp $   
package Website::StopIPs;
use strict;
use warnings;
use Net::DNS;

our $VERSION = 0.1;
our $DEBUG = 0;

sub new {
  my ($class) = @_;
  my $self = {};
  bless $self,$class;
  $self->_init();
  return $self;
}

sub _init {
  my ($self) = @_;
  $self->{'lists'} = [
		'zen.dnsbl.ja.net',
		'bl.spamcop.net',
	];
  $self->{'blocked'} = 0;
  $self->{'res'} = Net::DNS::Resolver->new();
  return;
}

sub blacklisted {
  my ($self,$ips) = @_;
  return 1 unless $ips;

  #check if $ips needs to be split into more than one.
  $ips =~ s/\s+//gmx; # remove the white space
  my @ips = split /,/mx, $ips;
  
  my $blocked = 0;

  for my $ip (@ips) {
    my $rev = join q(.), reverse(split(/\./mx,$ip));

    foreach my $bl (@{$self->{'lists'}}) {
  	  my $ares = $self->{'res'}->search($rev.q(.).$bl,'A');
    	if(defined($ares)) {
        $DEBUG && warn "Found an A NAME\n";
  	   	my $txtres = $self->{'res'}->search($rev.q(.).$bl,'TXT');
  		  if(defined($txtres)) {
          $DEBUG && warn "Found a TXT NAME\n";
  			  my @a = $txtres->answer;
  			  warn $bl.' ... '.$a[0]->rdatastr."\n";
          $blocked += 1;
    		}
        else {
  	  		$DEBUG && warn $bl." ... A record found but no TXT record\n";
    		}
      }
    }
  }

  if ($blocked > 0){
    return 1;
  }
  return;
}

1;
