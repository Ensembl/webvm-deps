package EnsEMBL::Web::Factory::Translation;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Factory);

sub createObjects {   
  my $self = shift;
  my ($identifier, $fetch_call, $transobj);
  my $db          = $self->param( 'db' ) || 'core';
     $db          = 'otherfeatures' if $db eq 'est';
  my $db_adaptor  = $self->database($db) ;	
  unless ($db_adaptor){
    $self->problem('fatal', 
		   'Database Error', 
		   "Could not connect to the $db database."  ); 
    return ;
  }

  # If this is not a core database, we need to force the DBAdaptor to use 
  # the correct (core) SNP DB adaptor!
  #if( $db ne 'core' and $self->species_defs->databases->{'ENSEMBL_SNP'} ){
  #  my $snpdb_adaptor  = $self->database('snp');
  #  if( $snpdb_adaptor ){
  #    $db_adaptor->add_db_adaptor( 'SNP', $snpdb_adaptor );
  #  }
  #}

  if( $identifier = $self->param( 'peptide' ) ){ 
    $fetch_call = 'fetch_by_translation_stable_id';
  } elsif( $identifier = $self->param( 'transcript' ) ){ 
    $fetch_call = 'fetch_by_stable_id';
  } else {
     $self->problem('fatal', 'Please enter a valid identifier',
		     "This view requires a transcript or peptide 
                    identifier in the URL.");
    return;
  }


  foreach my $adapt_class("TranscriptAdaptor","PredictionTranscriptAdaptor"){
    my $adapt_getter = "get_$adapt_class";
    my $transcript_adaptor = $db_adaptor->$adapt_getter;
    (my $T = $identifier) =~ s/^(\S+)\.\d*/$1/g ; # Strip versions
    (my $T2 = $identifier) =~ s/^(\S+?)(\d+)(\.\d*)?/$1.sprintf("%011d",$2)/eg ; # Strip versions
    eval { $transobj = $transcript_adaptor->$fetch_call($identifier) };
    last if $transobj;
    eval { $transobj = $transcript_adaptor->$fetch_call($T2) };
    last if $transobj;
    eval { $transobj = $transcript_adaptor->$fetch_call($T) };
    last if $transobj;
  }

  if( ref( $transobj ) eq 'ARRAY' ){ 
    # if fetch_call is type 'fetch_all', take first object
    $transobj = $transobj->[0];
  }

  if(!$transobj || $@) { 
    # Query xref IDs
    $self->_archive( 'Transcript', 'transcript' );
    return if( $self->has_a_problem );
    $self->_known_feature( 'Transcript', 'transcript' ) ;
    return ;	
  }
  my $peptide_Obj = $transobj->translation ||
    $self->problem( 'fatal',
      'No Translation',
      "The identifier $identifier does not translate or has no translation." );

  # Set transcript param to Ensembl Stable ID
  $self->param( 'transcript',$transobj->stable_id  );
  my $dataobject = $self->new_object( 'Translation', $peptide_Obj, $self->__data );
     $dataobject->transcript( $transobj );
  $self->DataObjects( $dataobject );
  return 1;
}


1;