# $Id: Transcript.pm,v 1.236.2.1 2013-01-04 10:05:02 wm2 Exp $

package EnsEMBL::Web::Object::Transcript;

### NAME: EnsEMBL::Web::Object::Transcript
### Wrapper around a Bio::EnsEMBL::Transcript object  

### PLUGGABLE: Yes, using Proxy::Object 

### STATUS: At Risk
### Contains a lot of functionality not directly related to
### manipulation of the underlying API object 

### DESCRIPTION

use strict;

use Bio::EnsEMBL::Utils::TranscriptAlleles qw(get_all_ConsequenceType);
use Bio::EnsEMBL::Variation::Utils::Sequence qw(ambiguity_code variation_class);

use EnsEMBL::Web::Cache;
use Data::Dumper;
use base qw(EnsEMBL::Web::Object);

our $MEMD = EnsEMBL::Web::Cache->new;

sub availability {
  my $self = shift;
  
  if (!$self->{'_availability'}) {
    my $availability = $self->_availability;
    my $obj = $self->Obj;
    
    if ($obj->isa('EnsEMBL::Web::Fake')) {
      $availability->{$self->feature_type} = 1;
    } elsif ($obj->isa('Bio::EnsEMBL::ArchiveStableId')) { 
      $availability->{'history'} = 1;
      my $trans_id = $self->param('p') || $self->param('protein'); 
      my $trans = scalar @{$obj->get_all_translation_archive_ids};
      $availability->{'history_protein'} = 1 if $trans_id || $trans >= 1;
    } elsif( $obj->isa('Bio::EnsEMBL::PredictionTranscript') ) {
      $availability->{'either'} = 1;
    } else {
      my $counts = $self->counts;
      my $rows   = $self->table_info($self->get_db, 'stable_id_event')->{'rows'};
      
      $availability->{'history'}         = !!$rows;
      $availability->{'history_protein'} = !!$rows;
      $availability->{'core'}            = $self->get_db eq 'core';
      $availability->{'either'}          = 1;
      $availability->{'transcript'}      = 1;
      $availability->{'domain'}          = 1;
      $availability->{'translation'}     = !!$obj->translation;
      $availability->{'strains'}         = !!$self->species_defs->databases->{'DATABASE_VARIATION'}->{'#STRAINS'} if $self->species_defs->databases->{'DATABASE_VARIATION'};
      $availability->{'history_protein'} = 0 unless $self->translation_object;
      $availability->{'has_variations'}  = $counts->{'prot_variations'};
      $availability->{'has_domains'}     = $counts->{'prot_domains'};
      $availability->{"has_$_"}          = $counts->{$_} for qw(exons evidence similarity_matches oligos go);
    }
  
    $self->{'_availability'} = $availability;
  }
  
  return $self->{'_availability'};
}

sub default_action { return $_[0]->Obj->isa('Bio::EnsEMBL::ArchiveStableId') ? 'Idhistory' : 'Summary'; }

sub counts {
  my $self = shift;
  my $sd = $self->species_defs;

  my $key = sprintf(
    '::COUNTS::TRANSCRIPT::%s::%s::%s::', 
    $self->species, 
    $self->hub->core_param('db'), 
    $self->hub->core_param('t')
  );
  
  my $counts = $self->{'_counts'};
  $counts ||= $MEMD->get($key) if $MEMD;

  if (!$counts) {
    return unless $self->Obj->isa('Bio::EnsEMBL::Transcript');
    
    $counts = {
      exons              => scalar @{$self->Obj->get_all_Exons},
      evidence           => $self->count_supporting_evidence,
      similarity_matches => $self->count_similarity_matches,
      oligos             => $self->count_oligos,
      prot_domains       => $self->count_prot_domains,
      prot_variations    => $self->count_prot_variations,
      go                 => $self->count_go,
      %{$self->_counts}
    };
    
    $MEMD->set($key, $counts, undef, 'COUNTS') if $MEMD;
    $self->{'_counts'} = $counts;
  }

  return $counts;
}

sub count_prot_domains {
  my $self = shift;
  return 0 unless $self->translation_object;
  my $c = 0;
  my $analyses = $self->table_info($self->get_db, 'protein_feature')->{'analyses'} || {};
  #my @domain_keys = grep { $analyses->{$_}{'web'}{'type'} eq 'domain' } keys %$analyses;
  my @domain_keys = keys %$analyses;
  $c += map { @{$self->translation_object->get_all_ProteinFeatures($_)} } @domain_keys;
  return $c;
}

sub count_prot_variations {
  my $self = shift;
  return 0 unless $self->species_defs->databases->{'DATABASE_VARIATION'};
  return scalar grep $_->translation_start, @{$self->get_transcript_variations};
}

sub count_supporting_evidence {
  my $self = shift;
  my $type = $self->get_db;
  my $ln   = $self->logic_name;
  my $dbc = $self->database($type)->dbc;
  my %all_evidence;
  my $sql = '
    SELECT feature_type, feature_id 
      FROM transcript_supporting_feature 
     WHERE transcript_id = ?';
     
  my $sth = $dbc->prepare($sql);
  $sth->execute($self->Obj->dbID);
  
  while (my ($type, $feature_id) = $sth->fetchrow_array) {
    $all_evidence{$type}{$feature_id}++;
  }

  unless ($ln =~ /otter/) {
    $sql = '
      SELECT feature_type, feature_id
        FROM supporting_feature sf, exon_transcript et
       WHERE et.exon_id = sf.exon_id
         AND et.transcript_id = ?';
    $sth = $dbc->prepare($sql);
    $sth->execute($self->Obj->dbID);

    while (my ($type, $feature_id) = $sth->fetchrow_array) {
      $all_evidence{$type}{$feature_id}++;
    };
  }

  my %names = (
    'dna_align_feature'     => 'dna_align_feature_id',
    'protein_align_feature' => 'protein_align_feature_id'
  );
  
  my %hits;
  my $dbh = $dbc->db_handle;
  
  while (my ($evi_type, $hits) = each %all_evidence) {
    foreach my $hit_id (keys %$hits) {
      my $type = $names{$evi_type};
      my ($hit_name) = $dbh->selectrow_array("SELECT hit_name FROM $evi_type where $type = $hit_id");
      $hits{$hit_name}++
    }
  }
  
  return scalar keys %hits;
}

