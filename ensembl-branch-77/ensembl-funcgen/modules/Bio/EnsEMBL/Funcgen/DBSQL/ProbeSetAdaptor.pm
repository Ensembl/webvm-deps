#
# Ensembl module for Bio::EnsEMBL::Funcgen::DBSQL::ProbeSetAdaptor
#

=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2018-2023] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=head1 NAME

Bio::EnsEMBL::Funcgen::DBSQL::ProbeSetAdaptor - A database adaptor for fetching and
storing ProbeSet objects.

=head1 SYNOPSIS

 use Bio::EnsEMBL::Registry;
 use Bio::EnsEMBL::Funcgen::ProbeSet;


 my $reg = Bio::EnsEMBL::Registry->load_adaptors_from_db(-host    => 'ensembldb.ensembl.org',
                                                         -user    => 'anonymous');


 my $pset_a = Bio::EnsEMBL::Resgitry->get_adpator($species, 'funcgen', 'ProbeSet');

 #Fetching a probeset by name
 my $probeset = $pset_a->fetch_by_array_probeset_name('Array-1', 'ProbeSet-1');

 ### Fetching probeset with transcript annotations ###
 # Generated by the Ensembl array mapping pipeline

 my @probesets     = @{$pset_a->fetch_all_by_linked_Transcript($transcript)};

 #Note: Associated linkage annotation is stored in the associated DBEntries

=head1 DESCRIPTION

The ProbeSetAdaptor is a database adaptor for storing and retrieving
ProbeSet objects.

=head1 SEE ALSO

  Bio::EnsEMBL::Funcgen::Probe
  Bio::EnsEMBL::Funcgen::ProbeSet
  ensembl-funcgen/scripts/examples/microarray_annotation_example.pl

  Or for details on how to run the array mapping pipeline see:
  ensembl-funcgen/docs/array_mapping.txt

=cut

package Bio::EnsEMBL::Funcgen::DBSQL::ProbeSetAdaptor;

use strict;
use warnings;
use Bio::EnsEMBL::Utils::Exception qw( throw warning );
use Bio::EnsEMBL::Funcgen::ProbeSet;
use Bio::EnsEMBL::Funcgen::DBSQL::BaseAdaptor;#DBI sql_types import

use base qw(Bio::EnsEMBL::Funcgen::DBSQL::BaseAdaptor);

=head2 fetch_by_array_probeset_name

  Arg [1]    : string - name of array
  Arg [2]    : string - name of probeset
  Example    : my $probeset = $opsa->fetch_by_array_probeset_name('Array-1', 'Probeset-1');
  Description: Returns a probeset given the array name and probeset name
               This will uniquely define a probeset. Only one
			   probeset is ever returned.
  Returntype : Bio::EnsEMBL::ProbeSet
  Exceptions : None
  Caller     : General
  Status     : At Risk

=cut

sub fetch_by_array_probeset_name{
	my ($self, $array_name, $probeset_name) = @_;

	if(! ($array_name && $probeset_name)){
	  throw('Must provide array_name and probeset_name arguments');
	}

	#Extend query tables
    $self->_tables([['probe', 'p'], ['array_chip', 'ac'], ['array', 'a']]);
	my $constraint = 'ps.name= ? AND ps.probe_set_id=p.probe_set_id AND p.array_chip_id=ac.array_chip_id AND ac.array_id=a.array_id AND a.name= ? GROUP by ps.probe_set_id';

	#bind params as we have unsafe string args
    $self->bind_param_generic_fetch($probeset_name, SQL_VARCHAR);
	$self->bind_param_generic_fetch($array_name,    SQL_VARCHAR);

	my $pset =  $self->generic_fetch($constraint)->[0];
    $self->reset_true_tables;

	return $pset;
}


=head2 fetch_all_by_name

  Arg [1]    : string - probe set name
  Example    : my @probes = @{$pdaa->fetch_all_by_name('ProbeSet1')};
  Description: Convenience method to re-instate the functionality of
               $core_dbentry_adpator->fetch_all_by_external_name('probeset_name');
               WARNING: This may not be the probeset you are expecting as
               probeset names are not unqiue across arrays and vendors.
               These should ideally be validated using the attached array
               information or alternatively use fetch_by_array_probeset_name
               Returns a probe with the given name.
  Returntype : Arrayref
  Exceptions : Throws if name not passed
  Caller     : General
  Status     : At Risk

