###########
# Author: perl hacks o'reilly
# Created: ?
# Maintainer: $author$
# Last Modified: $Date: 2009-05-01 10:32:36 $
# $Revision: 1.2 $ - $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Devel/TraceUse.pm,v $

package Devel::TraceUse;

use strict;
use warnings;
use Time::HiRes qw( gettimeofday tv_interval );

BEGIN {
  unshift @INC, \&trace_use unless grep { "$_" eq \&trace_use . q() } @INC;
}

our @used;
our $VERSION = '1.0'; 

sub trace_use {
  my ($code, $module) = @_;
  (my $mod_name = $module) =~ s |/|::|g;
  $mod_name =~ s/\.pm$//;
  my ($package, $filename, $line) = caller();
  my $elapsed = 0;

  {
    local *INC = [ @INC[1..$#INC] ];
    my $start_time = [ gettimeofday ];
    eval "package $package; require '$mod_name';";
    $elapsed = tv_interval( $start_time );
  }

  $package = $filename if $package eq 'main';
  push @used, {
               'file' => $package,
               'line' => $line,
               'time' => $elapsed,
               'module' => $mod_name,
              };
              
  return;
}

END {
  my $first = $used[0];
  my %seen = ( $first->{'file'} => 1 );
  my $pos = 1;
  
  warn "Modules used from $first->{'file'}:\n";

  for my $mod (@used) {
    my $message = q{};
    if (exists $seen{$mod->{'file'}}) {
      $pos = $seen{$mod->{'file'}};
    }
    else {
      $seen{$mod->{'file'}} = ++$pos;
    }

    my $indent = q{ } x $pos;
    $message .= "$indent$mod->{'module'}, line $mod->{'line'}";
    $message .= " ($mod->{'time'})" if $mod->{'time'};
    warn "$message\n";
  }
}

1;
