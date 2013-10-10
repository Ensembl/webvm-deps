=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
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

Bio::EnsEMBL::Compara::DBSQL::BaseRelationAdaptor

=head1 DESCRIPTION

Base class for the adaptors that deal with sets of members, like
FamilyAdaptor, DomainAdaptor, HomologyAdaptor


=head1 INHERITANCE TREE

  Bio::EnsEMBL::Compara::DBSQL::BaseRelationAdaptor
  +- Bio::EnsEMBL::Compara::DBSQL::BaseAdaptor

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 MAINTAINER

$Author: mm14 $

=head VERSION

$Revision: 1.26 $

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::DBSQL::BaseRelationAdaptor;

use strict;
use Bio::EnsEMBL::Utils::Exception;
use DBI qw(:sql_types);

use base ('Bio::EnsEMBL::Compara::DBSQL::BaseAdaptor');


=head2 fetch_by_stable_id

  Arg [1]    : string $stable_id
               the unique database identifier for the feature to be obtained
  Example    : $family = $adaptor->fetch_by_stable_id('ENSFM00300000084926')
  Description: Returns the object created from the database and defined by the
               the stable id $stable_id.
  Returntype : Bio::EnsEMBL::Compara::MemberSet
  Exceptions : thrown if $stable_id is not defined
  Caller     : general

=cut

sub fetch_by_stable_id {
    my ($self, $stable_id) = @_;

    unless(defined $stable_id) {
        $self->throw("fetch_by_stable_id must have an stable_id");
    }

    my $constraint = 'stable_id = ?';

    $self->bind_param_generic_fetch($stable_id, SQL_VARCHAR);

    return $self->generic_fetch_one($constraint)
}


=head2 fetch_all_by_method_link_type

  Arg [1]    : string $method_link_type
               the method type used to filter the objects
  Example    : $homologies = $adaptor->fetch_all_by_method_link_type('ENSEMBL_ORTHOLOGUES')
  Description: Returns the list of all the objects whose MethodLinkSpeciesSet
                matches the method with the type $method_link_type
  Returntype : ArrayRef of MemberSet
  Exceptions : thrown if $method_link_type is not defined
  Caller     : general

=cut

sub fetch_all_by_method_link_type {
    my ($self, $method_link_type) = @_;

    $self->throw("method_link_type arg is required\n")
        unless ($method_link_type);

    my @tabs = $self->_tables;
    my ($name, $syn) = @{$tabs[0]};

    my $join = [ [['method_link_species_set', 'mlss'], "mlss.method_link_species_set_id = $syn.method_link_species_set_id"], [['method'], 'method.method_link_id = mlss.method_link_id'] ];
    my $constraint = 'method.type = ?';

    $self->bind_param_generic_fetch($method_link_type, SQL_VARCHAR);

    return $self->generic_fetch($constraint, $join);
}


1;