sub count_similarity_matches {
  my $self = shift;
  my $type = $self->get_db;
  my $dbc = $self->database($type)->dbc;
  my %all_xrefs;
  # xrefs on the transcript
  my $sql1 = qq{
    SELECT x.display_label, edb.db_name, edb.type, edb.status
      FROM transcript t, object_xref ox, xref x, external_db edb
     WHERE t.transcript_id = ox.ensembl_id
       AND ox.xref_id = x.xref_id
       AND x.external_db_id = edb.external_db_id
       AND ox.ensembl_object_type = 'Transcript'
       AND t.transcript_id = ?};

  my $sth = $dbc->prepare($sql1);
  $sth->execute($self->Obj->dbID);
  
  while (my ($label, $db_name, $type, $status) = $sth->fetchrow_array) {
    my $key = $db_name.$label;
    $all_xrefs{'transcript'}{$key} = { 'id' => $label, 'db_name' => $db_name, 'type' => $type, 'status' => $status };
  }

  # xrefs on the translation
  my $sql2 = qq{
    SELECT x.display_label, edb.db_name, edb.type, edb.status
      FROM translation tl, object_xref ox, xref x, external_db edb
     WHERE tl.translation_id = ox.ensembl_id
       AND ox.xref_id = x.xref_id
       AND x.external_db_id = edb.external_db_id
       AND ox.ensembl_object_type = 'Translation'
       AND tl.transcript_id = ?};
  $sth = $dbc->prepare($sql2);
  $sth->execute($self->Obj->dbID);
  
  while (my ($label, $db_name, $type, $status) = $sth->fetchrow_array) {
    my $key = $db_name.$label;
    $all_xrefs{'translation'}{$key} = { 'id' => $label, 'db_name' => $db_name, 'type' => $type, 'status' => $status };
  }

  # filter out what isn't shown on the 'External References' page
  my @counted_xrefs;
  foreach my $t (qw(transcript translation)) {
    my $xrefs = $all_xrefs{$t};
    while (my ($key,$det) = each %$xrefs) { 
      next unless (grep {$det->{'type'} eq $_} qw(MISC PRIMARY_DB_SYNONYM)); 
      # these filters are taken directly from Component::_sort_similarity_links
      # code duplication needs removing, and some of these may well not be needed any more
      next if $det->{'status'} eq 'ORTH';                        # remove all orthologs
      next if lc $det->{'db_name'} eq 'medline';                 # ditch medline entries - redundant as we also have pubmed
      next if $det->{'db_name'} =~ /^flybase/i && $det->{'id'} =~ /^CG/;  # Ditch celera genes from FlyBase
      next if $det->{'db_name'} eq 'Vega_gene';                  # remove internal links to self and transcripts
      next if $det->{'db_name'} eq 'Vega_transcript';
      next if $det->{'db_name'} eq 'Vega_translation';
      next if $det->{'db_name'} eq 'GO';
      next if $det->{'db_name'} eq 'goslim_goa';
      next if $det->{'db_name'} eq 'OTTP' && $det->{'display_label'} =~ /^\d+$/; #ignore xrefs to vega translation_ids
      push @counted_xrefs, $key;
    }
  }
  
  return scalar @counted_xrefs;
}

sub count_oligos {
  my $self = shift;
  my $type = 'funcgen';
  return 0 unless $self->database('funcgen');
  my $dbc = $self->database($type)->dbc; 
  my $sql = qq{
   SELECT count(distinct(ox.ensembl_id))
     FROM object_xref ox, xref x, external_db edb
    WHERE ox.xref_id = x.xref_id
      AND x.external_db_id = edb.external_db_id
      AND (ox.ensembl_object_type = 'ProbeSet'
           OR ox.ensembl_object_type = 'Probe')
      AND x.info_text = 'Transcript'
      AND x.dbprimary_acc = ?};
      
  my $sth = $dbc->prepare($sql); 
  $sth->execute($self->Obj->stable_id);
  my $c = $sth->fetchall_arrayref->[0][0];
  return $c;
}

sub count_go {
  my $self = shift;
  return 0 unless $self->Obj->translation;
  my $type = $self->get_db;
  my $dbc = $self->database($type)->dbc;
  my $tl_dbID = $self->Obj->translation->dbID; 

  # First get the available ontologies
  if (my @ontologies = @{$self->species_defs->SPECIES_ONTOLOGIES || []}) {
      my $ontologies_list = scalar(@ontologies) > 1 ? qq{ in ('}.(join "\', \'", @ontologies).qq{' ) } : qq{ ='$ontologies[0]' };

      my $sql = qq{
       SELECT count(distinct(x.display_label))
           FROM object_xref ox, xref x, external_db edb
           WHERE ox.xref_id = x.xref_id
           AND x.external_db_id = edb.external_db_id
           AND edb.db_name $ontologies_list 
           AND ox.ensembl_object_type = ?
           AND ox.ensembl_id = ?};

      # Count the ontology terms mapped to the translation
      my $sth = $dbc->prepare($sql);
      $sth->execute('Translation', $self->transcript->translation->dbID);
      my $c = $sth->fetchall_arrayref->[0][0];

      # Add those mapped to the transcript
      $sth->execute('Transcript', $self->transcript->dbID);
      $c += $sth->fetchall_arrayref->[0][0];

      return $c;
  }
  return;
}


sub default_track_by_gene {
  my $self = shift;
  my $db    = $self->get_db;
  my $logic = $self->logic_name;

  my %mappings_db_ln = (
   'core' => {
      map( {( $_, $_ )} qw( 
        genscan fgenesh genefinder snap ciona_snap augustus
        gsc gid slam gws_h gws_s )
      ),
      map( {($_, $_.'_transcript')} qw(
        vectorbase tigr_0_5 species_protein human_one2one_mus_orth mus_one2one_human_orth
        human_one2one_mouse_cow_orth
        cdna_all targettedgenewise human_ensembl_proteins
        medaka_protein gff_prediction oxford_fgu platypus_olfactory_receptors
        genebuilderbeeflymosandswall gsten flybase wormbase
        ensembl sgd homology_low cow_proteins refseq mouse_protein dog_protein horse_protein
        jamboree_cdnas ciona_dbest_ncbi ciona_est_seqc ciona_est_seqn organutan_protein
        ciona_est_seqs ciona_jgi_v1 ciona_kyotograil_2004
        ensembl_projection ensembl_segment fugu_protein lamprey_protein
        ciona_kyotograil_2005 )
      ),
      qw(
        rodent_protein   rprot_transcript
        hox              gsten_transcript
        cyt              gsten_transcript
        ncrna            rna_transcript
        mirna            rna_transcript
        trna             rna_transcript
        rrna             rna_transcript
        snrna            rna_transcript
        snlrna           rna_transcript
        snorna           rna_transcript
        ensembl_ncrna    erna_transcript
        homology_medium  homology_low_transcript
        homology_high    homology_low_transcript
        beeprotein       homology_low_transcript
        otter            vega_transcript
      )
    },
    'otherfeatures' => { 
      qw(
        oxford_fgu oxford_fgu_ext_transcript
        estgene est_transcript 
      ), 
      map ({($_, $_.'_transcript')} qw(
        singapore_est singapore_protein chimp_cdna chimp_est human_est human_cdna
        medaka_transcriptcoalescer medaka_genome_project
      ))
    },
    'vega' => {
      otter          => 'evega_transcript',
      otter_external => 'evega_external_transcript',
    }
  );

  return lc($logic).'_transcript' if $db eq 'otherfeatures' && lc($logic) =~ /^singapore_(est|protein)$/;
  return $mappings_db_ln{lc $db}{lc $logic} || 'ensembl_transcript';
}

sub short_caption {
  my $self = shift;
   
  return 'Transcript-based displays' unless shift eq 'global';
  return ucfirst($self->Obj->type) . ': ' . $self->Obj->stable_id if $self->Obj->isa('EnsEMBL::Web::Fake');
  
  my $dxr   = $self->Obj->can('display_xref') ? $self->Obj->display_xref : undef;
  my $label = $dxr ? $dxr->display_id : $self->Obj->stable_id;
  
  return length $label < 15 ? "Transcript: $label" : "Trans: $label" if($label);    
}

sub caption {
  my $self = shift;
  my $heading = $self->type_name.': ';
  my $subhead;

  my( $disp_id ) = $self->display_xref;
  if( $disp_id && $disp_id ne $self->stable_id ) {
    $heading .= $disp_id;
    $subhead = $self->stable_id;
  }
  else {
    $heading .= $self->stable_id;
  }

  return [$heading, $subhead];
}


sub type_name {
  my $self = shift;
  return $self->Obj->isa('EnsEMBL::Web::Fake') ? ucfirst $self->Obj->type : $self->species_defs->translate('Transcript');
}

sub transcript             { return $_[0]->Obj; }
sub source                 { return $_[0]->gene ? $_[0]->gene->source : undef; }
sub stable_id              { return $_[0]->Obj->stable_id;  }
sub feature_type           { return $_[0]->Obj->type;       }
sub version                { return $_[0]->Obj->version;    }
sub logic_name             { return $_[0]->gene ? $_[0]->gene->analysis->logic_name : $_[0]->Obj->analysis->logic_name; }
sub status                 { return $_[0]->Obj->status;  }
sub display_label          { return $_[0]->Obj->analysis->display_label || $_[0]->logic_name; }
sub coord_system           { return $_[0]->Obj->slice->coord_system->name; }
sub seq_region_type        { return $_[0]->coord_system; }
sub seq_region_name        { return $_[0]->Obj->slice->seq_region_name; }
sub seq_region_start       { return $_[0]->Obj->start; }
sub seq_region_end         { return $_[0]->Obj->end; }
sub seq_region_strand      { return $_[0]->Obj->strand; }
sub feature_length         { return $_[0]->Obj->feature_Slice->length; }
sub get_latest_incarnation { return $_[0]->Obj->get_latest_incarnation; }

