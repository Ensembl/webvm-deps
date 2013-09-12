# $Id: AutoComplete.pm,v 1.4 2012-11-07 11:00:31 sb23 Exp $

package EnsEMBL::Web::Controller::AutoComplete;

### Provides JSON results for autocomplete dropdown in location navigation bar

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $self  = {};
  
  bless $self, $class;
  
  my $hub     = EnsEMBL::Web::Hub->new;
  my $cache   = $hub->cache;
  my $species = $hub->species;
  my $query   = $hub->param('q');
  my ($key, $results);
  
  if ($cache) {
    $key     = sprintf '::AUTOCOMPLETE::GENE::%s::%s::', $hub->species, $query;
    $results = $cache->get($key);
  }
  
  if (!$results) {
    my $dbh = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub)->db;
    my $sth = $dbh->prepare(sprintf 'select display_label, stable_id, db from gene_autocomplete where species = "%s" and display_label like %s', $species, $dbh->quote("$query%"));
    
    $sth->execute;
    
    $results = $sth->fetchall_arrayref;
    $cache->set($key, $results, undef, 'AUTOCOMPLETE') if $cache;
  }
  
  print $self->jsonify($results);
  
  return $self;
}

1;
