#########
# Author:        rmp
# Maintainer:    $Author: jc3 $
# Created:       2006-06-28
# Last Modified: $Date: 2008/09/22 13:56:14 $
#
package Website::Service;
use strict;
use warnings;
use Website::ServiceManager;

our $VERSION = do { my @r = (q$Revision: 1.30 $ =~ /\d+/g); sprintf '%d.'.'%03d' x $#r, @r };
our $DEBUG   = 0;
our $SSH     = 'ssh -x ';
our $HOME    = '/nfs/WWW';
our $PATH    = join(':', qw(/sbin
			    /usr/sbin
			    /usr/apps/bin
			    /usr/bin
			    /usr/local/bin
			    /bin
			    /usr/local/oracle
			   ));

our $LD_LIBRARY_PATH = join(':', qw(/usr/local/lib
				    /usr/local/ssl/lib
				    /usr/apps/lib
				    /usr/local/oracle
				    /GPFS/data1/WWW/bin/apache2/lib));

sub new {
  my ($self, $ref) = @_;
  $ref ||= {};
  bless $ref, $self;
  return $ref;
}

sub stop {
  my $self = shift;
  $self->_process('stop', @_);
}

sub start {
  my $self = shift;
  $self->_process('start', @_);
}

sub restart {
  my $self = shift;
  $self->_process('restart', @_);
}

sub status {
  my $self = shift;
  $self->_process('status', @_);
}

sub platform {
  my ($self, $node) = @_;

  #########
  # Determine the target platform
  #
  if(!$self->{'platform'}) {
    my $platform = &_cmd($node, '-', qq($SSH $node uname));
    chomp $platform;
    $self->{'platform'} = $platform;

    $DEBUG and printf STDERR "%-30s Determined platform $platform\n", "[-/$node/-]";
  }

  return $self->{'platform'} || '';
}

sub _process {
  my ($self, $action, $opts) = @_;
  my $srvc = $self->{'service'};
  my $node = $self->{'node'};
  $opts  ||= {};
  $opts->{'output'} ||= 'yes';

#  if(!$self->{'pidfile'}) {
#    printf STDERR "%-30s No pidfile configured\n", "[$action/$node/$srvc]";
#    return;
#  }

  print "Performing $action on $self->{'node'}:$self->{'service'}\n" if($action ne 'status');

  if(!$srvc) {
    $DEBUG and printf STDERR "%-30s Skipping container with no service\n", "[$action/$node]";
    return;
  }

#  print "[$action/$node/$srvc] Executing\n";


  #########
  # See if we've got a pidfile
  #
  my $pid = '';

  eval {
    local %SIG;
    $SIG{ALRM} = sub { die 'timeout' };
    alarm(10);
    if($self->{'pidfile'}) {
      $pid = &_cmd($node, $srvc, qq($SSH $node "test -f $self->{'pidfile'} && cat $self->{'pidfile'}" 2>&1));

      $DEBUG and printf STDERR "%-30s Received pid '$pid'\n", "[$action/$node/$srvc]";
    }
    alarm(0);
  };

  if ($@) {
    if ($@ =~ /timeout/) {
      warn qq(Failed to contact $self->{'node'}, is it up?\n);
      return;
    }
  }

  #########
  # See if our service is running
  #
  my $running    = '';
  my $orphaned   = '';
  my $widepsopts = ($self->platform($node) =~ /OSF/i)?'':'www';

  if($pid) {
    #########
    # Check pid-associated stuff if we have a pid
    #
    $running = &_cmd($node, $srvc, qq($SSH $node "ps $widepsopts $pid | tail -n +2 | grep '$self->{'conf'}'" 2>&1 ));

    if(!$running) {
      $orphaned = &_cmd($node, $srvc, qq($SSH $node "ps augx$widepsopts | grep '$self->{'conf'}' | grep -v grep" 2>&1 ));
      if($orphaned =~ /^ssh:/) {
	$orphaned = 0;

      } else {
	$orphaned = $orphaned?1:0;
      }
    }

    # $running                = service is up
    # !$running && $orphaned  = service is orphaned - needs cleanup
    # !$running && !$orphaned = service is down

  } elsif($self->{'conf'}) {
    #########
    # Otherwise do a process table scan
    #
    $running  = &_cmd($node, $srvc, qq($SSH $node "ps augx$widepsopts | grep '$self->{'conf'}' | grep -v grep" 2>&1 ));
    if($running =~ /^ssh:/) {
      $running = 0;

    } else {
      $running  = $running?1:0; # fake up something to match the tests below
      $orphaned = $running;
    }

  } else {
    printf STDERR "%-30s Skipping container with no configuration file\n", "[$action/$node]";
    return;
  }

  my $preexec = '';
  ($running)  = $running =~ /^\s*(\d+)/;
  $running  ||= '';

  if($self->{'shell'} =~ /^(lst|t)?csh$/) {
    $preexec = qq(cd "$self->{'root'}"; setenv HOME "$HOME"; setenv LD_LIBRARY_PATH "$LD_LIBRARY_PATH"; setenv PATH "$PATH");

    if($self->{'lsf'} =~ /on|yes/) {
      $preexec .= qq(; source /usr/local/lsf/conf/cshrc.lsf);
    }

  } else {
    $preexec = qq(cd "$self->{'root'}"; export HOME="$HOME"; export LD_LIBRARY_PATH="$LD_LIBRARY_PATH"; export PATH="$PATH");

    if($self->{'lsf'} =~ /on|yes/) {
      $preexec .= qq(; source /usr/local/lsf/conf/profile.lsf);
    }
  }

  $pid           =~ s/[\r\n]+/ /smg;
  $self->{'pid'} = $pid;

  if($action eq "start") {
    if($running =~ /^[\s\d]+/) {
      printf STDERR "%-30s Running already ($running)\n", "[$action/$node/$srvc]";
      return;
    }

    if(!$self->{'start'}) {
      printf STDERR "%-30s No start command configured\n", "[$action/$node/$srvc]";
      return;
    }

    if($orphaned) {
      $self->_cleanup_orphans($action);
    }

    &_cmd($node, $srvc, qq($SSH $node "$preexec ; exec $self->{'start'}; ps augx$widepsopts | grep $self->{'conf'} | grep -v grep"), $self), "\n";

  } elsif($action eq "stop") {
    if(!$running) {
      printf STDERR "%-30s Stopped already\n", "[$action/$node/$srvc]";
      return;
    }

    if(!$self->{'stop'}) {
      printf STDERR "%-30s No stop command configured\n", "[$action/$node/$srvc]";
      return;
    }

    if($orphaned) {
      $self->_cleanup_orphans($action);

    } elsif($pid) {
      &_cmd($node, $srvc, qq($SSH $node "$preexec ; $self->{'stop'}; ps augx$widepsopts | grep $self->{'conf'} | grep -v grep"), $self);

    } else {
      printf "%-30s No pid / Nothing to kill\n", "[$action/$node/$srvc]";
    }

  } elsif($action eq "restart") {
    if(!$running) {
      printf STDERR "%-30s Not running\n", "[$action/$node/$srvc]";
      return;
    }

    if(!$self->{'restart'}) {
      printf STDERR "%-30s No restart command configured\n", "[$action/$node/$srvc]";
      return;
    }

    if($orphaned) {
      $self->_cleanup_orphans($action);
    }

    &_cmd($node, $srvc, qq($SSH $node "$preexec ; $self->{'restart'}; ps augx$widepsopts | grep $self->{'conf'} | grep -v grep"), $self);

  } elsif($action eq "status") {
    my $state = "DOWN";
    $state    = "UP"   if($running);
    $state    = "ORPH" if($orphaned);
    if($opts->{'output'} eq "yes") {
      printf("%-30s pid=%-8s %s\n", "[$action/$node/$srvc]", $pid, $state);
    } else {
      return $state;
    }
  }
}

sub _cleanup_orphans {
  my ($self, $action) = @_;
  my $node       = $self->{'node'};
  my $srvc       = $self->{'service'};
  my $widepsopts = ($self->platform($node) =~ /OSF/i)?'':'www';
  printf("%-30s Cleanup up orphan processes\n", "[$action/$node/$srvc]");;
  print &_cmd($node, $srvc, qq($SSH $node "ps augx$widepsopts | grep $self->{'conf'} | grep -v grep | awk '{print \\\$2}' | xargs kill -KILL")), "\n";
}

sub _cmd {
  my ($node, $service, $cmd, $extra) = @_;
  $extra ||= {};

  #########
  # Perform final 'static' interpolation
  #
  $cmd = &Website::ServiceManager::_interpolate($node, $service, $cmd);

  #########
  # Perform dynamic / runtime interpolation
  #
  for my $k (keys %$extra) {
    $cmd =~ s/\%$k/$extra->{$k}/g;
  }

  $DEBUG and print STDERR qq(cmd=$cmd\n);
  my $result = `$cmd`;
  chomp $result;
  $DEBUG and print STDERR $result, "\n";
  return $result;
}

1;
