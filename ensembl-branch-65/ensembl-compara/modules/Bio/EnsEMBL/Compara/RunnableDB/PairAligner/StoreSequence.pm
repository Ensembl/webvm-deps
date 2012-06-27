=head1 LICENSE

  Copyright (c) 1999-2011 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

    http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=head1 NAME

Bio::EnsEMBL::Compara::RunnableDB::PairAligner::StoreSequence

=cut

=head1 SYNOPSIS

my $db       = Bio::EnsEMBL::Compara::DBAdaptor->new($locator);
my $runnable = Bio::EnsEMBL::Compara::Production::GenomicAlignBlock::StoreSequence>new (
                                                    -db      => $db,
                                                    -input_id   => $input_id
                                                    -analysis   => $analysis );
$runnable->fetch_input(); #reads from DB
$runnable->run();
$runnable->write_output(); #writes to DB

=cut

=head1 DESCRIPTION

This object gets the DnaFrag objects from a DnaFragChunkSet and stores the sequence (if short enough) in the Compara sequence table

=cut

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::Compara::RunnableDB::PairAligner::StoreSequence;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);

use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBLoader;

use Bio::EnsEMBL::Compara::Production::DBSQL::DBAdaptor;

use Bio::EnsEMBL::Compara::Production::DnaFragChunk;
use Bio::EnsEMBL::Compara::Production::DnaFragChunkSet;
use Bio::EnsEMBL::Compara::Production::DnaCollection;

use Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor;

use Bio::EnsEMBL::Analysis::RunnableDB;
use base ('Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable');

=head2 fetch_input

    Title   :   fetch_input
    Usage   :   $self->fetch_input
    Function:   prepares global variables and DB connections
    Returns :   none
    Args    :   none

=cut

sub fetch_input {
    my( $self) = @_;

    #Convert chunkSetID into DnaFragChunkSet object
    if(defined($self->param('chunkSetID'))) {
	my $chunkset = $self->compara_dba->get_DnaFragChunkSetAdaptor->fetch_by_dbID($self->param('chunkSetID'));
	$self->param('dnaFragChunkSet', $chunkset);
    }
    
    #Convert chunkID into DnaFragChunk object
    if(defined($self->param('chunkID'))) {
	my $chunk = $self->compara_dba->get_DnaFragChunkAdaptor->fetch_by_dbID($self->param('chunkID'));
	$self->param('dnaFragChunk', $chunk);
    }
   
    return 1;
}


sub run {
  my ($self) = @_;

  return 1;
}


sub write_output {  
  my ($self) = @_;

  #
  #Get all the chunks in this dnaFragChunkSet
  #
  if (defined $self->param('dnaFragChunkSet')) {
      my $chunkSet = $self->param('dnaFragChunkSet');
      my $chunk_array = $chunkSet->get_all_DnaFragChunks;
      
      #Store sequence in Sequence table
      foreach my $chunk (@$chunk_array) {
	  my $bioseq = $chunk->bioseq;
	  if($chunk->sequence_id==0) {
	      $self->compara_dba->get_DnaFragChunkAdaptor->update_sequence($chunk);
	  }
      }
  }

  if (defined $self->param('dnaFragChunk')) {
      my $chunk = $self->param('dnaFragChunk');

      #Store sequence in Sequence table
      my $bioseq = $chunk->bioseq;
      if($chunk->sequence_id==0) {
	  $self->compara_dba->get_DnaFragChunkAdaptor->update_sequence($chunk);
      }
  }
  return 1;
}
1;
