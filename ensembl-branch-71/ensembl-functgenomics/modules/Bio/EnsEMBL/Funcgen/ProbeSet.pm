#
# Ensembl module for Bio::EnsEMBL::Funcgen::ProbeSet
#

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

    http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <ensembl-dev@ebi.ac.uk>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=head1 NAME

Bio::EnsEMBL::Funcgen::ProbeSet - A module to represent a probeset.

=head1 SYNOPSIS

 use Bio::EnsEMBL::Registry;
 use Bio::EnsEMBL::Funcgen::ProbeSet;


 my $reg = Bio::EnsEMBL::Registry->load_adaptors_from_db(-host    => 'ensembldb.ensembl.org',
                                                         -user    => 'anonymous');

 my $pset_adaptor = $reg->get_adaptor($species, 'funcgen', 'ProbeSet');

 ### Creating/storing a ProbeSet ###

 my $probe_set = Bio::EnsEMBL::Funcgen::ProbeSet->new(-NAME          => 'ProbeSet-1',
                                                      -SIZE          => 1,
                                                      -FAMILY        => "ENCODE REGIONS",#optional
                                                     );

 $pset_adaptor->store($probe_set);


 ### Fetching associated transcripts ###
 # Generated by the Ensembl array mapping pipeline

 my @dbentries     = @{$probe_set->fetch_all_Transcript_DBEntries};
 my $trans_adaptor = $reg->get_adpator($species, 'core', 'Transcript');

 foreach my $dbe(@dbentries){

    my $tx = $trans_adaptor->fetch_by_stable_id($dbe->primary_id);
   
    #Print the transcript info and the linkage annotation
    print $tx->stable_id."\t".$probe_set->name.' '.$dbe->linkage_annotation."\n";
 }

 #Alternatively these annotations are also available in a transcript centric manner
 #using the ProbeSetAdaptor


=head1 DESCRIPTION

A ProbeSet object represents a set of probes on a microarray. The
data (currently the name, size, and family) are stored in the probe_set 
table. ProbeSets are only really relevant for Affy probes, or when 
avaliable these will be analagous to Nimblegen feature sets.

For Affy arrays, a probeset can be part of more than one array, containing unique
probes. 

#Need to rewrite this bit
#Something about array_chip_id i.e. experimental validation etc
On each Affy array the probe has a slightly different name. For
example, two different complete names for the same probe might be
DrosGenome1:AFFX-LysX-5_at:535:35; and Drosophila_2:AFFX-LysX-5_at:460:51;. In
the database, these two probes will have the same probe_id. Thus the same
Affy probe can have a number of different names and complete names depending on
which array it is on.


=head1 SEE ALSO

  Bio::EnsEMBL::Funcgen::ProbeSetAdaptor
  ensembl-functgenomics/scripts/examples/microarray_annotation_example.pl

  Or for details on how to run the array mapping pipeline see:
  ensembl-functgenomics/docs/array_mapping.txt

=cut

use strict;
use warnings;

package Bio::EnsEMBL::Funcgen::ProbeSet;

use Bio::EnsEMBL::Utils::Argument qw( rearrange ) ;
use Bio::EnsEMBL::Utils::Exception qw( throw warning );
use Bio::EnsEMBL::Funcgen::Storable;

use vars qw(@ISA);
@ISA = qw(Bio::EnsEMBL::Funcgen::Storable);


=head2 new

  Arg [-NAME]           : string - probeset name
  Arg [-SIZE]           : int - probe set size
        Will be the same for all probes sets if same probe set
		is on multiple arrays.
  Arg [-FAMILY]         : string - probe set family, generic descriptor for probe set e.g. ENCODE REGIONS, RANDOM
        Will be the same for all probes sets if same probe set is on multiple arrays.
  Example    : my $probeset = Bio::EnsEMBL::Funcgen::ProbeSet->new(
                   -NAME          => 'ProbeSet-1',
				   -SIZE          => 1,
                   -FAMILY        => "ENCODE_REGIONS",
               );
  Description: Creates a new Bio::EnsEMBL::Funcgen::ProbeSet object.
  Returntype : Bio::EnsEMBL::Funcgen::ProbeSet
  Exceptions : Throws if not supplied with probeset name and array chip id(s)
  Caller     : General
  Status     : Medium Risk