# Returns a hash of family information and associated (API) Gene objects
# N.B. moved various bits from Translation and Family objects
sub get_families {
  my $self = shift;
  my $cdb = shift || 'compara';
  my $databases = $self->database($cdb);

  # get taxon_id
  my $taxon_id;
  eval {
    my $meta = $self->database('core')->get_MetaContainer;
    $taxon_id = $meta->get_taxonomy_id;
  };
  
  if ($@) {
    warn $@; 
    return {};
  }

  # create family object
  my $family_adaptor;
  eval {
    $family_adaptor = $databases->get_FamilyAdaptor
  };
  
  if ($@) {
    warn $@; 
    return {};
  }
  
  my $families = [];
  my $translation = $self->translation_object;
  
  eval {
    $families = $family_adaptor->fetch_by_Member_source_stable_id('ENSEMBLPEP',$translation->stable_id)
  };

  # munge data
  my $family_hash = {};
  
  if (@$families) {
    my $ga = $self->database('core')->get_GeneAdaptor;
    
    foreach my $family (@$families) {
      $family_hash->{$family->stable_id} = {
        'description' => $family->description,
        'count'       => $family->Member_count_by_source_taxon('ENSEMBLGENE', $taxon_id),
        'genes'       => [ map { $ga->fetch_by_stable_id($_->stable_id) } @{$family->get_Member_by_source_taxon('ENSEMBLGENE', $taxon_id) || []} ],
      };
    }
  }
  
  return $family_hash;
}

sub get_frameshift_introns {
  my $self               = shift;
  my $transcript_attribs = $self->Obj->get_all_Attributes('Frameshift'); 
  my $link               = $self->hub->url({ type => 'Transcript', action => 'Exons', t => $self->Obj->stable_id });
  my %unique             = map { $_->value => $link } @$transcript_attribs;
  my $frameshift_introns;
  
  foreach (sort { $a <=> $b } keys %unique) {
    my $url       = $unique{$_};
    my $link_text = qq{<a href="$url">$_</a>};
    $frameshift_introns .= "$link_text, ";
  }
  
  $frameshift_introns =~ s/,\s+$//;
  
  return $frameshift_introns;
}

sub get_domain_genes {
  my $self = shift;
  my $a = $self->gene ? $self->gene->adaptor : $self->Obj->adaptor;
  return $a->fetch_all_by_domain($self->param('domain')); 
}

sub get_Slice {
  my ($self, $context, $ori, $slice) = @_;
  
  $slice ||= $self->gene->feature_Slice;
  
  if ($context =~ /(\d+)%/) {
    $context = $slice->length * $1 / 100;
  }
  
  if ($ori && $slice->strand != $ori) {
    $slice = $slice->invert;
  }
  
  return $slice->expand($context, $context);
}

#-- Transcript SNP view -----------------------------------------------

sub get_transcript_Slice {
  my $self = shift;
  return $self->get_Slice(@_, $self->Obj->feature_Slice);
}

 # Args        : Web user config, arrayref of slices (see example)
 # Example     : my $slice = $object->get_Slice( $wuc, ['context', 'normal', '500%'] );
 # Description : Gets slices for transcript sample view
 # Returns  hash ref of slices
sub get_transcript_slices {
  my ($self, $slice_config) = @_;
  
  # name, normal/munged, zoom/extent
  if ($slice_config->[1] eq 'normal') {
    my $slice = $self->get_transcript_Slice($slice_config->[2], 1);
    return [ 'normal', $slice, [], $slice->length ];
  } else {
    return $self->get_munged_slice($slice_config->[0], $slice_config->[2], 1);
  }
}

# TSV/TSE
sub get_munged_slice {
  my $self          = shift;
  my $config_name   = shift;
  my $master_config = $self->get_imageconfig($config_name eq 'tsv_transcript' ? 'transcript_population' : $config_name);
  my $slice         = $self->get_transcript_Slice(@_); # pushes it onto forward strand, expands if necc.
  my $length        = $slice->length;
  my $munged        = '0' x $length;                   # Munged is string of 0, length of slice
  my $extent        = $self->param('context');         # Context is the padding around the exons in the fake slice
  my @lengths;
  
  if ($extent eq 'FULL') {
    $extent = 1000;
    @lengths = ($length);
  } else {
    foreach my $exon (@{$self->Obj->get_all_Exons}) {                
      my $start       = $exon->start - $slice->start + 1 - $extent;
      my $exon_length = $exon->end   - $exon->start  + 1 + 2 * $extent;
      # Change munged to 1 where there is exon or extent (i.e. flank)
      substr($munged, $start - 1, $exon_length) = '1' x $exon_length;
    }
    
    @lengths = map length $_, split /(0+)/, $munged;
  }
  
  # @lengths contains the sizes of gaps and exons(+/- context)

  $munged = undef;

  my $collapsed_length = 0;
  my $flag             = 0;
  my $subslices        = [];
  my $pos              = 0;

  foreach (@lengths, 0) {
    if ($flag = 1 - $flag) {
      push @$subslices, [ $pos + 1, 0, 0 ];
      $collapsed_length += $_;
    } else {
      $subslices->[-1][1] = $pos;
    }
    
    $pos += $_;
  }
  
  # compute the width of the slice image within the display
  my $pixel_width =
    ($master_config->get_parameter('image_width') || 800) - 
    ($master_config->get_parameter('label_width') || 100) -
    ($master_config->get_parameter('margin')      ||   5) * 3;

  # Work out the best size for the gaps between the "exons"
  my $fake_intron_gap_size = 11;
  my $intron_gaps          = $#lengths / 2;
  
  if ($intron_gaps && ($intron_gaps * $fake_intron_gap_size > $pixel_width * 0.75)) {
    $fake_intron_gap_size = int($pixel_width * 0.75 / $intron_gaps);
  }

  # Compute how big this is in base-pairs
  my $exon_pixels    = $pixel_width - $intron_gaps * $fake_intron_gap_size;
  my $scale_factor   = $collapsed_length / $exon_pixels;
  my $padding        = int($scale_factor * $fake_intron_gap_size) + 1;
  $collapsed_length += $padding * $intron_gaps;

  # Compute offset for each subslice
  my $start = 0;
  
  foreach (@$subslices) {
    $_->[2] = $start - $_->[0];
    $start += $_->[1] - $_->[0] - 1 + $padding;
  }
  
  return [ 'munged', $slice, $subslices, $collapsed_length ];
}

# Description: Valid user selections
# Returns hashref
sub valids {
  my $self = shift;
  my %valids = (); # Now we have to create the snp filter
  
  foreach ($self->param) {
    $valids{$_} = 1 if $_ =~ /opt_/ && $self->param($_) eq 'on';
  }
  
  return \%valids;
}

sub extent {
  my $self = shift;
  my $extent = $self->param('context');
  $extent = 5000 if $extent eq 'FULL';
  return $extent;
}

sub getFakeMungedVariationsOnSlice {
  my ($self, $slice, $subslices) = @_;
  
  my $sliceObj = $self->new_object(
    'Slice', $slice, $self->__data
  );

  my ($count_snps, $filtered_snps, $context_count) = $sliceObj->getFakeMungedVariationFeatures($subslices);
  $self->__data->{'sample'}{'snp_counts'} = [ $count_snps, scalar @$filtered_snps ];
  return ($count_snps, $filtered_snps, $context_count);
}

