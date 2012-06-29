#########
# Author:        rmp
# Maintainer:    $Author: nb5 $
# Created:       2006-06-28
# Last Modified: $Date: 2009-04-01 14:22:55 $
#
package Website::ServiceManager;
use strict;
use warnings;
use Website::Service;

our $VERSION = do { my @r = (q$Revision: 1.77 $ =~ /\d+/g); sprintf '%d.'.'%03d' x $#r, @r };
our $DEBUG   = 0;
our $SERVERS = {
  'frontend' => {
    '_services' => [qw(proxy)],
    '_lsf'      => 'off',
    'intweb2'   => {
      '_shell'    => 'bash',
      '_nodes'    => [qw(intweb2a intweb2b)],
    },
    'wwwsrv'   => {
      '_shell' => 'csh',
      'webfe'  => [qw(webfe-red1 webfe-red2 webfe-yellow1 webfe-yellow2)],
    },
  },
  'backend'  => {
    '_lsf'      => 'off',
    '_shell'    => 'bash',
    'live'      => {
      '_services'     => [qw(heavy lite webpublishd)],
      '_nodes'        => [qw(web-grn-01 web-yel-01 web-wwwold-01 web-wwwold-02 web-wwwold-03 web-wwwold-04)],
      'web-vm-grn-01' => {
        '_services' => [qw(heavy lite webpublishd)],
      },
    },
    'dev'      => {                   
      '_services' => [qw(heavy lite admin)],
      '_nodes'    => [qw(webdev2 webdev3)],
    },
  },
  'wtccc'    =>  {  
    '_services' => [qw(wtccc_live wtccc_dev)],
    '_lsf'      => 'off',
    '_shell'    => 'bash',
    'genoweb1'  => {
      '_nodes' => [qw(genoweb1a genoweb1b)],
    },
  },         
};

our $SERVICES = {
     'heavy' => {
         'pidfile' => qq(/chroot/web/WWWlogs/httpd.pid),
         'conf'    => qq(/WWWconf/httpd.conf),
         'start'   => qq(/etc/init.d/apache-heavy start),
         'stop'    => qq(/etc/init.d/apache-heavy stop),
         'restart' => qq(/etc/init.d/apache-heavy reload),
        },

     'lite' => {
         'pidfile' => qq(/chroot/web/WWWlogs/lite.httpd.pid),
         'conf'    => qq(/WWWconf/httpd-lite.conf),
         'start'   => qq(/etc/init.d/apache-lite start),
         'stop'    => qq(/etc/init.d/apache-lite stop),
         'restart' => qq(/etc/init.d/apache-lite reload),
        },
     'admin_old'     => {
         'root'    => qq(/GPFS/data1/WWW),
         'pidfile' => qq(%root/cdsllogs/webadmin.httpd.pid),
         'conf'    => qq(%root/conf/webadmin.conf),
         'start'   => qq(%root/bin/httpd -f %conf),
         'stop'    => qq(kill -TERM %pid),
         'restart' => qq(kill -USR1 %pid),
        },
     'admin' => {
         'pidfile' => qq(/chroot/live-test/WWWlogs/webadmin.httpd.pid),
         'conf'    => qq(/WWWconf/webadmin.conf),
         'start'   => qq(/etc/init.d/webadmin start),
         'stop'    => qq(/etc/init.d/webadmin stop),
         'restart' => qq(/etc/init.d/webadmin reload),
        },
     'proxy'     => {
         'root'    => qq(/apache/frontend),
         'pidfile' => qq(%root/logs/httpd.pid),
         'conf'    => qq(%root/conf/webfrontend.conf),
         'start'   => qq(%root/bin/httpd -D%cluster -D%host -f '%conf'),
         'stop'    => qq(kill -TERM %pid),
         'restart' => qq(kill -USR1 %pid),
        },
     'wtccc_live' => {
         'pidfile' => qq(/data/chroot/live/var/run/apache2.pid),
         'conf'    => qq(/WWWconf/live.conf),
         'start'   => qq(chroot /data/chroot/live/ /etc/init.d/apache-heavy start),
         'stop'    => qq(chroot /data/chroot/live/ /etc/init.d/apache-heavy stop),
         'restart' => qq(chroot /data/chroot/live/ /etc/init.d/apache-heavy reload),
        },
     'wtccc_dev' => {
         'pidfile' => qq(/data/chroot/dev/var/run/apache2.pid),
         'conf'    => qq(/WWWconf/dev.conf),
         'start'   => qq(chroot /data/chroot/dev/ /etc/init.d/apache-heavy start),
         'stop'    => qq(chroot /data/chroot/dev/ /etc/init.d/apache-heavy stop),
         'restart' => qq(chroot /data/chroot/dev/ /etc/init.d/apache-heavy reload),
        },
     'webpublishd' => {
         'pidfile' => qq(/chroot/web/WWWlogs/webpublishd.pid),
         'conf'    => qq(/usr/local/bin/webpublishd), # string required for status checks and nothing else
         'start'   => qq(/etc/init.d/webpublish start),
         'stop'    => qq(/etc/init.d/webpublish stop),
         'restart' => qq(/etc/init.d/webpublish reload),
        },
    };

our $DEFAULTS = {};

sub new {
  my ($class) = @_;
  my $self    = {};
  bless $self, $class;
  $self->_init_meta();
  return $self;
}

sub services {
  my $self = shift;
  my @services = ();

  while(my ($entry, $settings) = each %$self) {
    push @services, $entry;
    if(scalar @{$self->{$entry}->{'meta'}->{'_services'}||[]}) {
      for my $srv (@{$self->{$entry}->{'meta'}->{'_services'}}) {
        push @services, "$entry:$srv";
      }
    }
  }

  @services = sort {
    my ($a1, $a2) = split(/:/, $a);
    my ($b1, $b2) = split(/:/, $b);
    $a2 ||= '';
    $b2 ||= '';
    return $a1 cmp $b1 || $a2 cmp $b2
  } @services;

  return [map { $self->service($_) } @services];
}

sub service {
  my ($self, $nodeservice) = @_;

  my ($node, $service) = split(/:/, $nodeservice);

  $service ||= $node if($SERVICES->{$node});
  $node    ||= $service;

  #########
  # Process any children for this node
  #
  my @nodes   = @{$self->{$node}->{'_nodes'}||[]};
  my @results = ();

  if(scalar @nodes) {
    for my $child (sort @{$self->{$node}->{'_nodes'}}) {
      $child = "$child:$service" if($service && $child !~ /:/);
      push @results, @{$self->service($child)};
    }

  } else {

    for my $srvc (sort @{$self->{$node}->{'meta'}->{'_services'}||[]}) {
      next if($service && $service ne $srvc); # next if a service was given

      my $cfg = {
     'node'    => $node,
     'service' => $srvc,
    };

      for my $f (qw(root pidfile conf start stop restart)) {
        $cfg->{$f} = &_interpolate($node, $srvc, $SERVICES->{$srvc}->{$f} || $DEFAULTS->{$f} || '');
      }
      for my $f (keys %{$self->{$node}->{'meta'}}) {
        my $ff        = $f;
        $ff           =~ s/^_//;
        $cfg->{$ff} ||= $self->{$node}->{'meta'}->{$f};
      }
      push @results, Website::Service->new($cfg);
    }
  }

  $DEBUG and print STDERR qq(Looking for Service $nodeservice\n);
#  if(!scalar @results) {
#    my $err = qq(Service $nodeservice unknown);
#    print STDERR (!$self->{'_errors'}->{$err}++)?"$err\n":'';
#  }
  return \@results;
}

sub _init_meta {
  my $self = shift;
  $self  ||= {};

  #########
  # Add host-based configuration
  #
  while(my ($server, $meta) = each %$SERVERS) {
    &_descend($server, $meta, $self);
  }

  #########
  # Add service-based configuration
  #
  while(my ($entry, $settings) = each %$self) {
    next if(scalar @{$self->{$entry}->{'_nodes'}||[]}); # Skip if this entry contains multiple nodes

    for my $service (@{$self->{$entry}->{'meta'}->{'_services'}}) {
      $self->{$service} ||= {
           '_nodes' => [],
           'meta'   => {
            '_services' => [],
           },
          };
      push @{$self->{$service}->{'_nodes'}}, $entry;
    }
  }

  #########
  # Uniquify the list
  #
  while(my ($entry, $settings) = each %$self) {
    my $seensrv = {};
    $self->{$entry}->{'meta'}->{'_services'} = [grep { !$seensrv->{$_}++ } @{$self->{$entry}->{'meta'}->{'_services'}}];
  }

  return $self;
}

sub _descend {
  my ($Node, $Value, $results, $meta_ref) = @_;
  my $children = [];
  my $meta     = {%{$meta_ref||{}}};

  if(ref($Value) eq 'ARRAY') {
    $DEBUG and print STDERR "Value for $Node contains array of children\n";
    push @$children, @{$Value};

  } elsif($Value->{'_nodes'}) {
    $DEBUG and print STDERR "Value for $Node is a hash with listed child nodes\n";
    push @$children, @{$Value->{'_nodes'}||[]};
  }

  if(ref($Value) eq 'HASH') {
    $DEBUG and print STDERR "Adding services for $Node\n";
    while(my ($k, $v) = each %$Value) {
      next if($k eq '_nodes');
      $meta->{$k} = $v if(substr($k, 0, 1) eq '_');
    }
  }

  #########
  # Push on this node
  #
  $results->{$Node} ||= {};
  push @{$results->{$Node}->{'_nodes'}}, @$children if(@{$children});
  $results->{$Node}->{'meta'} = $meta;

  if(ref($Value) eq 'HASH') {
    while(my ($node, $value) = each %{$Value}) {
      next if(substr($node, 0, 1) eq '_' || $node eq '_nodes');
      $DEBUG and print STDERR "Descending hash-based child $node\n";
      &_descend($node, $value, $results, $meta);
      push @{$results->{$Node}->{'_nodes'}}, $node;
    }
  }

  for my $child (@$children) {
    $DEBUG and print STDERR "Descending regular child $child\n";
    &_descend($child, {}, $results, $meta);
  }
}

sub _interpolate {
  my ($host, $service, $str) = @_;

  my $cluster = $host;
  if($host =~ /^([a-z]+\d)[a-h]$/) { # cbi2a / webdev1a / wwwsrv1a
    $cluster = $1;

  } elsif($host =~ /^([a-z]+\-\d)\-\d+$/) { # web-1-01 / web-2-01
    $cluster = $1;
  }

  my $root = $SERVICES->{$service}->{'root'} || '';
  my $conf = $SERVICES->{$service}->{'conf'} || '';
  $str     =~ s/\%cluster/$cluster/g;
  $str     =~ s/\%host/$host/g;
  $str     =~ s/\%service/$service/g;
  $str     =~ s/\%conf/$conf/g;
  $str     =~ s/\%root/$root/g;

  return $str||'';
}

1;
