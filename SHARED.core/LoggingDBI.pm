#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2004-01-06
# Last Modified: $Date: 2007-06-06 13:13:17 $
# Id:            $Id: LoggingDBI.pm,v 1.2 2007-06-06 13:13:17 rmp Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/LoggingDBI.pm,v $
# $HeadURL$
#
package LoggingDBI;
use strict;
use warnings;
use DBI;

our $VERSION  = do { my @r = (q$Revision: 1.2 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $AUTOLOAD;

sub connect {
  my $class = shift;
  my $self  = {
               '_history' => [],
               '_dbh'     => DBI->connect(@_),
              };
  bless $self, $class;

  return $self;
}

sub connect_cached {
  my $class = shift;
  my $self  = {
               '_history' => [],
               '_dbh'     => DBI->connect_cached(@_),
              };
  bless $self, $class;

  return $self;
}

sub profiler {
  my ($self, $profiler) = @_;
  if($profiler) {
    $self->{'_profiler'} = $profiler;
  }
  return $self->{'_profiler'};
}

sub AUTOLOAD {
  my $self         = shift;
  my ($func)       = $AUTOLOAD =~ /([^:]+)$/mx;
  my $profiler     = $self->profiler();
  my $summarytag   = join ' || ', grep { defined } @_;
  $summarytag      =~ s/\s+/ /mxg;
  my $aggregatetag = $_[0]||q();
  $aggregatetag    =~ s/\s+/ /mxg;

  if($profiler && $aggregatetag)                               { $profiler->begin("DBI aggregate: $aggregatetag"); }
  if($profiler && $summarytag && $aggregatetag ne $summarytag) { $profiler->begin("DBI: $summarytag"); }
  my $result;
  if(defined $self->{'_dbh'}) {
    $result = $self->{'_dbh'}->$func(@_);
  }
  if($profiler && $summarytag && $aggregatetag ne $summarytag) { $profiler->end("DBI: $summarytag"); }
  if($profiler && $aggregatetag)                               { $profiler->end("DBI aggregate: $aggregatetag"); }
  return $result;
}

1;
