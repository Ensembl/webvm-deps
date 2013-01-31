#!/usr/local/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename qw( dirname );

# --- load libraries needed for reading config ---
use vars qw( $SERVERROOT );
BEGIN{
  $SERVERROOT = dirname( $Bin );
  unshift @INC, "$SERVERROOT/conf";
  eval{ require SiteDefs };
  if ($@){ die "Can't use SiteDefs.pm - $@\n"; }
  map{ unshift @INC, $_ } @SiteDefs::ENSEMBL_LIB_DIRS;
}

use Storable;
use Bio::Tools::Run::Search;
use Bio::Search::Result::EnsemblResult;
use EnsEMBL::Web::DBSQL::DBConnection;
use EnsEMBL::Web::SpeciesDefs;

my $token    = shift @ARGV;
my $filename = shift @ARGV;
(my $FN2 = $filename) =~ s/parsing/done/;
(my $FN3 = $filename) =~ s/parsing/error/;
if( ! $token ){ die( "runblast.pl called with no token" ) }
my @bits = split( '/', $token );
my $ticket = join( '',$bits[-3],$bits[-2] ); # Ticket = 3rd + 2nd to last dirs

# Retrieve the runnable object
my $SPECIES_DEFS = EnsEMBL::Web::SpeciesDefs->new();
my $DBCONNECTION = EnsEMBL::Web::DBSQL::DBConnection->new( undef, $SPECIES_DEFS );

my $blast_adaptor = $DBCONNECTION->get_databases_species( $SPECIES_DEFS->ENSEMBL_PRIMARY_SPECIES, 'blast')->{'blast'};
$blast_adaptor->{'disconnect_flag'} = 0;
$blast_adaptor->ticket( $ticket );

my $runnable = eval { Bio::Tools::Run::Search->retrieve( $token, $blast_adaptor  ) };

if( ! $runnable ){ 
  warn "Renaming $filename -> $FN3";
  rename $filename, $FN3;
  open O, ">>$FN3";
  print O $@;
  close O;
  die( "Token $token not found" );
}
$runnable->verbose(1);

eval{
  # Initialise
  my $species = $runnable->result->database_species();
  my $ensembl_adaptor = $DBCONNECTION->get_DBAdaptor( 'core', $species );
  warn $runnable;
  $runnable->result->core_adaptor( $ensembl_adaptor );
  
  # Do the job
  $runnable->parse( "$token.out" );
  $runnable->status("COMPLETED");
  $runnable->store;
};
if( $@ ){
  warn "Renaming $filename -> $FN3";
  rename $filename, $FN3;
  open O, ">>$FN3";
  print O $@;
  close O;
  die $@;
} else {
  warn "Renaming $filename -> $FN2";
  rename $filename, $FN2;
}
exit 0;