=cut

sub new {
	my $caller = shift;
	
	my $class = ref($caller) || $caller;
	
	my $self = $class->SUPER::new(@_);

	#warn("The only way to get array names/ids, is to retrieve all the probes!!!");

	
	my (
		$name,          $size,
		$family
	) = rearrange([
		'NAME',          'SIZE',
		'FAMILY',
	], @_);
	
		
	$self->name($name)     if defined $name;
	$self->family($family) if defined $family;
	$self->size($size)     if defined $size;
	
	return $self;
}



#=head2 get_all_ProbeFeatures

#  Args       : None
#  Example    : my $features = $probeset->get_all_ProbeFeatures();
#  Description: Get all features produced by this probeset. The probeset needs to be
#               database persistent.
#  Returntype : Listref of Bio::EnsEMBL::Funcgen::ProbeFeature objects
#  Exceptions : None
#  Caller     : General
#  Status     : Medium Risk

#=cut

sub get_all_ProbeFeatures {
	my $self = shift;

	throw("Not implemented yet, do we want to do this for ProbeSet or just probe?");

	if ( $self->adaptor() && $self->dbID() ) {
		return $self->adaptor()->db()->get_ProbeFeatureAdaptor()->fetch_all_by_ProbeSet($self);
	} else {
		warning('Need database connection to retrieve Features');
		return [];
	}    
}

=head2 get_all_Arrays

  Args       : None
  Example    : my $arrays = $probeset->get_all_Arrays();
  Description: Returns all arrays that this probeset is part of. Only works if the
               probedet was retrieved from the database or created using
			   add_Array_probename.
  Returntype : Listref of Bio::EnsEMBL::Funcgen::Array objects
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub get_all_Arrays {
  my $self = shift;

  if (defined $self->{'arrays'}) {
	return $self->{'arrays'};
  } 
  else{
	$self->{arrays} = $self->adaptor->db->get_ArrayAdaptor->fetch_all_by_ProbeSet($self);
  }
  
  $self->{arrays}
}


=head2 get_all_Probes

  Args       : None
  Example    : my @probes = @{$probeset->get_all_Probes();
  Description: Returns all probes belonging to this ProbeSet
  Returntype : Listref of Bio::EnsEMBL::Funcgen::Probe objects
  Exceptions : None
  Caller     : General
  Status     : At Risk

=cut

sub get_all_Probes {
  my $self = shift;

  if (defined $self->{'probes'}) {
	return $self->{'probes'};
  } 
  else{
	$self->{probes} = $self->adaptor->db->get_ProbeAdaptor->fetch_all_by_ProbeSet($self);
  }
  
  $self->{probes}
}



#sub get_all_array_chips_ids?
#sub get_all_Results? from_Experiment?

=head2 name

  Arg [1]    : string - aprobeset name
  Example    : my $probesetname = $probeset->name('probeset-1');
  Description: Getter/Setter for the name attribute of ProbeSet objects.
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub name {
    my $self = shift;
	$self->{'name'} = shift if @_;
    return $self->{'name'};
}


=head2 family

  Arg [1]    : (optional) string - family
  Example    : my $family = $probe->family();
  Description: Getter and setter of family attribute for ProbeSet
               objects. e.g. EXPERIMENTAL or CONTROL
  Returntype : string
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub family {
    my $self = shift;
    $self->{'family'} = shift if @_;
    return $self->{'family'};
}

=head2 size

  Arg [1]    : (optional) int - probeset size
  Example    : my $probeset_size = $probeset->size();
  Description: Getter and setter of probeset size attribute for ProbeSet
               objects.
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

sub size {
    my $self = shift;
    $self->{'size'} = shift if @_;
    return $self->{'size'};
}

1;