sub getAllelesConsequencesOnSlice {
  my ($self, $sample, $key, $sample_slice) = @_;
 
  # If data already calculated, return
  my $allele_info  = $self->__data->{'sample'}{$sample}->{'allele_info'};  
  my $consequences = $self->__data->{'sample'}{$sample}->{'consequences'};    
  return ($allele_info, $consequences) if $allele_info && $consequences;
  
  # Else
  my $valids = $self->valids;  

  # Get all features on slice
  my $allele_features = $sample_slice->get_all_AlleleFeatures_Slice(1) || []; 
  return ([], []) unless @$allele_features;

  my @filtered_af =
    sort { $a->[2]->start <=> $b->[2]->start }
    grep { $valids->{'opt_class_' . lc($self->var_class($_->[2]))} }                           # [ fake_s, fake_e, AF ] Filter our unwanted classes
    grep { scalar map { $valids->{'opt_' . lc $_} ? 1 : () } @{$_->[2]->get_all_sources} } # [ fake_s, fake_e, AF ] Filter our unwanted sources
    map  { $_->[1] ? [ $_->[0]->start + $_->[1], $_->[0]->end + $_->[1], $_->[0] ] : () }  # [ fake_s, fake_e, AlleleFeature ] Filter out AFs not on munged slice
    map  {[ $_, $self->munge_gaps($key, $_->start, $_->end) ]}                             # [ AF, offset ] Map to fake coords. Create a munged version AF
    @$allele_features;
  
  return ([], []) unless @filtered_af;

  # consequences of AlleleFeatures on the transcript
  my @slice_alleles = map { $_->[2]->transfer($self->Obj->slice) } @filtered_af;

  push @$consequences, $_->get_all_TranscriptVariations([$self->Obj])->[0] foreach @slice_alleles;
  return ([], []) unless @$consequences;
  
  # this is a hack, there's an issue with weakening to avoid circular
  # references in VariationFeature that causes the reference to the VF to be
  # garbage collected, so we make a copy here such that we can still get to it
  # later
  $_->{_cache_variation_feature} = $_->variation_feature foreach @$consequences;

  my @valid_conseq;
  my @valid_alleles;

  #foreach (sort {$a->start <=> $b->start} @$consequences) { # conseq on our transcript
  foreach (@$consequences) { # conseq on our transcript
    #my $last_af =  $valid_alleles[-1];
    #my $allele_feature;
    #
    #if ($last_af && $last_af->[2]->start eq $_->start) {
    #  $allele_feature = $last_af;
    #} else {
    #  $allele_feature = shift @filtered_af;
    #}
    
	my $allele_feature = shift @filtered_af;
    #next unless $allele_feature;
	
    foreach my $type (@{$_->consequence_type || []}) {
      next unless $valids->{'opt_' . lc $type};
      warn "Allele undefined for ", $allele_feature->[2]->variation_name . "\n" unless $allele_feature->[2]->allele_string;
	  
      # [ fake_s, fake_e, SNP ]   Filter our unwanted consequences
      push @valid_conseq,  $_;
      push @valid_alleles, $allele_feature;
      last;
    }
  }
  
  $self->__data->{'sample'}{$sample}->{'consequences'} = \@valid_conseq  || [];
  $self->__data->{'sample'}{$sample}->{'allele_info'}  = \@valid_alleles || [];
  
  return (\@valid_alleles, \@valid_conseq);
}

sub var_class {
  my ($self, $allele) = @_;
  my $allele_string = join '|', $allele->ref_allele_string, $allele->allele_string;
  return variation_class($allele_string);
}

sub ambig_code {
  my ($self, $allele) = @_;
  my $allele_string = join '|', $allele->ref_allele_string, $allele->allele_string;
  return ambiguity_code($allele_string);
}

# Arg (optional) : type string
#  -"default": returns samples checked by default
#  -"display": returns samples for dropdown list with default ones first
# Description: returns selected samples (by default)
# Returns type list
sub get_samples {
  my $self         = shift;
  my $options      = shift;
  my $params       = shift;
  my $hub          = $self->hub;
  my $vari_adaptor = $self->Obj->adaptor->db->get_db_adaptor('variation');
  
  unless ($vari_adaptor) {
    warn "ERROR: Can't get variation adaptor";
    return ();
  }

  my $individual_adaptor = $vari_adaptor->get_IndividualAdaptor;
 
  if ($options eq 'default') {
    return sort @{$individual_adaptor->get_default_strains};
  }

  my %default_pops; 
  map { $default_pops{$_} = 1 } @{$individual_adaptor->get_default_strains};
 
  my %db_pops;
  
  foreach (sort @{$individual_adaptor->get_display_strains}) {
    next if $default_pops{$_}; 
    $db_pops{$_} = 1;
  }

  my %configured_pops = (%default_pops, %db_pops);
  my @pops;
  
  if ($options eq 'display') { # return list of pops with default first
    return (sort keys %default_pops), (sort keys %db_pops); 
  } elsif ($params) {
    @pops = grep $configured_pops{$_}, sort keys %$params;
  } else { # get configured samples 
    foreach (sort grep /opt_pop_/, $hub->param) {
      (my $sample = $_) =~ s/opt_pop_//;
      push @pops, $sample if $configured_pops{$sample} && $hub->param($_) eq 'on';
    }
  }
  
  return sort @pops;
}

# TSV and SE
sub munge_gaps {
  my ($self, $slice_code, $bp, $bp2) = @_;
  my $subslices = $self->__data->{'slices'}{$slice_code}[2];
  
  unless ($subslices) {
    my $tmp =  $self->get_transcript_slices([ $slice_code, 'munged', $self->extent ]);
    $subslices = $tmp->[2];
  }
  
  foreach (@$subslices) {
    if ($bp >= $_->[0] && $bp <= $_->[1]) {
      my $return = defined($bp2) && ($bp2 < $_->[0] || $bp2 > $_->[1]) ? undef : $_->[2];
      return $return;
    }
  }
  
  return undef;
}

sub munge_gaps_split {
  my ($self, $slice_code, $bp, $bp2, $obj_ref) = @_;
  my $subslices = $self->__data->{'slices'}{$slice_code}[2];
  my @return = ();
  
  foreach (@$subslices) {
    my ($st, $en);
    
    if ($bp < $_->[0]) {
      $st = $_->[0];
    } elsif ($bp <= $_->[1]) {
      $st = $bp;
    } else {
      next;
    }
    
    if($bp2 > $_->[1]) {
      $en = $_->[1];
    } elsif ($bp2 >= $_->[0]) {
      $en = $bp2;
    } else {
      last;
    }
    
    if (defined $st && defined $en) {
      push @return, [ $st + $_->[2], $en + $_->[2], $obj_ref ];
    }
  }
  
  return @return;
}

sub read_coverage {
  my ($self, $sample, $sample_slice) = @_;

  my $individual_adaptor = $self->Obj->adaptor->db->get_db_adaptor('variation')->get_IndividualAdaptor; 
  my $sample_objs = $individual_adaptor->fetch_all_by_name($sample);
  return ([], []) unless @$sample_objs; 
  my $sample_obj = $sample_objs->[0]; 

  my $rc_adaptor = $self->Obj->adaptor->db->get_db_adaptor('variation')->get_ReadCoverageAdaptor; 
  my $coverage_level = $rc_adaptor->get_coverage_levels; 
  my $coverage_obj = $rc_adaptor->fetch_all_by_Slice_Sample_depth($sample_slice, $sample_obj); 
  return ($coverage_level, $coverage_obj);
}

sub munge_read_coverage {
  my ($self, $coverage_obj) = @_;
  
  my @filtered_obj =
    sort { $a->[2]->start <=> $b->[2]->start }
    map  { $self->munge_gaps_split('tsv_transcript', $_->start, $_->end, $_) }
    @$coverage_obj;
    
  return  \@filtered_obj;
}

