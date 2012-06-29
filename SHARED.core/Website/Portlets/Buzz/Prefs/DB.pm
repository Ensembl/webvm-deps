#########
# Author: rmp@psyphi.net
#
package Website::Portlets::Buzz::Prefs::DB;
use strict;
use Website::Portlets::Buzz::Prefs;

use vars qw(@ISA);
@ISA = qw(Website::Portlets::Buzz::Prefs);

sub fields {
  qw(dbhost dbname dbuser dbpass username);
}


sub _feeds {
  my ($self, $ref) = @_;
  my $qusername     = $self->dbh->quote($self->{'username'}||"default");

  if($ref) {
    my $qfeedlist = $self->dbh->quote(join("\n", grep { $_ !~ /^\s*$/} @{$ref})."\n");
    $self->dbh->do(qq(REPLACE INTO feed (username,feedlist)
		      VALUES($qusername, $qfeedlist)));
  }

  my $res = $self->dbh->selectall_arrayref(qq(SELECT feedlist
					      FROM   feed
					      WHERE  username=$qusername));
  my $list = $res->[0]->[0] || "";
  return split("\n", $list);
}

1;