=cut


sub fetch_all_by_name{
  my ($self, $name) = @_;

  throw('Must provide a probeset name argument') if ! defined $name;
  $self->bind_param_generic_fetch($name, SQL_VARCHAR);

  return $self->generic_fetch('ps.name=?');
}


=head2 fetch_by_ProbeFeature

  Arg [1]    : Bio::EnsEMBL::ProbeFeature
  Example    : my $probeset = $opsa->fetch_by_ProbeFeature($feature);
  Description: Returns the probeset that created a particular feature.
  Returntype : Bio::EnsEMBL::ProbeSet
  Exceptions : Throws if argument is not a Bio::EnsEMBL::ProbeFeature object
  Caller     : General
  Status     : At Risk

=cut

#This is a good candidate for complex query extension
#As we will most likely want the probe also if we are fetching the ProbeSet
#For a given feature.
#We could also set the probe in the ProbeFeature object, so we don't re-query
#should the user use ProbeFeature->get_probe
#This is also a case for passing the array name to automatically set
#the probe name? As we will likely know the array name beforehand.

#Could we also bring back annotations for this Probe/ProbeSet?
#

sub fetch_by_ProbeFeature {
	my ($self, $pfeature) = @_;
	$self->db->is_stored_and_valid('Bio::EnsEMBL::Funcgen::ProbeFeature', $pfeature);

	#Extend query
    $self->_tables([['probe', 'p']]);
	my $pset =  $self->generic_fetch('p.probe_id='.$pfeature->probe_id.' and p.probe_set_id=ps.probe_set_id GROUP by ps.probe_set_id')->[0];
    $self->reset_true_tables;
	return $pset;
}


=head2 fetch_all_by_Array

Arg [1]    : Bio::EnsEMBL::Funcgen::Array
Example    : my @probesets = @{$pset_adaptor->fetch_all_by_Array($array)};
Description: Fetch all ProbeSets on a particular array.
Returntype : Listref of Bio::EnsEMBL::ProbeSet objects.
Exceptions : throws if arg is not valid or stored
Caller     : General
Status     : At Risk

=cut

#This is quicker than query extension?

sub fetch_all_by_Array {
  my $self  = shift;
  my $array = shift;

  if(! (ref($array) && $array->isa('Bio::EnsEMBL::Funcgen::Array') && $array->dbID())){
	throw('Need to pass a valid stored Bio::EnsEMBL::Funcgen::Array');
  }

  #get all array_chip_ids, for array and do a subselect statement with generic fetch
  my $constraint = (  " ps.probe_set_id in"
					  ." ( SELECT distinct(p.probe_set_id)"
					  ."   from probe p where"
					  ."   p.array_chip_id IN (".join(",", @{$array->get_array_chip_ids()}).")"
					  ." )" );

  return $self->generic_fetch($constraint);
}



=head2 _true_tables

  Args       : None
  Example    : None
  Description: Returns the names and aliases of the tables to use for queries.
  Returntype : List of listrefs of strings
  Exceptions : None
  Caller     : Internal
  Status     : At Risk

=cut

sub _true_tables {
  return ([ 'probe_set', 'ps' ]);
}

=head2 _columns

  Args       : None
  Example    : None
  Description: PROTECTED implementation of superclass abstract method.
               Returns a list of columns to use for queries.
  Returntype : List of strings
  Exceptions : None
  Caller     : Internal
  Status     : At Risk

=cut

sub _columns {
  return qw( ps.probe_set_id ps.name ps.size ps.family);
}

=head2 _objs_from_sth

  Arg [1]    : DBI statement handle object
  Example    : None
  Description: PROTECTED implementation of superclass abstract method.
               Creates ProbeSet objects from an executed DBI statement
			   handle.
  Returntype : Listref of Bio::EnsEMBL::ProbeSet objects
  Exceptions : None
  Caller     : Internal
  Status     : At Risk

