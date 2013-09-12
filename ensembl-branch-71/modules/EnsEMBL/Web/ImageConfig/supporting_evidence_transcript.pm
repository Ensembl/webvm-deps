# $Id: supporting_evidence_transcript.pm,v 1.21 2013-03-08 18:09:06 st3 Exp $

package EnsEMBL::Web::ImageConfig::supporting_evidence_transcript;

use strict;

use base qw(EnsEMBL::Web::ImageConfig);

sub init {
  my $self = shift;
  
  $self->set_parameters({
    label_width      => 115,
    opt_empty_tracks => 0,
  });

  $self->create_menus('TSE_transcript', 'splice_sites', 'evidence');
  
  $self->load_tracks;

  my $logic_name = '';;
  if ($self->hub->core_objects->{'transcript'}) {
    $logic_name = $self->hub->core_objects->{'transcript'}->Obj->analysis->logic_name;
  }
  my $is_vega_gene   = $self->hub->get_db eq 'vega'   ? 1 : $self->species_defs->ENSEMBL_SITETYPE eq 'Vega' ? 1 : 0;
  my $is_rnaseq_gene = $self->hub->get_db eq 'rnaseq' ? 1 : 0;

  $self->add_tracks('splice_sites', [ 'non_can_intron', 'Non-canonical splicing', 'non_can_intron', {
    display     => 'normal',
    strand      => 'r',
    colours     => $self->species_defs->colour('feature'),
    description => 'Non-canonical splice sites (ie not GT/AG, GC/AG, AT/AC or NN/NN)',
  }]);

  my $transcript_evi_desc = $is_vega_gene ? 'Alignments from the Havana pipeline that support the transcript' :  'Alignments used to build this transcript model';

  $self->add_tracks('evidence', [ 'TSE_generic_match', 'Transcript supporting evidence', 'TSE_generic_match', {
    display     => 'normal',
    strand      => 'r',
    colours     => $self->species_defs->colour('feature'),
    description => $transcript_evi_desc,
  }]);

  if (!$is_vega_gene) {
    if ($is_rnaseq_gene) {

      #configure intron supporting feature display
      $self->add_tracks('evidence', [ 'Supported_introns', 'Intron supporting evidence', 'TSE_intron_sf', {
        display              => 'normal',
        strand               => 'r',
        colours              => $self->species_defs->colour('feature'),
        description          => 'RNASeq reads that support the introns',
      }]);
    }
    else {
      $self->add_tracks('evidence', [ 'SE_generic_match', 'Exon supporting evidence (Ensembl)', 'SE_generic_match', {
        display              => 'normal',
        strand               => 'r',
        colours              => $self->species_defs->colour('feature'),
        description          => 'Alignments from the Ensembl pipeline that support the exons',
        logic_names_excluded => '_havana',
      }]);
    }

    if ($self->species_defs->HAVANA_DATAFREEZE_DATE) {
      $self->add_tracks('evidence', [ 'SE_generic_match_havana', 'Exon supporting evidence (Havana)', 'SE_generic_match', {
        display          => 'normal',
        strand           => 'r',
        colours          => $self->species_defs->colour('feature'),
        description      => 'Alignments from the Havana pipeline that support the exons',
        logic_names_only => '_havana',
      }]);
    }
  }
  $self->add_tracks('evidence',
                    [ 'TSE_background_exon', '', 'TSE_background_exon', {
                      display => 'normal',
                      strand  => 'r',
                      menu    => 'no',
                    }],
                    [ 'TSE_legend', 'Legend', 'TSE_legend', {
                      display => 'normal',
                      strand  => 'r',
                      colours => $self->species_defs->colour('feature'),
                      menu    => 'no',
                    }],
                  );


}

1;
