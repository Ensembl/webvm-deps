# $Id: Transcript.pm,v 1.174 2011-10-28 16:18:04 it2 Exp $

package EnsEMBL::Web::Configuration::Transcript;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}->{'default'} = $self->object ? $self->object->default_action : 'Summary';
}

sub user_tree { return 1; }

# either - prediction transcript or transcript
# domain - domain only (no transcript)
# history - IDHistory object or transcript
# database:variation - Variation database
sub populate_tree {
  my $self = shift;

  $self->create_node('Summary', 'Transcript summary',
    [qw(
      image   EnsEMBL::Web::Component::Transcript::TranscriptImage
      summary EnsEMBL::Web::Component::Transcript::TranscriptSummary
    )],
    { 'availability' => 'either', 'concise' => 'Transcript summary' }
  );

  my $T = $self->create_node('SupportingEvidence', 'Supporting evidence ([[counts::evidence]])',
   [qw( evidence EnsEMBL::Web::Component::Transcript::SupportingEvidence )],
    { 'availability' => 'transcript has_evidence', 'concise' => 'Supporting evidence' }
  );
  
  $T->append($self->create_subnode('SupportingEvidence/Alignment', '',
    [qw( alignment EnsEMBL::Web::Component::Transcript::SupportingEvidenceAlignment )],
    { 'no_menu_entry' => 'transcript' }
  ));
  
  my $seq_menu = $self->create_submenu('Sequence', 'Sequence');
  
  $seq_menu->append($self->create_node('Exons', 'Exons ([[counts::exons]])',
    [qw( exons EnsEMBL::Web::Component::Transcript::ExonsSpreadsheet )],
    { 'availability' => 'either has_exons', 'concise' => 'Exons' }
  ));
  
  $seq_menu->append($self->create_node('Sequence_cDNA', 'cDNA',
    [qw( sequence EnsEMBL::Web::Component::Transcript::TranscriptSeq )],
    { 'availability' => 'either', 'concise' => 'cDNA sequence' }
  ));
  
  $seq_menu->append($self->create_node('Sequence_Protein', 'Protein',
    [qw( sequence EnsEMBL::Web::Component::Transcript::ProteinSeq )],
    { 'availability' => 'either', 'concise' => 'Protein sequence' }
  ));
  
  my $record_menu = $self->create_submenu('ExternalRecords', 'External References');

  my $sim_node = $self->create_node('Similarity', 'General identifiers ([[counts::similarity_matches]])',
    [qw( similarity EnsEMBL::Web::Component::Transcript::SimilarityMatches )],
    { 'availability' => 'transcript has_similarity_matches', 'concise' => 'General identifiers' }
  );
  
  $sim_node->append($self->create_subnode('Similarity/Align', '',
   [qw( alignment EnsEMBL::Web::Component::Transcript::ExternalRecordAlignment )],
    { 'no_menu_entry' => 'transcript' }
  ));
  
  $record_menu->append($sim_node);
  
  $record_menu->append($self->create_node('Oligos', 'Oligo probes ([[counts::oligos]])',
    [qw( arrays EnsEMBL::Web::Component::Transcript::OligoArrays )],
    { 'availability' => 'transcript database:funcgen has_oligos', 'concise' => 'Oligo probes' }
  ));
  
  my $go_menu = $self->create_submenu('GO', 'Ontology ([[counts::go]])');
  $go_menu->append($self->create_node('Ontology/Image', 'Ontology graph ([[counts::go]])',
    [qw( go EnsEMBL::Web::Component::Transcript::Goimage )],
    { 'availability' => 'transcript has_go', 'concise' => 'Ontology graph' }
  ));

  $go_menu->append($self->create_node('Ontology/Table', 'Ontology table ([[counts::go]])',
    [qw( go EnsEMBL::Web::Component::Transcript::Go )],
    { 'availability' => 'transcript has_go', 'concise' => 'Ontology table' }
  ));

  my $var_menu = $self->create_submenu('Variation', 'Genetic Variation');
    
  $var_menu->append($self->create_node('Population', 'Population comparison',
    [qw( snptable EnsEMBL::Web::Component::Transcript::TranscriptSNPTable )],
    { 'availability' => 'strains database:variation core' }
  ));
  
  $var_menu->append($self->create_node('Population/Image', 'Comparison image',
    [qw( snps EnsEMBL::Web::Component::Transcript::SNPView )],
    { 'availability' => 'strains database:variation core' }
  ));
  
  my $prot_menu = $self->create_submenu('Protein', 'Protein Information');
  
  $prot_menu->append($self->create_node('ProteinSummary', 'Protein summary',
    [qw(
      image      EnsEMBL::Web::Component::Transcript::TranslationImage
      statistics EnsEMBL::Web::Component::Transcript::PepStats
    )],
    { 'availability' => 'either', 'concise' => 'Protein summary' }
  ));
  
  my $D = $self->create_node('Domains', 'Domains & features ([[counts::prot_domains]])',
    [qw( domains EnsEMBL::Web::Component::Transcript::DomainSpreadsheet )],
    { 'availability' => 'transcript has_domains', 'concise' => 'Domains & features' }
  );
  
  $D->append($self->create_subnode('Domains/Genes', 'Genes in domain',
    [qw( domaingenes EnsEMBL::Web::Component::Transcript::DomainGenes )],
    { 'availability' => 'transcript|domain', 'no_menu_entry' => 1 }
  ));
  
  $prot_menu->append($D);
  
  $prot_menu->append($self->create_node('ProtVariations', 'Variations ([[counts::prot_variations]])',
    [qw( protvars EnsEMBL::Web::Component::Transcript::ProteinVariations )],
    { 'availability' => 'either database:variation has_variations', 'concise' => 'Variations' }
  ));
  
  # External Data tree, including non-positional DAS sources
  my $external = $self->create_node('ExternalData', 'External Data',
    [qw( external EnsEMBL::Web::Component::Transcript::ExternalData )],
    { 'availability' => 'transcript' }
  );
  
  if ($self->hub->species_defs->ENSEMBL_LOGINS) {
    $external->append($self->create_node('UserAnnotation', 'Personal annotation',
      [qw( manual_annotation EnsEMBL::Web::Component::Transcript::UserAnnotation )],
      { 'availability' => 'logged_in transcript' }
    ));
  }
  
  my $history_menu = $self->create_submenu('History', 'ID History');
  
  $history_menu->append($self->create_node('Idhistory', 'Transcript history',
    [qw(
      display    EnsEMBL::Web::Component::Gene::HistoryReport
      associated EnsEMBL::Web::Component::Gene::HistoryLinked
      map        EnsEMBL::Web::Component::Gene::HistoryMap
    )],
    { 'availability' => 'history', 'concise' => 'ID History' }
  ));
  
  $history_menu->append($self->create_node('Idhistory/Protein', 'Protein history',
    [qw(
      display    EnsEMBL::Web::Component::Gene::HistoryReport/protein
      associated EnsEMBL::Web::Component::Gene::HistoryLinked/protein
      map        EnsEMBL::Web::Component::Gene::HistoryMap/protein
    )],
    { 'availability' => 'history_protein', 'concise' => 'ID History' }
  ));
  
  $self->create_subnode('Output', 'Export Transcript Data',
    [qw( export EnsEMBL::Web::Component::Export::Output )],
    { 'availability' => 'transcript', 'no_menu_entry' => 1 }
  );
}

1;