=cut

sub _objs_from_sth {
	my ($self, $sth) = @_;

	my (@result, $current_dbid, $probeset_id, $name, $size, $family);
	my ($array, %array_cache);

	$sth->bind_columns( \$probeset_id,  \$name, \$size, \$family);


	#do not have array_chip adaptor
	#use array adaptor directly
	#how are we going ot handle the cache here?????

	my $probeset;
	while ( $sth->fetch() ) {
		#$array = $array_cache{$array_id} || $self->db->get_ArrayAdaptor()->fetch_by_dbID($array_id);

		#This is nesting array object in probeset!
		#$array = $array_cache{$arraychip_id} || $self->db->get_ArrayAdaptor()->fetch_by_array_chip_dbID($arraychip_id);

		#Is this required? or should we lazy load this?
		#Should we also do the same for probe i.e. nest or lazy load probeset
		#Setting here prevents, multiple queries, but if we store the array cache in the adaptor we can overcome this
		#danger of eating memory here, but it's onld the same as would be used for generating all the probesets
		#what about clearing the cache?
		#also as multiple array_chips map to same array, cache would be redundant
		#need to store only once and reference.
		#have array_cache and arraychip_map
		#arraychip_map would give array_id which would be key in array cache
		#This is kinda reinventing the wheel, but reducing queries and redundancy of global cache
		#cache would never be populated if method not called
		#there for reducing calls and memory, increasing speed of generation/initation
		#if method were called
		#would slightly slow down processing, and would slightly increase memory as cache(small as non-redundant)
		#and map hashes would persist

		#Do we even need this????

		#warn("Can we lazy load the arrays from a global cache, which is itself lazy loaded and non-redundant?\n");


		#this current id stuff is due to lack of probeset table in core
		#if (!$current_dbid || $current_dbid != $probeset_id) {

		  # New probeset
		  $probeset = Bio::EnsEMBL::Funcgen::ProbeSet->new
			(
			 -dbID         => $probeset_id,
			 -name         => $name,
			 -size         => $size,
			 #			 -array        => $array,
			 -family       => $family,
			 -adaptor     => $self,
			);
		push @result, $probeset;

			#$current_dbid = $probeset_id;
		#} else {
		#	# Extend existing probe
		#	$probe->add_Array_probename($array, $name);
		#}
	}
	return \@result;
}

=head2 store

  Arg [1]    : List of Bio::EnsEMBL::Funcgen::ProbeSet objects
  Example    : $opa->store($probeset1, $probeset2, $probeset3);
  Description: Stores given ProbeSet objects in the database. Should only be
               called once per probe because no checks are made for duplicates.??? It certainly looks like there is :/
			   Sets dbID and adaptor on the objects that it stores.
  Returntype : None
  Exceptions : Throws if arguments are not Probe objects
  Caller     : General
  Status     : At Risk

=cut

sub store {
	my ($self, @probesets) = @_;

	my ($sth, $array);

	if (scalar @probesets == 0) {
		throw('Must call store with a list of Probe objects');
	}

	my $db = $self->db();

	PROBESET: foreach my $probeset (@probesets) {

		if ( !ref $probeset || !$probeset->isa('Bio::EnsEMBL::Funcgen::ProbeSet') ) {
			throw('ProbeSet must be an ProbeSet object');
		}

		if ( $probeset->is_stored($db) ) {
			warning('ProbeSet [' . $probeset->dbID() . '] is already stored in the database');
			next PROBESET;
		}

		$sth = $self->prepare("
					INSERT INTO probe_set
					(name, size, family)
					VALUES (?, ?, ?)
				");
		$sth->bind_param(1, $probeset->name(),                     SQL_VARCHAR);
		$sth->bind_param(2, $probeset->size(),                     SQL_INTEGER);
		$sth->bind_param(3, $probeset->family(),                   SQL_VARCHAR);

		$sth->execute();
		$probeset->dbID($self->last_insert_id);
		$probeset->adaptor($self);
	  }

	return \@probesets;
}



1;