#-- end transcript SNP view ----------------------------------------------

=head2 gene

 Arg[1]      : Bio::EnsEMBL::Gene - (OPTIONAL)
 Example     : $ensembl_gene = $transdata->gene
               $transdata->gene( $ensembl_gene )
 Description : returns the ensembl gene object if it exists on the transcript object
                else it creates it from the core-api. Alternativly a ensembl gene object
                reference can be passed to the function if the transcript is being created
                via a gene and so saves on creating a new gene object.
 Return type : Bio::EnsEMBL::Gene

=cut

sub gene {
  my $self = shift;
  
  if (@_) {
    $self->{'_gene'} = shift;
  } elsif (!$self->{'_gene'}) {
    eval {
      my $db = $self->get_db;
      my $adaptor_call = $self->param('gene_adaptor') || 'get_GeneAdaptor';
      my $GeneAdaptor = $self->database($db)->$adaptor_call;
      my $Gene = $GeneAdaptor->fetch_by_transcript_stable_id($self->stable_id);   
      $self->{'_gene'} = $Gene if $Gene;
    };
  }
  
  return $self->{'_gene'};
}

=head2 translation_object

 Arg[1]      : none
 Example     : $ensembl_translation = $transdata->translation
 Description : returns the ensembl translation object if it exists on the transcript object
                else it creates it from the core-api.
 Return type : Bio::EnsEMBL::Translation

=cut

sub translation_object {
  my $self = shift;
  
  unless (exists $self->{'data'}{'_translation'}) {
    my $translation = $self->transcript->translation;
    
    if ($translation) {
      my $translationObj = $self->new_object(
        'Translation', $translation, $self->__data
      );
      $translationObj->gene($self->gene);
      $translationObj->transcript($self->transcript);
      $self->{'data'}{'_translation'} = $translationObj;
    } else {
      $self->{'data'}{'_translation'} = undef;
    }
  }
  
  return $self->{'data'}{'_translation'};
}

=head2 db_type

 Arg[1]      : none
 Example     : $type = $transdata->db_type
 Description : Gets the db type of ensembl feature
 Return type : string a db type (EnsEMBL, Vega, EST, etc.)

=cut

sub db_type {
  my $self = shift;
  my $db   = $self->get_db;
  my %db_hash = qw(
    core           Ensembl
    otherfeatures  EST
    vega           Vega
  );
  
  return $db_hash{$db};
}

sub gene_type {
  my $self = shift;
  my $db = $self->get_db;
  my $type = '';
  $type = $self->Obj->status.' '.$self->Obj->biotype;
  $type =~ s/_/ /;
  $type ||= $self->display_label;
  $type ||= $self->db_type;
  $type ||= $db;
  $type = ucfirst $type if $type !~ /[A-Z]/; # All lc, so format
  return $type;
} 

sub gene_stat_and_biotype {
  my $self = shift;
  my $db = $self->get_db;
  my $type = '';
  
  if ($db eq 'core') {
    $type = ucfirst(lc $self->gene->status) . ' ' . $self->gene->biotype;
    $type ||= $self->db_type;
  } elsif ($db eq 'vega') {
    my $biotype = ($self->gene->biotype eq 'tec') ? uc $self->gene->biotype : $self->gene->biotype;
    $type = ucfirst(lc $self->gene->status) . " $biotype";
    $type =~ s/unknown //i;
    return $type;
  } else {
    $type = $self->logic_name;
    if ($type =~/^(proj|assembly_patch)/ ){
      $type = ucfirst(lc($self->Obj->status))." ".$self->Obj->biotype;
    }
    $type =~ s/^ccds/CCDS/;
  }
  $type ||= $db;
  $type =~ s/_/ /g;
  $type = ucfirst $type if $type !~ /[A-Z]/; # All lc, so format
  $type =~ s/^Est/EST/;
  
  return $type;
}

sub analysis {
  my $self = shift;
  return $self->gene ? $self->gene->analysis : $self->transcript->analysis
}

sub get_author_name {
  my $self = shift;
  my $attribs = $self->gene->get_all_Attributes('author');
  
  if (@$attribs) {
    return $attribs->[0]->value;
  } else {
    return undef;
  }
}

sub transcript_type {
  my $self = shift;
  my $db = $self->get_db;
  my $type = '';
  
  if (ref $self->Obj eq 'Bio::EnsEMBL::PredictionTranscript') {
    return '';
  } elsif ($db !~ /core|vega/i) {
    return '';
  } else {
    $type = ucfirst(lc $self->Obj->status) . ' ' . $self->Obj->biotype;
    $type =~ s/_/ /g;
    return $type;
  }
}

sub transcript_class {
  my $self = shift;
  my $class = ucfirst(lc $self->Obj->status) . ' ' . $self->Obj->biotype;
  $class =~ s/_/ /g;
  $class =~ s/unknown//i;
  return $class;
}

sub retrieve_remarks {
  my $self = shift;
  my @remarks = map { $_->value } @{ $self->Obj->get_all_Attributes('remark') };
  foreach my $attrib_code qw(cds_start_NF cds_end_NF mRNA_start_NF mRNA_end_NF) {
    push @remarks, map {$_->name} grep {$_->value} @{ $self->Obj->get_all_Attributes($attrib_code) };
  }
  return \@remarks;
}


=head2 trans_description

 Arg[1]      : none
 Example     : $description = $transdata->trans_description
 Description : Gets the description from the GENE object (no description on transcript)
 Return type : string
                The description of a feature

=cut

sub trans_description {
  my $gene = $_[0]->gene;
  my %description_by_type = ( 'bacterial_contaminant' => 'Probable bacterial contaminant' );
  
  if ($gene) {
    return $gene->description || $description_by_type{$gene->biotype} || 'No description';
  }
  
  return 'No description';
}

=head2 display_xref

 Arg[1]      : none
 Example     : ($xref_display_id, $xref_dbname) = $transdata->display_xref
 Description : returns a pair value of xref display_id and xref dbname  (BRCA1, HUGO)
 Return type : a list

=cut

sub display_xref {
  my $self = shift;
  return $self->transcript->name if $self->transcript->isa('EnsEMBL::Web::Fake');
  return unless $self->transcript->can('display_xref');
  my $trans_xref = $self->transcript->display_xref;
  if ($trans_xref) {
    (my $db_display_name = $trans_xref->db_display_name) =~ s/(.*HGNC).*/$1 Symbol/; #hack for HGNC name labelling, remove in e58
    return ($trans_xref->display_id, $trans_xref->dbname, $trans_xref->primary_id, $db_display_name);
  }
}

=head2 get_similarity_hash

 Arg[1]      : none
 Example     : @similarity_matches = $transdata->get_similarity_hash
 Description : Returns an arrayref of hashes conating similarity matches
 Return type : an array ref

=cut

sub get_similarity_hash {
  my ($self, $recurse) = @_;  

  $recurse = 1 unless defined $recurse;
  my $DBLINKS;
  
  eval { 
    $DBLINKS = $recurse ? $self->transcript->get_all_DBLinks : $self->transcript->get_all_DBEntries;
  };
  
  warn "SIMILARITY_MATCHES Error on retrieving gene DB links $@" if $@;

  return $DBLINKS  || [];
}

=head2 get_go_list

 Arg[1]      : none
 Example     : @go_list = $transdata->get_go_list
 Description : Returns a hashref conating go links
 Return type : a hashref

=cut

