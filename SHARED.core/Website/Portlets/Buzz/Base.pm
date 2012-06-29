#########
# Author: rmp@psyphi.net
#
package Website::Portlets::Buzz::Base;
use strict;
use DBI;
use Exporter;

sub init {
  my $self = shift;
  $self->{'dbhost'} ||= "webdbsrv";
  $self->{'dbname'} ||= "portlet";
  $self->{'dbuser'} ||= "portletrw";
  $self->{'dbpass'} ||= "RHTt4t/R";
}

sub dbh {
  my ($self)  = @_;
  my $retries = 3;

  while(!$self->{'dbh'} && !$self->{'_db_failed'} && $retries > 0) {
    $SIG{ALRM} = sub { die "timeout";};
    alarm(5);
    eval {
      $self->{'dbh'} ||= DBI->connect_cached("DBI:mysql:database=$self->{'dbname'};host=$self->{'dbhost'}",
					     $self->{'dbuser'},
					     $self->{'dbpass'},
					     {RaiseError=>1});
    };
    alarm(0);
    if($@) {
      $retries--;
      $self->{'_db_failed'} = 1 unless($retries);
    }
  }
  if(!$self->{'dbh'}) {
    warn qq(Failed to connect to portlets database: $@\n);
    $self->{'_db_failed'} = 1;
  }
  return $self->{'dbh'};
}

sub gen_getarray {
  my ($self, $class, $query) = @_;
  $self   = $self->new() unless(ref($self));
  my @res = ();
  my $sth;

  eval {
    $sth = $self->dbh->prepare($query);
    $sth->execute();
  };
  if($@) {
    warn $@;
    $query =~ s/\s+/ /smg;
    print STDERR qq(Query was:\n$query\n\n);
  }

  while(my $ref = $sth->fetchrow_hashref()) {
    $ref->{'dbh'} = $self->dbh();
    push @res, $class->new($ref);
  }
  return @res;
}

1;
