=head1 LICENSE

  Copyright (c) 1999-2012 The European Bioinformatics Institute and
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

Bio::EnsEMBL::Compara::DBSQL::NCTreeAdaptor

=head1 DESCRIPTION

Specialization of Bio::EnsEMBL::Compara::DBSQL::GeneTreeAdaptor for non-coding genes

=head1 INHERITANCE TREE

  Bio::EnsEMBL::Compara::DBSQL::NCTreeAdaptor
  `- Bio::EnsEMBL::Compara::DBSQL::GeneTreeAdaptor
     `- Bio::EnsEMBL::Compara::DBSQL::NestedSetAdaptor

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 MAINTAINER

$Author: mm14 $

=head VERSION

$Revision: 1.7 $

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::DBSQL::NCTreeAdaptor;

use strict;

use base ('Bio::EnsEMBL::Compara::DBSQL::GeneTreeAdaptor');

sub default_where_clause {
    return "tr.tree_type IN ('ncrnaclusterset', 'ncrnatree')";
}


sub _get_canonical_Member {
  my $self = shift;
  my $member = shift;

  return $member->get_canonical_transcript_Member;
}

1;