sub get_go_list {
  my $self = shift ;

  # The array will have the list of ontologies mapped 
  my $ontologies = $self->species_defs->SPECIES_ONTOLOGIES || return {};

  my $dbname_to_match = shift || join '|', @$ontologies;
  my $ancestor=shift;
  my $trans = $self->transcript;
  my $goadaptor = $self->hub->get_databases('go')->{'go'};

  my @goxrefs = @{$trans->get_all_DBLinks};

  my %go_hash;
  my %hash;

  foreach my $goxref (sort { $a->display_id cmp $b->display_id } @goxrefs) {
    my $go = $goxref->display_id;
    chomp $go; # Just in case
    next unless ($goxref->dbname =~ /^($dbname_to_match)$/);

    my ($otype, $go2) = $go =~ /([\w|\_]+):0*(\d+)/;
    my $term;
    next if exists $hash{$go2};

    my $info_text;
    my $sources;

    if ($goxref->info_type eq 'PROJECTION') {
      $info_text= $goxref->info_text; 
    }

    my $evidence = '';
    if ($goxref->isa('Bio::EnsEMBL::OntologyXref')) {
      $evidence = join ', ', @{$goxref->get_all_linkage_types}; 

      foreach my $e (@{$goxref->get_all_linkage_info}) {
        my ($linkage, $xref) = @{$e || []};
        next unless $xref;
        my ($did, $pid, $db, $db_name) =  ($xref->display_id, $xref->primary_id, $xref->dbname, $xref->db_display_name);
        my $label = "$db_name:$did";

        #db schema won't (yet) support Vega GO supporting xrefs so use a specific form of info_text to generate URL and label
        my $vega_go_xref = 0;
        my $info_text = $xref->info_text;
        if ($info_text =~ /Quick_Go:/) {
          $vega_go_xref = 1;
          $info_text =~ s/Quick_Go://;
          $label = "(QuickGO:$pid)";
        }
        my $ext_url = $self->hub->get_ExtURL_link($label, $db, $pid, $info_text);
        $ext_url = "$did $ext_url" if $vega_go_xref;
        push @$sources, $ext_url;
      }
    }

    $hash{$go2} = 1;

    if (my $goa = $goadaptor->get_GOTermAdaptor) {
      my $term;
      eval { 
        $term = $goa->fetch_by_accession($go2); 
      };

      warn $@ if $@;

      my $term_name = $term ? $term->name : '';
      $term_name ||= $goxref->description || '';

      my $has_ancestor = (!defined ($ancestor));
      if (!$has_ancestor){
        $has_ancestor=($go eq $ancestor);

        my $ancestors = $goa->fetch_all_by_descendant_term($goa->fetch_by_accession($go));
        for(my $i=0; $i< scalar (@$ancestors) && !$has_ancestor; $i++){
          $has_ancestor=(@{$ancestors}[$i]->accession eq $ancestor);
        }
      }
      
      if($has_ancestor){
        $go_hash{$go} = {
          evidence => $evidence,
          term     => $term_name,
          info     => $info_text,
          source   => join ' ,', @{$sources || []},
        };
      }
    }

  }

  return \%go_hash;
}


=head2 get_oligo_probe_data

 Arg[1]       : none 
 Example      : %probe_data  = %{$transdate->get_oligo_probe_data}
 Description  : Retrieves all oligo probe releated DBEntries for this transcript
 Returntype   : Hashref of probe info

=cut

sub get_oligo_probe_data {
  my $self = shift; 
  my $fg_db = $self->database('funcgen'); 
  my $probe_adaptor = $fg_db->get_ProbeAdaptor; 
  my @transcript_xrefd_probes = @{$probe_adaptor->fetch_all_by_external_name($self->stable_id)};
  my $probe_set_adaptor = $fg_db->get_ProbeSetAdaptor; 
  my @transcript_xrefd_probesets = @{$probe_set_adaptor->fetch_all_by_external_name($self->stable_id)};
  my %probe_data;

  # First retrieve data for Probes linked to transcript
  foreach my $probe (@transcript_xrefd_probes) {
    my ($array_name, $probe_name, $vendor, @info);
    
    ($array_name, $probe_name) = split /:/, $_ for @{$probe->get_all_complete_names}; 
    $vendor = $_->vendor for values %{$probe->get_names_Arrays};
    @info = ('probe', $_->linkage_annotation) for @{$probe->get_all_Transcript_DBEntries};
 
    my $key = "$vendor $array_name";
    $key = $vendor if $vendor eq $array_name;

    if (exists $probe_data{$key}) {
      my %probes = %{$probe_data{$key}};
      $probes{$probe_name} = \@info;
      $probe_data{$key} = \%probes;
    } else {
      my %probes = ($probe_name, \@info);
      $probe_data{$key} = \%probes;
    }
  }

  # Next retrieve same information for probesets linked to transcript
  foreach my $probeset (@transcript_xrefd_probesets) {
    my ($array_name, $probe_name, $vendor, @info);

    $probe_name = $probeset->name;
    
    foreach (@{$probeset->get_all_Arrays}) {
     $vendor =  $_->vendor;
     $array_name = $_->name;
    }
    
    @info = ('pset', $_->linkage_annotation) for @{$probeset->get_all_Transcript_DBEntries};
    
    my $key = "$vendor $array_name";
    
    if (exists $probe_data{$key}){
      my %probes = %{$probe_data{$key}};
      $probes{$probe_name} = \@info;
      $probe_data{$key} = \%probes;
    } else {
      my %probes = ($probe_name, \@info);
      $probe_data{$key} = \%probes;
    }
  }

  $self->sort_oligo_data(\%probe_data); 
}

sub sort_oligo_data {
  my ($self, $probe_data) = @_; 
  my $hub        = $self->hub;

  foreach my $array (sort keys %$probe_data) {
    my $text;
    my $p_type = 'pset';
    my %data   = %{$probe_data->{$array}};
    
    foreach my $probe_name (sort keys %data) {
      my ($p_type, $probe_text) = @{$data{$probe_name}};
      
      my $url = $hub->url({
        'type'   => 'Location',
        'action' => 'Genome',
        'id'     => $probe_name,
        'ftype'  => 'ProbeFeature',
        'fdb'    => 'funcgen',
        'ptype'  => $p_type, 
      });
      
      $text .= '<p>';
      $text .= $probe_name;
      $text .= qq{ <span class="small">[$probe_text]</span>} if $probe_text;
      $text .= qq{  [<a href="$url">view all locations</a>]</p>};
    }
    
    push @{$self->__data->{'links'}{'ARRAY'}}, [ $array || $array, $text ];
  }
}

sub rna_notation {
  my $self       = shift;
  my $transcript = $self->Obj;
  my $length     = $transcript->length;
  my $miRNA      = $transcript->get_all_Attributes('miRNA');
  my $ncRNA      = $transcript->get_all_Attributes('ncRNA');
  my @strings;
  
  if (@$miRNA) {
    my $string = '-' x $length;
    
    foreach (@$miRNA) {
      my ($start, $end) = split /-/, $_->value;
      substr($string, $start - 1, $end - $start + 1) = '#' x ($end - $start + 1);
    }
    
    push @strings, $string;
  }
  
  if (@$ncRNA) {
    my $string = '-' x $length;
    
    foreach (@$ncRNA) {
      my ($start, $end, $packed) = $_->value =~ /^(\d+):(\d+)\s+(.*)/;
      substr($string, $start - 1, $end - $start + 1) = join '', map { substr($_, 0, 1) x (substr($_, 1) || 1) } ($packed =~ /(\D\d*)/g);
    }
    
    push @strings, $string;
  }
  
  return @strings;
}

sub vega_projection {
  my $self = shift;
  my $alt_assembly = shift;
  my $alt_projection = $self->Obj->feature_Slice->project('chromosome', $alt_assembly);
  my @alt_slices = ();
  
  foreach my $seg (@{$alt_projection}) {
    my $alt_slice = $seg->to_Slice;
    push @alt_slices, $alt_slice;
  }
  
  return \@alt_slices;
}

sub mod_date {
  my $self = shift;
  my $time = $self->transcript->modified_date;
  return unless $time;
  return $self->date_format($time,'%d/%m/%y');
}

