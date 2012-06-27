package EnsEMBL::Web::DBSQL::WebDBConnection;

use strict;
use warnings;
use EnsEMBL::Web::Cache;

our $cache = new EnsEMBL::Web::Cache;

sub import {
  my ($class, $species_defs) = @_;
  my $caller = caller;
  my $dsn = join(':',
    'dbi',
    'mysql',
    $species_defs->multidb->{'DATABASE_WEBSITE'}{'NAME'},
    $species_defs->multidb->{'DATABASE_WEBSITE'}{'HOST'},
    $species_defs->multidb->{'DATABASE_WEBSITE'}{'PORT'},
  );

  $caller->connection(
    $dsn,
    $species_defs->multidb->{'DATABASE_WEBSITE'}{'USER'} || $species_defs->DATABASE_WRITE_USER,
    defined $species_defs->multidb->{'DATABASE_WEBSITE'}{'PASS'} ? $species_defs->multidb->{'DATABASE_WEBSITE'}{'PASS'} : $species_defs->DATABASE_WRITE_PASS,

    {
      RaiseError => 1,
      PrintError => 1,
      AutoCommit => 1,
    }
  ) || die "Can not connect to $dsn";

  $caller->cache($cache)
    if $cache;
}

1;
