# $Id: Gene.pm,v 1.225 2012-09-20 13:33:54 ma7 Exp $

package EnsEMBL::Web::Configuration::Gene;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}->{'default'} = $self->object ? $self->object->default_action : 'Summary';
}

sub user_tree { return 1; }

sub populate_tree {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  
  $self->create_node('Summary', 'Gene summary',
    [qw(
      summary     EnsEMBL::Web::Component::Gene::GeneSummary
      transcripts EnsEMBL::Web::Component::Gene::TranscriptsImage
    )],
    { 'availability' => 'gene', 'concise' => 'Gene summary' }
  );

  $self->create_node('Splice', 'Splice variants ([[counts::transcripts]])',
    [qw( image EnsEMBL::Web::Component::Gene::SpliceImage )],
    { 'availability' => 'gene has_transcripts', 'concise' => 'Splice variants' }
  );

  $self->create_node('Evidence', 'Supporting evidence',
    [qw( evidence EnsEMBL::Web::Component::Gene::SupportingEvidence )],
    { 'availability' => 'gene', 'concise' => 'Supporting evidence' }
  );

  $self->create_node('Sequence', 'Sequence',
    [qw( sequence EnsEMBL::Web::Component::Gene::GeneSeq )],
    { 'availability' => 'gene', 'concise' => 'Marked-up sequence' }
  );

  $self->create_node('Matches', 'External references',
    [qw( matches EnsEMBL::Web::Component::Gene::SimilarityMatches )],
    { 'availability' => 'gene has_similarity_matches', 'concise' => 'External references' }
  );

  $self->create_node('Regulation', 'Regulation',
    [qw(
      regulation EnsEMBL::Web::Component::Gene::RegulationImage
      features   EnsEMBL::Web::Component::Gene::RegulationTable
    )],
    { 'availability' => 'regulation not_patch' }
  );
  
  my $compara_menu = $self->create_node('Compara', 'Comparative Genomics',
    [qw(button_panel EnsEMBL::Web::Component::Gene::Compara_Portal)],
    {'availability' => 'gene database:compara core'}
  );
  
  $compara_menu->append($self->create_node('Compara_Alignments', 'Genomic alignments',
    [qw(
      selector   EnsEMBL::Web::Component::Compara_AlignSliceSelector
      alignments EnsEMBL::Web::Component::Gene::Compara_Alignments
    )],
    { 'availability' => 'gene database:compara core has_alignments' }
  ));
  
  my $tree_node = $self->create_node('Compara_Tree', 'Gene tree (image)',
    [qw( image EnsEMBL::Web::Component::Gene::ComparaTree )],
    { 'availability' => 'gene database:compara core has_gene_tree' }
  );
  
  $tree_node->append($self->create_subnode('Compara_Tree/Text', 'Gene tree (text)',
    [qw( treetext EnsEMBL::Web::Component::Gene::ComparaTree/text )],
    { 'availability' => 'gene database:compara core has_gene_tree' }
  ));
  
  $tree_node->append($self->create_subnode('Compara_Tree/Align', 'Gene tree (alignment)',
    [qw( treealign EnsEMBL::Web::Component::Gene::ComparaTree/align )],
    { 'availability' => 'gene database:compara core has_gene_tree' }
  ));
  
  $tree_node->append($self->create_node('SpeciesTree', 'Gene gain/loss tree',
      [qw( image EnsEMBL::Web::Component::Gene::SpeciesTree )],
      { 'availability' => 'gene database:compara core has_species_tree' }
    ));
  
  $compara_menu->append($tree_node);
    
  my $ol_node = $self->create_node('Compara_Ortholog', 'Orthologues ([[counts::orthologs]])',
    [qw( orthologues EnsEMBL::Web::Component::Gene::ComparaOrthologs )],
    { 'availability' => 'gene database:compara core has_orthologs', 'concise' => 'Orthologues' }
  );
  
  $ol_node->append($self->create_subnode('Compara_Ortholog/Alignment', 'Orthologue alignment',
    [qw( alignment EnsEMBL::Web::Component::Gene::HomologAlignment )],
    { 'availability'  => 'gene database:compara core has_orthologs', 'no_menu_entry' => 1 }
  ));
  
  $compara_menu->append($ol_node);
  
  my $pl_node = $self->create_node('Compara_Paralog', 'Paralogues ([[counts::paralogs]])',
    [qw(paralogues EnsEMBL::Web::Component::Gene::ComparaParalogs)],
    { 'availability' => 'gene database:compara core has_paralogs', 'concise' => 'Paralogues' }
  );
  
  $pl_node->append($self->create_subnode('Compara_Paralog/Alignment', 'Paralogue alignment',
    [qw( alignment EnsEMBL::Web::Component::Gene::HomologAlignment )],
    { 'availability' => 'gene database:compara core has_paralogs', 'no_menu_entry' => 1 }
  ));
  
  $compara_menu->append($pl_node);
  
  my $fam_node = $self->create_node('Family', 'Protein families ([[counts::families]])',
    [qw( family EnsEMBL::Web::Component::Gene::Family )],
    { 'availability' => 'family', 'concise' => 'Protein families' }
  );
  
  $fam_node->append($self->create_subnode('Family/Genes', uc($species_defs->get_config($hub->species, 'SPECIES_COMMON_NAME')) . ' genes in this family',
    [qw( genes EnsEMBL::Web::Component::Gene::FamilyGenes )],
    { 'availability'  => 'family', 'no_menu_entry' => 1 }
  ));
  
  $fam_node->append($self->create_subnode('Family/Proteins', 'Proteins in this family',
    [qw(
      ensembl EnsEMBL::Web::Component::Gene::FamilyProteins/ensembl
      other   EnsEMBL::Web::Component::Gene::FamilyProteins/other
    )],
    { 'availability'  => 'family database:compara core', 'no_menu_entry' => 1 }
  ));
  
  $fam_node->append($self->create_subnode('Family/Alignments', 'Multiple alignments in this family',
    [qw( jalview EnsEMBL::Web::Component::Gene::FamilyAlignments )],
    { 'availability'  => 'family database:compara core', 'no_menu_entry' => 1 }
  ));
  
  $compara_menu->append($fam_node);
  
	$self->create_node('Phenotype',  'Phenotype',
    [qw( phenotype EnsEMBL::Web::Component::Gene::GenePhenotype )],
    { 'availability' => 'phenotype' }
  );
	
  my $var_menu = $self->create_submenu('Variation', 'Genetic Variation');

  $var_menu->append($self->create_node('Variation_Gene/Table', 'Variation table',
    [qw( snptable EnsEMBL::Web::Component::Gene::VariationTable )],
    { 'availability' => 'gene database:variation core not_patch' }
  ));
  
  $var_menu->append($self->create_node('Variation_Gene/Image',  'Variation image',
    [qw( image EnsEMBL::Web::Component::Gene::VariationImage )],
    { 'availability' => 'gene database:variation core not_patch' }
  ));
	
	$var_menu->append($self->create_node('StructuralVariation_Gene', 'Structural variation',
    [qw(
      svimage EnsEMBL::Web::Component::Gene::SVImage
      svtable EnsEMBL::Web::Component::Gene::SVTable
    )],
    { 'availability' => 'gene has_structural_variation' }
  ));

  # External Data tree, including non-positional DAS sources
  my $external = $self->create_node('ExternalData', 'External data',
    [qw( external EnsEMBL::Web::Component::Gene::ExternalData )],
    { 'availability' => 'gene' }
  );
  
  if ($species_defs->ENSEMBL_LOGINS) {
    $external->append($self->create_node('UserAnnotation', 'Personal annotation',
      [qw( manual_annotation EnsEMBL::Web::Component::Gene::UserAnnotation )],
      { 'availability' => 'logged_in gene' }
    ));
  }
  
  my $history_menu = $self->create_submenu('History', 'ID History');
  
  $history_menu->append($self->create_node('Idhistory', 'Gene history',
    [qw(
      display    EnsEMBL::Web::Component::Gene::HistoryReport
      associated EnsEMBL::Web::Component::Gene::HistoryLinked
      map        EnsEMBL::Web::Component::Gene::HistoryMap
    )],
    { 'availability' => 'history', 'concise' => 'ID History' }
  ));
  
  $self->create_subnode('Output', 'Export Gene Data',
    [qw( export EnsEMBL::Web::Component::Export::Output )],
    { 'availability' => 'gene', 'no_menu_entry' => 1 }
  );
}

1;