sub created_date {
  my $self = shift;
  my $time = $self->transcript->created_date;
  return unless $time;
  return $self->date_format($time,'%d/%m/%y');
}

sub date_format {
  my ($self, $time, $format) = @_;
  my ($d, $m, $y) = (localtime $time)[3,4,5];
  
  my %S = (
    d => sprintf('%02d', $d),
    m => sprintf('%02d', $m+1),
    y => $y+1900
  );
  
  (my $res = $format) =~ s/%(\w)/$S{$1}/ge;
  return $res;
}

# Calls for IDHistoryView

sub get_archive_object {
  my $self = shift;
  my $id = $self->stable_id;
  my $archive_adaptor = $self->database('core')->get_ArchiveStableIdAdaptor;
  my $archive_object = $archive_adaptor->fetch_by_stable_id($id);

  return $archive_object;
}

=head2 history

 Arg1        : data object
 Description : gets the archive id history tree based around this ID
 Return type : listref of Bio::EnsEMBL::ArchiveStableId
               As every ArchiveStableId knows about it's successors, this is
               a linked tree.

=cut

sub history {
  my $self = shift;

  my $archive_adaptor = $self->database('core')->get_ArchiveStableIdAdaptor;
  return unless $archive_adaptor;

  my $history = $archive_adaptor->fetch_history_tree_by_stable_id($self->stable_id);
  return $history;
}

#########################################################################
#alignview support features - some ported from schema49 AlignmentFactory#

sub get_sf_hit_db_name {
  my $self = shift;
  my ($id) = @_;
  my $hit = $self->get_hit($id);
  return unless $hit;
  return $hit->db_name;
}

sub get_hit {
  my $self = shift;
  my ($id) = @_;

  foreach my $sf (@{$self->Obj->get_all_supporting_features}) {
    return $sf if ($sf->hseqname eq $id);
  }
  
  foreach my $exon (@{$self->Obj->get_all_Exons}) {
    foreach my $sf (@{$exon->get_all_supporting_features}) {
      return $sf if ($sf->hseqname eq $id);
    }
  }
  return;
}

sub determine_sequence_type {
  my $self = shift;
  my $sequence = shift;
  return 'UNKNOWN' unless $sequence;
  my $threshold = shift || 70; # %ACGT for seq to qualify as DNA
  $sequence = uc $sequence;
  $sequence =~ s/\s|N//;
  $sequence =~ s/^>.*\n//; #remove header line since long headers confuse sequence type determination
  my $all_chars = length( $sequence );
  return unless $all_chars;
  my $dna_chars = ( $sequence =~ tr/ACGT// );
  return (($dna_chars/$all_chars) * 100) > $threshold ? 'DNA' : 'PEP';
}

sub split60 {
  my ($self, $seq) = @_;
  $seq =~ s/(.{1,60})/$1\n/g;
  return $seq;
}

sub get_int_seq {
  my $self      = shift;
  my $obj       = shift  || return undef;
  my $seq_type  = shift  || return undef; # DNA || PEP
  my $other_obj = shift;
  my $fasta_prefix = join '', '>', $obj->stable_id, "<br />\n";
  
  if ($seq_type eq 'DNA') {
    return [ $fasta_prefix . $self->split60($obj->seq->seq), length $obj->seq->seq ];
  } elsif ($seq_type eq 'PEP') {
    if ($obj->isa('Bio::EnsEMBL::Exon') && $other_obj->isa('Bio::EnsEMBL::Transcript')) {
      return [ $fasta_prefix.$self->split60($obj->peptide($other_obj)->seq), length $obj->peptide($other_obj)->seq ] if $obj->peptide($other_obj) && $other_obj->translate;
    } elsif($obj->translate) {
      $fasta_prefix = join '', '>', $obj->translation->stable_id, "<br />\n";
      return [ $fasta_prefix . $self->split60($obj->translate->seq), length $obj->translate->seq ];
    }
  }
  
  return [];
}

sub save_seq {
  my $self = shift;
  my $content = shift ;
  my $seq_file = $self->species_defs->ENSEMBL_TMP_TMP . '/SEQ_' . time() . int(rand()*100000000) . $$;
  open (TMP,">$seq_file") or die("Cannot create working file.$!");
  print TMP $content;
  close TMP;
  return ($seq_file)
}

=head2 get_Alignment

 Arg[1]      : external sequence
 Arg[2]      : internal sequence (transcript, exon or translation)
 Arg[3]      : type of sequence (DNA or PEP)
 Example     : my $alig =  $self->get_alignment( $ext_seq, $int_seq, $seq_type )
 Description : Runs either matcher or wise2 for pairwise sequence alignment
               Uses custom output format pairln if available
               Used for viewing of supporting evidence alignments
 Return type : alignment

=cut

sub get_alignment {
  my $self = shift;
  my $ext_seq  = shift || return undef;
  my $int_seq  = shift || return undef;
  $int_seq =~ s/<br \/>//g;
  my $seq_type = shift || return undef;
  
  # To stop box running out of memory - put an upper limit on the size of sequence
  # that alignview can handle
  if (length $int_seq > 1e6 || length $ext_seq > 1e6)  {
    $self->problem('fatal', 'Cannot align if sequence > 1 Mbase');
    return 'Sorry, cannot do the alignments if sequence is longer than 1 Mbase';
  }

  my $int_seq_file = $self->save_seq($int_seq);
  my $ext_seq_file = $self->save_seq($ext_seq);

  ####
  #We deal with having to use the reverse complement of a hit sequence by telling PFETCH to retrieve it where appropriate
  #This will deal with all situations I am aware of, but a better way of doing it could be to use EMBOSS revcomp before running matcher
  ####

  my $label_width  = '22'; # width of column for e! object label
  my $output_width = 61;   # width of alignment
  my $dnaAlignExe  = '%s/bin/matcher -asequence %s -bsequence %s -outfile %s %s';
  my $pepAlignExe  = '%s/bin/psw -dymem explicit -m %s/wisecfg/blosum62.bla %s %s -n %s -w %s > %s';

  my $out_file = time() . int(rand()*100000000) . $$;
  $out_file = $self->species_defs->ENSEMBL_TMP_DIR.'/' . $out_file . '.out';

  my $command;
  if ($seq_type eq 'DNA') {
    $command = sprintf $dnaAlignExe, $self->species_defs->ENSEMBL_EMBOSS_PATH, $int_seq_file, $ext_seq_file, $out_file, '-aformat3 pairln';
    warn "Command: $command" if $self->species_defs->ENSEMBL_DEBUG_FLAGS & $self->species_defs->ENSEMBL_DEBUG_EXTERNAL_COMMANDS ;
    `$command`;
    
    unless (open(OUT, "<$out_file")) {
      $command = sprintf $dnaAlignExe, $self->species_defs->ENSEMBL_EMBOSS_PATH, $int_seq_file, $ext_seq_file, $out_file;
      warn "Command: $command" if $self->species_defs->ENSEMBL_DEBUG_FLAGS & $self->species_defs->ENSEMBL_DEBUG_EXTERNAL_COMMANDS ;
      `$command`;
    }
    
    unless (open(OUT, "<$out_file")) {
      $self->problem('fatal', "Cannot open alignment file.", $!);
    }
  } elsif ($seq_type eq 'PEP') {
    $command = sprintf $pepAlignExe, $self->species_defs->ENSEMBL_WISE2_PATH, $self->species_defs->ENSEMBL_WISE2_PATH, $int_seq_file, $ext_seq_file, $label_width, $output_width, $out_file;
    warn "Command: $command" if $self->species_defs->ENSEMBL_DEBUG_FLAGS & $self->species_defs->ENSEMBL_DEBUG_EXTERNAL_COMMANDS;
    `$command`;

    unless (open(OUT, "<$out_file")) {
      $self->problem('fatal', "Cannot open alignment file.", $!);
    }
  } else { 
    return undef; 
  }
    
  my $alignment ;
  while (<OUT>) {
    next if $_ =~ 
    /\#Report_file
     |\#----.*
     |\/\/\s*
     |\#\#\#
     |^\#$
     |Rundate: #matcher
     |Commandline #matcher
     |asequence #matcher
     |bsequence #matcher
     |outfile #matcher
     |aformat #matcher
     |Align_format #matcher
     |Report_file #matcher
     /x;
     
    $alignment .= $_;
  }
  
  $alignment =~ s/\n+$//;
  unlink $out_file;
  unlink $int_seq_file;
  unlink $ext_seq_file;
  $alignment;
}

###################################
#end of alignview support features

sub get_genetic_variations {
  my $self       = shift;
  my @samples    = @_;
  my $hub        = $self->hub;
  my $tsv_extent = $hub->param('context') eq 'FULL' ? 5000 : $hub->param('context');
  my $snp_data   = {};

  foreach my $sample (@samples) {
    my $munged_transcript = $self->get_munged_slice('tsv_transcript', $tsv_extent, 1);    
    my $sample_slice      = $munged_transcript->[1]->get_by_strain($sample);
    my ($allele_info, $consequences) = $self->getAllelesConsequencesOnSlice($sample, 'tsv_transcript', $sample_slice);
    
    next unless @$consequences && @$allele_info;
    
    my $index = 0;
    
    foreach my $allele_ref (@$allele_info) {
      my $allele      = $allele_ref->[2];
      my $conseq_type = $consequences->[$index];
      
      $index++;
      
      next unless $conseq_type && $allele;

      # Type
      my $type = join ', ', @{$conseq_type->consequence_type || []};
      $type   .= ' (Same As Ref. Assembly)' if $type eq 'SARA';

      # Position
      my $offset    = $sample_slice->strand > 0 ? $sample_slice->start - 1 : $sample_slice->end + 1;
      my $chr_start = $allele->start + $offset;
      my $chr_end   = $allele->end + $offset;
      my $pos       = $chr_start;
      
      if ($chr_end < $chr_start) {
        $pos = "between&nbsp;$chr_end&nbsp;&amp;&nbsp;$chr_start";
      } elsif ($chr_end > $chr_start) {
        $pos = "$chr_start&nbsp;-&nbsp;$chr_end";
      }
      
      my $chr        = $sample_slice->seq_region_name;
      my $aa_alleles = $conseq_type->pep_allele_string;
      my $sources    = join ', ' , @{$allele->get_all_sources || []};
      my $vid        = $allele->variation_name;
      my $source     = $allele->source;
      my $vf         = $allele->variation->dbID;
      
      my $url = $hub->url({
        type   => 'Variation', 
        action => 'Summary', 
        v      => $vid , 
        vf     => $vf, 
        source => $source 
     });
      
      push @{$snp_data->{"$chr:$pos"}->{$sample}}, {
        ID          => qq{<a href="$url">$vid</a>},
        consequence => $type,
        aachange    => $aa_alleles || '-'
      };
    }
  }
  
  return $snp_data;
}

sub get_transcript_variations {
  my $self = shift;
	return $self->get_adaptor('get_TranscriptVariationAdaptor', 'variation')->fetch_all_by_Transcripts_with_constraint([ $self->Obj ]);
}

sub variation_data {
  my ($self, $slice, $include_utr, $strand) = @_;
  
  return [] unless $self->species_defs->databases->{'DATABASE_VARIATION'};
  
  my $hub                = $self->hub;
  my $transcript         = $self->Obj;
  my $cd_start           = $transcript->cdna_coding_start;
  my $cd_end             = $transcript->cdna_coding_end;
  my @coding_sequence    = split '', substr $transcript->seq->seq, $cd_start - 1, $cd_end - $cd_start + 1;
  my %consequence_filter = map { $_ ? ($_ => 1) : () } $hub->param('consequence_filter');
     %consequence_filter = () if join('', keys %consequence_filter) eq 'off';
  my @data;
  
  # Population filtered variations currently fail to return in a reasonable time
  #my %population_filter;
  
  #if ($slice) {
  #  my $hub    = $self->hub;
  #  my $filter = $hub->param('population_filter');
  #  
  #  if ($filter && $filter ne 'off') {
  #    %population_filter = map { $_->dbID => $_ }
  #      @{$slice->get_all_VariationFeatures_by_Population(
  #        $hub->get_adaptor('get_PopulationAdaptor', 'variation')->fetch_by_name($filter), 
  #        $hub->param('min_frequency')
  #      )};
  #  }
  #}
  
  foreach my $tv (@{$self->get_transcript_variations}) {
    my $pos = $tv->translation_start;
    
    next if !$include_utr && !$pos;
    next unless $tv->cdna_start && $tv->cdna_end;
    next if scalar keys %consequence_filter && !grep $consequence_filter{$_}, @{$tv->consequence_type};
    
    my $vf    = $tv->variation_feature;
    my $vdbid = $vf->dbID;
    
    #next if scalar keys %population_filter && !$population_filter{$vdbid};
    
    my $start = $vf->start;
    my $end   = $vf->end;
    my $tva   = $tv->get_all_alternate_TranscriptVariationAlleles->[0];
    
    push @data, {
      tva           => $tva,
      tv            => $tv,
      vf            => $vf,
      position      => $pos,
      vdbid         => $vdbid,
      snp_source    => $vf->source,
      snp_id        => $vf->variation_name,
      ambigcode     => $vf->ambig_code($strand),
      codons        => $pos ? join(', ', split '/', $tva->display_codon_allele_string) : '',
      allele        => $vf->allele_string(undef, $strand),
      pep_snp       => join(', ', split '/', $tva->pep_allele_string),
      type          => $tv->display_consequence,
      class         => $vf->var_class,
      length        => $end - $start,
      indel         => $vf->var_class =~ /in\-?del|insertion|deletion/ ? ($start > $end ? 'insert' : 'delete') : '',
      codon_seq     => [ map $coding_sequence[3 * ($pos - 1) + $_], 0..2 ],
      codon_var_pos => ($tv->cds_start + 2) - ($pos * 3)
    };
  }
  
  @data = map $_->[2], sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } map [ $_->{'vf'}->length, $_->{'vf'}->most_severe_OverlapConsequence->rank, $_ ], @data;
  
  return \@data;
}

=head2 peptide_splice_sites

 Example    : $splice_sites = $transcript->peptide_splice_sites
 Description: Calculates any overlapping exon boundries for a peptide sequence
              it then builds a hash and stores it on the object. The hash contains
              the exon Ids, phase of the exon and if it has an overlapping slice site
              overlapping slice site = exon ends in the middle of a codon and therfore 
              in the middle of a amino-acid residue of the protein
 Return type: hashref
=cut

sub peptide_splice_sites {
  my $self = shift;
  
  return $self->{'splice_sites'} if $self->{'splice_sites'};
  
  my $splice_site = {};
  my $i           = 0;
  my $cdna_len    = 0;
  my $pep_len     = 0;
  
  foreach my $e (@{$self->Obj->get_all_translateable_Exons}) {
    $i++;
    $cdna_len += $e->length;
    
    my $overlap_len = $cdna_len % 3;
    my $pep_len     = $overlap_len ? 1 + ($cdna_len - $overlap_len) / 3 : $cdna_len / 3;
    
    $splice_site->{$pep_len-1}{'overlap'} = $pep_len-1 if $overlap_len;
    $splice_site->{$pep_len}{'exon'}      = $e->stable_id || $i;
    $splice_site->{$pep_len}{'phase'}     = $overlap_len;
  }
  
  return $self->{'splice_sites'} = $splice_site;
}

sub can_export {
  my $self = shift;
  
  return $self->action =~ /^Export$/ ? 0 : $self->availability->{'transcript'};
}

1;