#$Id: Variation.pm,v 1.85 2012-02-10 11:08:01 wm2 Exp $
package EnsEMBL::Web::Object::Variation;

### NAME: EnsEMBL::Web::Object::Variation
### Wrapper around a Bio::EnsEMBL::Variation 
### or EnsEMBL::Web::VariationFeature object  

### PLUGGABLE: Yes, using Proxy::Object 

### STATUS: At Risk
### Contains a lot of functionality not directly related to
### manipulation of the underlying API object 

### DESCRIPTION

# FIXME Are these actually used anywhere???
# Is there a reason they come before 'use strict'?
use Bio::EnsEMBL::Variation::Utils::Sequence qw(ambiguity_code variation_class);
use Bio::EnsEMBL::Utils::Eprof qw(eprof_start eprof_end eprof_dump); 

use strict;
use warnings;
no warnings "uninitialized";

use EnsEMBL::Web::Cache;

use base qw(EnsEMBL::Web::Object);

our $MEMD = new EnsEMBL::Web::Cache;

sub availability {
  my $self = shift;
  
  if (!$self->{'_availability'}) {
    my $availability = $self->_availability;
    my $obj = $self->Obj;
    
    if ($obj->isa('Bio::EnsEMBL::Variation::Variation')) {
      my $counts = $self->counts;
      
      $availability->{'variation'} = 1;
      
      $availability->{"has_$_"}  = $counts->{$_} for qw(transcripts populations individuals ega alignments ldpops);
      $availability->{'is_somatic'}  = $obj->is_somatic;
      $availability->{'not_somatic'} = !$obj->is_somatic;
    }
    
    $self->{'_availability'} = $availability;
  }
  
  return $self->{'_availability'};
}

sub counts {
  my $self = shift;
  my $obj  = $self->Obj;
  my $hub  = $self->hub;

  return {} unless $obj->isa('Bio::EnsEMBL::Variation::Variation');

  my $vf  = $hub->param('vf');
  my $key = sprintf '::Counts::Variation::%s::%s::%s::', $self->species, $hub->param('vdb'), $hub->param('v');
  $key   .= $vf . '::' if $vf;

  my $counts = $self->{'_counts'};
  $counts ||= $MEMD->get($key) if $MEMD;

  unless ($counts) {
    $counts = {};
    $counts->{'transcripts'} = $self->count_transcripts;
    $counts->{'populations'} = $self->count_populations;
    $counts->{'individuals'} = $self->count_individuals;
    $counts->{'ega'}         = $self->count_ega;
    $counts->{'ldpops'}      = $self->count_ldpops;
    $counts->{'alignments'}  = $self->count_alignments->{'multi'};
    
    $MEMD->set($key, $counts, undef, 'COUNTS') if $MEMD;
    $self->{'_counts'} = $counts;
  }

  return $counts;
}
sub count_ega {
  my $self = shift;
  my @ega_links = @{$self->get_external_data};
  my $counts = scalar @ega_links || 0; 
  return $counts;  
}
sub count_transcripts {
  my $self = shift;
  my %mappings = %{ $self->variation_feature_mapping };
  my $counts = 0;

  foreach my $varif_id (keys %mappings) {
    next unless ($varif_id  eq $self->param('vf'));
    my @transcript_variation_data = @{ $mappings{$varif_id}{transcript_vari} };
    $counts = scalar @transcript_variation_data;
  }
  
  $counts += scalar map {@{$_->get_all_RegulatoryFeatureVariations}, @{$_->get_all_MotifFeatureVariations}} @{$self->get_variation_features};

  return $counts;
}

sub count_populations {
  my $self = shift;
  my $counts = scalar(keys %{$self->freqs}) || 0;
  return $counts;
}

sub count_individuals {
  my $self = shift;
  my $dbh  = $self->database('variation')->get_VariationAdaptor->dbc->db_handle;
  my $var  = $self->Obj;
  
  # somatic variations don't have genotypes currently
  return 0 if $var->is_somatic;
  
  my $gts = $var->get_all_IndividualGenotypes();
  
  return defined($gts) ? scalar @$gts : 0;
}

# uncomment when including export data for variation
# sub can_export {
#   my $self = shift;
#   
#   return $self->action =~ /^Export$/ ? 0 : $self->availability->{'variation'};
# }

sub count_ldpops {
  my $self = shift;
  my $pa  = $self->database('variation')->get_PopulationAdaptor;
  my $count = scalar @{$pa->fetch_all_LD_Populations};
  
  return ($count > 0 ? $count : undef);
}

sub short_caption {
  my $self = shift;
  
  my $type = $self->Obj->is_somatic ? 'Somatic mutation' : 'Variation';
  my $short_type = $self->Obj->is_somatic ? 'S. mut' : 'Var';
  return $type.' displays' unless shift eq 'global';   
  
  my $label = $self->name;  
  return length $label > 30 ? "$short_type: $label" : "$type: $label";
}

sub caption {
 my $self = shift; 
 my $caption = [$self->name, uc $self->vari_class];
 return $caption;
}

# Location ----------------------------------------------------------------------

sub not_unique_location {
  my $self = shift;
  unless ($self->hub->core_param('vf') ){
    my %mappings = %{ $self->variation_feature_mapping };
    my $count = scalar (keys %mappings);
    my $html;
    if ($count < 1) {
      $html = "<p>This feature has not been mapped.<p>";
    } elsif ($count > 1) { 
      $html = "<p>You must select a location from the panel above to see this information</p>";
    }
    return  $html;
  }
  return;
}

sub location_string {

  ### Variation_location
  ### Example    : my $location = $self->location_string;
  ### Description: Gets chr:start-end for the SNP with 100 bases on either side
  ### Returns string: chr:start-end

  my ($self, $unique) = @_;
  my( $sr, $st ) = $self->_seq_region_($unique);
  return $sr ? "$sr:@{[$st-100]}-@{[$st+100]}" : undef;
}

sub var_location {
  ### Variation_location
  ### Example    : my $location = $self->location_string;
  ### Description: Gets chr:start-end for the SNP 
  ### Returns string: chr:start-end

  my ($self, $unique) = @_;
  my( $sr, $st ) = $self->_seq_region_($unique);
  return $sr ? "$sr:@{[$st]}-@{[$st]}" : undef;
}

sub _seq_region_ {

  ### Variation_location
  ### Args        : $unique
  ###               if $unique=1 -> returns undef if there are more than one 
  ###               variation features returned)
  ###               if $unique is 0 or undef, it returns the data for the first
  ###               mapping postion
  ### Example    : my ($seq_region, $start) = $self->_seq_region_;
  ### Description: Gets the sequence region, start and coordinate system name
  ### Returns $seq_region, $start, $seq_type

  my $self = shift;
  my $unique = shift;
  my($seq_region, $start, $seq_type);
  if (  my $region  = $self->param('c') ) {
    ($seq_region, $start) = split /:/, $region;
    my $slice = $self->database('core')->get_SliceAdaptor->fetch_by_region(undef,$seq_region);
    return unless $slice;
    $seq_type = $slice->coord_system->name;
  }
  else {
    my @vari_mappings = @{ $self->get_variation_features };
    return (undef, undef, undef, "no") unless  @vari_mappings;

    if ($unique) {
      return (undef, undef, undef, "multiple") if $#vari_mappings > 0;
    }
    $seq_region  = $self->region_name($vari_mappings[0]);
    $start       = $self->start($vari_mappings[0]);
    $seq_type    = $self->region_type($vari_mappings[0]);
  }
  return ( $seq_region, $start, $seq_type );
}


sub seq_region_name    {

  ### Variation_location 
  ### a

  my( $sr,$st) = $_[0]->_seq_region_; return $sr; 
}
sub seq_region_start   {
  ### Variation_location 
  ### a
  my( $sr,$st) = $_[0]->_seq_region_; return $st; 
}
sub seq_region_end     {
  ### Variation_location 
  ### a
  my( $sr,$st) = $_[0]->_seq_region_; return $st; 
}
sub seq_region_strand  {
  ### Variation_location 
  ### a
  return 1; 
}
sub seq_region_type    { 
  ### Variation_location
  ### a
  my($sr,$st,$type) = $_[0]->_seq_region_; return $type; 
}

sub seq_region_data {

  ### Variation_location
  ### Args       : none
  ### Example    : my ($seq_region, $start, $type) = $object->seq_region_data;
  ### Description: Only returns sequence region, start and coordinate system name 
  ###              if this Variation Object maps to one Variation Feature obj
  ### Returns $seq_region, $start, $seq_type, $error(optional) which specifies
  ### 'no' if no mapping or 'multiple' if has several hits
  ### If there is an error, the first 3 args returned are undef

  my($sr,$st,$type, $error) = $_[0]->_seq_region_(1); 
  return ($sr, $st, $type, $error);
}


# Variation calls ----------------------------------------------------------------
sub vari {

  ### Variation_object_calls
  ### Args: none
  ### Example    : my $ensembl_vari = $object->vari
  ### Description: Gets the ensembl variation object stored on the variation data object
  ### Returns Bio::EnsEmbl::Variation

  my $self = shift;
  return $self->Obj;
}

sub name {

   ### Variation_object_calls
   ### a
   ### Arg (optional):   Variation object name (string)
   ### Example    : my $vari_name = $object->vari_name;
   ### Example    : $object->vari_name('12335');
   ### Returns String for variation name

  my $self = shift;
  if (@_) {
      $self->vari->name(shift);
  }
  return $self->vari->name;
}

sub source {

  ### Variation_object_calls
  ### Args: none
  ### Example    : my $vari_source = $object->source;
  ### Description: gets the Variation source
  ### Returns String

  $_[0]->vari->source;
}

sub source_description {

  ### Variation_object_calls
  ### Args: none
  ### Example    : my $vari_source_desc = $object->source_description;
  ### Description: gets the description for the Variation source
  ### Returns String

  $_[0]->vari->source_description;
}

sub get_genes {

  ### Variation_object_calls
  ### a
  ### Args: none
  ### Example    : my @genes = @ {$obj->get_genes};
  ### Returns arrayref of Bio::EnsEMBL::Gene objects

  $_[0]->vari->get_all_Genes; 
}


sub source_version { 

  ### Variation_object_calls
  ### a
  ### Example    : my $vari_source_version = $object->source
  ### Description: gets the Variation source version e.g. dbSNP version 119
  ### Returns String

  my $self    = shift;
  my $source  = $self->vari->source;
  my $version = $self->vari->adaptor->get_source_version($source);
  return $version;
}


sub source_url {
  
  ### Variation_object_calls
  ### Args: none
  ### Example    : my $vari_source_url = $object->source_url
  ### Description: gets the Variation source URL
  ### Returns String
  
  my $self = shift;
  my $source_url = $self->vari->source_url;
  return $source_url;
}
 
sub dblinks {

  ### Variation_object_calls
  ### Args: none
  ### Example    : my $dblinks = $object->dblinks;
  ### Description: gets the SNPs links to external database
  ### Returns Hashref (external DB => listref of external IDs)

  my $self = shift;
  my @sources = @{  $self->vari->get_all_synonym_sources  };
  my %synonyms;
  foreach (@sources) {
    $synonyms{$_} = $self->vari->get_all_synonyms($_);
  }
  return \%synonyms;
}

sub consequence_type {
  my $self = shift;
  my $consequence_type;
  my @vari_mappings = @{ $self->get_variation_features };
  foreach my $f (@vari_mappings){
    return '-' unless $f->variation_name eq $self->name;
    $consequence_type = $f->display_consequence;
  }
  $consequence_type =~s/_/ /g;
 
  return $consequence_type;
}

sub status { 

  ### Variation_object_calls
  ### a
  ### Example    : my $vari_status = $object->get_all_validation_states;
  ### Returns List of states

  my $self = shift;
  return $self->vari->get_all_validation_states;
}



sub flanking_seq {

  ### Variation_object_calls
  ### Args: "up" or "down" (string)
  ### Example    : my $down_seq = $object->flanking_seq($down);
  ### Description: gets the sequence downstream of the SNP
  ### Returns String

  my $self = shift;
  my $direction = shift;
  my $call = $direction eq 'up' ? "five_prime_flanking_seq" : "three_prime_flanking_seq";
  my $sequence;
  eval { 
    $sequence = $self->vari->$call;
  };
  if ($@) {
    warn "*****[ERROR]: No flanking sequence!";
    return 'unavailable';
  }
  return uc($sequence);
}


sub alleles {

  ### Variation_object_call
  ### Args: none
  ### Example    : my $alleles = $object->alleles;
  ### Description: gets the SNP alleles
  ### Returns Array or string

  my $self = shift;

  my  @vari_mappings = @{ $self->unique_variation_feature };
  return $vari_mappings[0]->allele_string if @vari_mappings;

  # Several mappings or no mappings
  my @allele_obj = @{$self->vari->get_all_Alleles};
  my %alleles;
  map { $alleles{$_->allele} = 1; } @allele_obj;

  my $observed_alleles = join "/", (keys %alleles);
  if (@vari_mappings) {
    return "$observed_alleles";
  } else {
    return "This variation has no mapping.  $observed_alleles";
  }
}



sub vari_class{

  ### Variation_object_calls
  ### a
  ### Example    : my $vari_class = $object->vari_class
  ### Description: returns the variation class (indel, snp, het) for a varation
  ### Returns String
  
  # /!\ The following block  needs to be changed for the e!62 by "return $_[0]->vari->var_class;" /!\
  my $var = $_[0]->vari->var_class; # only for e!61
  $var =~ tr/_/ /;
  return $var;
}



sub moltype {

  ### Variation_object_calls
  ### a
  ### Example    : $object->moltype;
  ### Description: returns the molecular type of the variation
  ### Returns String

  my $self = shift;
  return $self->vari->moltype;
}



sub ancestor {

  ### Variation_object_calls 
  ### a
  ### Example    : $object->ancestral_allele;
  ### Description: returns the ancestral allele for the variation
  ### Returns String

  my $self = shift;
  return $self->vari->ancestral_allele;
}


sub clinical_significance {

  ### Variation_object_calls 
  ### a
  ### Example    : $object->clinical_significance;
  ### Description: returns the clinical significance and the corresponding display colour.
  ### Returns and array

  my $self = shift;
  my %cs_colours = ('non-pathogenic' => '#090',
                    'begnin'         => '#090',
                    'pathogenic'     => '#FF0000',
                    'probable-non-pathogenic'  => '#FF9000',
                    'probable-pathogenic'     => '#FF9000');                  
  my $cs = $self->vari->clinical_significance;
  my $colour = $cs_colours{$cs} ? $cs_colours{$cs} : '#779';
  return $cs,$colour;
}


sub tagged_snp { 

  ### Variation_object_calls
  ### Args: none
  ### Example    : my $pops = $object->tagged_snp
  ### Description: The "is_tagged" call returns an array ref of populations 
  ###              objects Bio::Ensembl::Variation::Population where this SNP 
  ###              is a tag SNP
  ### Returns hashref of pop_name

  my $self = shift;
  my  @vari_mappings = @{ $self->get_variation_features };
  return {} unless @vari_mappings;

  my %pops;
  foreach my $vf ( @vari_mappings ) {
    foreach my $pop_obj ( @{ $vf->is_tagged } ) {
      $pops{$self->pop_name($pop_obj)} = "Tagged SNP";
    }
  }
  return \%pops or {};
}

sub tag_snp { 

  ### Variation_object_calls
  ### Args: none
  ### Example    : my $pops = $object->tagged_snp
  ### Description: The "is_tagged" call returns an array ref of populations 
  ###              objects Bio::Ensembl::Variation::Population where this SNP 
  ###              is a tag SNP
  ### Returns hashref of pop_name

  my $self = shift;
  my  @vari_mappings = @{ $self->get_variation_features };
  return {} unless @vari_mappings;

  my %pops;
  foreach my $vf ( @vari_mappings ) {
    foreach my $pop_obj ( @{ $vf->is_tag } ) {
      $pops{$self->pop_name($pop_obj)} = "Tag SNP";
    }
  }
  return \%pops or {};
}

sub freqs {

  ### Population_allele_genotype_frequencies
  ### Args      : none
  ### Example    : my $data = $object->freqs;
  ### Description: gets allele and genotype frequencies for this Variation
  ### Returns hash of data, 

  my $self = shift;
  return {} unless @_ || $self->param('vf');
  my $variation_feature = shift || $self->vari->get_VariationFeature_by_dbID($self->param('vf'));
  my $allele_list = $variation_feature->get_all_Alleles;
  return {} unless $allele_list;
  
  my (%data, $allele_missing);
  foreach my $allele_obj ( sort { $a->subsnp cmp $b->subsnp }@{ $allele_list } ) {  
    my $pop_obj = $allele_obj->population;  
    next unless $pop_obj;
    my $pop_id  = $self->pop_id($pop_obj);
    my $ssid = $allele_obj->subsnp;
    
    # failed status
    $data{$pop_id}{$ssid}{failed_desc} = $allele_obj->failed_description if $allele_obj->is_failed;
   
    push (@{ $data{$pop_id}{$ssid}{AlleleFrequency} }, $allele_obj->frequency);
    push (@{ $data{$pop_id}{$ssid}{AlleleCount} }, $allele_obj->count);
    push (@{ $data{$pop_id}{$ssid}{Alleles} },   $allele_obj->allele);    
    next if $data{$pop_id}{$ssid}{pop_info};
    $data{$pop_id}{$ssid}{pop_info} = $self->pop_info($pop_obj);
    $data{$pop_id}{$ssid}{ssid} = $allele_obj->subsnp();
    $data{$pop_id}{$ssid}{submitter} = $allele_obj->subsnp_handle();
  }
  
  # Add genotype data;
  foreach my $pop_gt_obj ( sort { $a->subsnp cmp $b->subsnp} @{ $self->pop_genotype_obj } ) {
    my $pop_obj = $pop_gt_obj->population; 
    my $pop_id  = $self->pop_id($pop_obj); 
    my $ssid = $pop_gt_obj->subsnp();  
    # No allele data for this population ...
    unless (exists $data{$pop_id}{$ssid}{AlleleFrequency}){
      $allele_missing = 1;
      push (@{ $data{$pop_id}{$ssid}{AlleleFrequency} }, "");
      push (@{ $data{$pop_id}{$ssid}{AlleleCount} }, "");
      push (@{ $data{$pop_id}{$ssid}{Alleles} }, "");
      $data{$pop_id}{$ssid}{ssid} = $pop_gt_obj->subsnp();
      $data{$pop_id}{$ssid}{submitter} = $pop_gt_obj->subsnp_handle();
    }

    $data{$pop_id}{$ssid}{pop_info} = $self->pop_info($pop_obj);
    push (@{ $data{$pop_id}{$ssid}{GenotypeFrequency} }, $pop_gt_obj->frequency);
    push (@{ $data{$pop_id}{$ssid}{GenotypeCount} }, $pop_gt_obj->count);
    push (@{ $data{$pop_id}{$ssid}{Genotypes} }, $self->pop_genotypes($pop_gt_obj)); 

    $data{$pop_id}{$ssid}{count} = $pop_gt_obj->count();
  }

  if ($allele_missing == 1){
    %data = %{ $self->calculate_allele_freqs_from_genotype($variation_feature, \%data) }; 
  }

  return \%data;
}

sub calculate_allele_freqs_from_genotype {
  my ($self, $variation_feature, $temp_data) = @_;
  my %data = %$temp_data;
  my ($a1, $a2) = split /\//, $variation_feature->allele_string;
  
  # check if have allele data, if not calculate it
  foreach my $pop_id(keys %data){
    foreach my $ssid (keys %{$data{$pop_id}}){
      if (scalar @{$data{$pop_id}{$ssid}{'Alleles'}} <= 1){
        my (%genotype_freqs, $i);
        
        next unless $data{$pop_id}{$ssid}{'GenotypeFrequency'};
        
        foreach my $genotype (@{$data{$pop_id}{$ssid}{'Genotypes'}}){
          $genotype_freqs{$genotype} = $data{$pop_id}{$ssid}{'GenotypeFrequency'}[$i++];
        }
        
        my $genotype_1_same = $genotype_freqs{"$a1|$a1"} || 0;
        my $genotype_1_diff = $genotype_freqs{"$a1|$a2"} || $genotype_freqs{"$a2|$a1"} || 0;
        my $freq_a1         = ($genotype_1_diff + (2 * $genotype_1_same)) /2;
        my $freq_a2         = 1 - $freq_a1;
        
        @{$data{$pop_id}{$ssid}{'Alleles'}} = ();
        @{$data{$pop_id}{$ssid}{'AlleleFrequency'}} = ();
        
        push @{$data{$pop_id}{$ssid}{'Alleles'}}, $a1; 
        push @{$data{$pop_id}{$ssid}{'Alleles'}}, $a2;  
        push @{$data{$pop_id}{$ssid}{'AlleleFrequency'}}, $freq_a1; 
        push @{$data{$pop_id}{$ssid}{'AlleleFrequency'}}, $freq_a2; 
      }
    }
  }

  return \%data;
}

sub get_external_data {
  my $self = shift;
  return $self->hub->database('variation')->get_VariationAnnotationAdaptor->fetch_all_by_Variation($self->vari);
}

sub is_somatic_with_different_ref_base {
  my $self = shift;
  return unless $self->Obj->is_somatic;
  # get slice for variation feature
  my @vfs = @{$self->Obj->get_all_VariationFeatures};
  my $feature_slice;
  foreach my $vf (@vfs){
    if ($vf->dbID == $self->hub->core_param('vf')){
      $feature_slice = $vf->feature_Slice;
    }
  }
  return unless $feature_slice;
  my $ref_base = $feature_slice->seq();
  my ($a1, $a2) = split(//,$self->alleles);
  return  $ref_base ne $a1 ? 1 : undef;
}
# Population genotype and allele frequency table calls ----------------

sub pop_genotype_obj {

  ### frequencies_table
  ### Example    : my $pop_genotype_obj = $object->pop_genotype_obj;
  ### Description: gets Population genotypes for this Variation
  ### Returns listref of Bio::EnsEMBL::Variation::PopulationGenotype

  my $self = shift;
  return  $self->vari->get_all_PopulationGenotypes;
}




sub pop_genotypes {

  ### frequencies_table
  ###  Args      : Bio::EnsEMBL::Variation::PopulationGenotype object
  ### Example    : $genotype_freq = $object->pop_genotypes($pop);
  ### Description: gets the Population genotypes
  ### Returns String

  my ($self, $pop_genotype_obj)  = @_;
  return $pop_genotype_obj->genotype_string;
}



sub pop_info {

  ### frequencies_table
  ### Args      : Bio::EnsEMBL::Variation::Population object
  ### Example    : my $data = $self->pop_info
  ### Description: returns a hash with data about this population
  ### Returns hash of data

  my $self = shift;
  my $pop_obj = shift;
  my %data;
  $data{Name}               = $self->pop_name($pop_obj);
  $data{PopLink}            = $self->pop_links($pop_obj);
  $data{Size}               = $self->pop_size($pop_obj);
  $data{Description}        = $self->pop_description($pop_obj);
  $data{"Super-Population"} = $self->extra_pop($pop_obj,"super");
  $data{"Sub-Population"}   = $self->extra_pop($pop_obj,"sub");
  return \%data;
}



sub pop_name {

  ### frequencies_table
  ### Args      : Bio::EnsEMBL::Variation::Population object
  ### Example    : $object->pop_name($pop);
  ### Description: gets the Population name
  ### Returns String

  my ($self, $pop_obj)  = @_;
  return unless $pop_obj;
  return $pop_obj->name;
}



sub pop_id {

  ### frequencies_table
  ### Args      : Bio::EnsEMBL::Variation::Population object
  ### Example    : $object->pop_id($pop);
  ### Description: gets the Population ID
  ### Returns String

  my ($self, $pop_obj)  = @_;
  return unless $pop_obj; 
  return $pop_obj->dbID;
}



sub pop_links {

  ### frequencies_table
  ### Args      : Bio::EnsEMBL::Variation::Population object
  ### Example    : $genotype_freq = $object->pop_links($pop);
  ### Description: gets the Population description
  ### Returns String

  my ($self, $pop_obj)  = @_;
  return $pop_obj->get_all_synonyms("dbSNP");
}



sub pop_size {

  ### frequencies_table
  ### Args      : Bio::EnsEMBL::Variation::Population object
  ### Example    : $genotype_freq = $object->pop_size($pop);
  ### Description: gets the Population size
  ### Returns String

  my ($self, $pop_obj)  = @_;
  return $pop_obj->size;
}



sub pop_description {

  ### frequencies_table
  ### Args      : Bio::EnsEMBL::Variation::Population object
  ### Example    : $genotype_freq = $object->pop_description($pop);
  ### Description: gets the Population description
  ### Returns String

  my ($self, $pop_obj)  = @_;
  return $pop_obj->description;
}



sub extra_pop {

  ### frequencies_table
  ### Args1      : Bio::EnsEMBL::Variation::Population object
  ### Args2      : string "super", "sub"
  ### Example    : $genotype_freq = $object->extra_pop($pop, "super");
  ### Description: gets any super/sub populations
  ### Returns String

  my ($self, $pop_obj, $type)  = @_;
  return {} unless $pop_obj;
  my $call = "get_all_$type" . "_Populations";
  my @populations = @{ $pop_obj->$call};

  my %extra_pop;
  foreach my $pop ( @populations ) {
    my $id = $self->pop_id($pop_obj);
    $extra_pop{$id}{Name}       = $self->pop_name($pop);
    $extra_pop{$id}{Size}       = $self->pop_size($pop);
    $extra_pop{$id}{PopLink}    = $self->pop_links($pop);
    $extra_pop{$id}{Description}= $self->pop_description($pop);
  }
  return \%extra_pop;
}


# Individual table -----------------------------------------------------

sub individual_table {

  ### individual_table_calls
  ### Example    : my $ind_genotypes = $object->individual_table;
  ### Description: gets Individual Genotype data for this variation
  ### Returns hashref with all the data

  my $self = shift;
  my $selected_pop = shift;
  my $individual_genotypes = $self->individual_genotypes_obj($selected_pop);
  return {} unless defined $individual_genotypes && @$individual_genotypes; 
  my %data;
  
  my @ind_ids;
  
  foreach my $ind_gt_obj ( @$individual_genotypes ) { 
    my $ind_obj   = $ind_gt_obj->individual;
    next unless $ind_obj;
    my $ind_id    = $ind_obj->dbID;
    
    push @ind_ids, $ind_id;

    $data{$ind_id}{Name}           = $ind_obj->name;
    $data{$ind_id}{Genotypes}      = $self->individual_genotype($ind_gt_obj);
    $data{$ind_id}{Gender}         = $ind_obj->gender;
    $data{$ind_id}{Description}    = $self->individual_description($ind_obj);
    $data{$ind_id}{Mother}        = $self->parent($ind_obj,"mother");
    $data{$ind_id}{Father}        = $self->parent($ind_obj,"father");
    $data{$ind_id}{Children}      = $self->child($ind_obj);
    $data{$ind_id}{Object}        = $ind_obj;
  }
  
  # Bit of trickery here to get the populations
  # Uses a specially written method in the variation API to get a hash
  # linking individuals to populations
  # This means we do 1 query here instead of 1 per individual
  if(scalar @ind_ids) {
    my $ia = $individual_genotypes->[0]->individual->adaptor;
    my $ip_hash = $ia->_get_individual_population_hash(\@ind_ids);
    
    my (%pops, %pop_links);
    my $pa = $ia->db->get_PopulationAdaptor;
    $pops{$_->dbID} = $_ for @{$pa->fetch_all_by_dbID_list([keys %$ip_hash])};
    $pop_links{$_->dbID} = $self->pop_links($_) for values %pops;
    
    foreach my $pop_id(keys %$ip_hash) {
      foreach my $ind_id(keys %{$ip_hash->{$pop_id}}) {
        next unless defined($data{$ind_id});
        
        push (@{$data{$ind_id}{Population}}, {
          Name => $self->pop_name($pops{$pop_id}),
          Link => $pop_links{$pop_id},
          ID   => $pop_id
        });
      }
    }
  }
  
  return \%data;
}



sub individual_genotypes_obj {

  ### Individual_genotype_table_calls
  ### Example    : my $ind_genotypes = $object->individual_genotypes;
  ### Description: gets IndividualGenotypes for this Variation
  ### Returns listref of IndividualGenotypes

  my $self = shift;
  my $selected_pop = shift;
  my $individuals;
  eval {
    $individuals = $self->vari->get_all_IndividualGenotypes($selected_pop);
  };
  if ($@) {
    warn "\n\n************ERROR************:  Bio::EnsEMBL::Variation::Variation::get_all_IndividualGenotypes fails. $@";
  }
  return $individuals;
}



sub individual_genotype {

  ### Individual_genotype_table_calls
  ### Args      : Bio::EnsEMBL::Variation::IndividualGenotype object
  ### Example    : $genotype_freq = $object->individual_genotypes($individual);
  ### Description: gets the Individual genotypes
  ### Returns String

  my ($self, $individual)  = @_;
  return $individual->genotype_string;

}


sub individual_description {

  ### Individual_genotype_table_calls
  ### Args      : Bio::EnsEMBL::Variation::Individual object
  ### Example    : $genotype_freq = $object->individual_description($individual);
  ### Description: gets the Individual description
  ### Returns String

  my ($self, $individual_obj)  = @_;
  return $individual_obj->description;
}



sub parent {

  ### Individual_genotype_table_calls
  ### Args1      : Bio::EnsEMBL::Variation::Individual object
  ### Arg2      : string  "mother" "father"
  ### Example    : $mother = $object->parent($individual, "mother");
  ### Description: gets any related individuals
  ### Returns Bio::EnsEMBL::Variation::Individual

  my ($self, $ind_obj, $type)  = @_;
  my $call =  $type. "_Individual";
  my $parent = $ind_obj->$call;
  return {} unless $parent;

  # Gender is obvious, not calling their parents
  return  { Name        => $parent->name,
      ### Description=> $self->individual_description($ind_obj),
    };
}


sub child {

  ### Individual_genotype_table_calls
  ### Args      : Bio::EnsEMBL::Variation::Individual object
  ### Example    : %children = %{ $object->extra_individual($individual)};
  ### Description: gets any related individuals
  ### Returns Bio::EnsEMBL::Variation::Individual

  my ($self, $individual_obj)  = @_;
  my %children;

  foreach my $individual ( @{ $individual_obj->get_all_child_Individuals} ) {
    my $gender = $individual->gender;
    $children{$individual->name} = [$gender, 
           $self->individual_description($individual)];
  }
  return \%children;
}


sub get_individuals_pops {

  ### Individual_genotype_table_calls
  ### Args      : Bio::EnsEMBL::Variation::Individual object
  ### Example    : $pops =  $object->get_individuals_pop($individual)};
  ### Description: gets any individual''s populations
  ### Returns Bio::EnsEMBL::Variation::Population

  my ($self, $individual) = @_;
  my @populations = @{$individual->get_all_Populations};
  my @pop_string;

  foreach (@populations) {
    push (@pop_string,  {Name => $self->pop_name($_), 
       Link => $self->pop_links($_), ID => $_->dbID});
  }
  return \@pop_string;
}



# Variation sets ##############################################################

sub get_variation_set_string {
  my $self = shift;
  my @vs = ();
  my $vari_set_adaptor = $self->hub->database('variation')->get_VariationSetAdaptor;
  my $sets = $vari_set_adaptor->fetch_all_by_Variation($self->vari);

  my $toplevel_sets = $vari_set_adaptor->fetch_all_top_VariationSets;
  my $variation_string;
  my %sets_observed; 
  foreach (sort { $a->name cmp $b->name } @$sets){
    $sets_observed{$_->name}  =1 
  } 

  foreach my $top_set (@$toplevel_sets){
    next unless exists  $sets_observed{$top_set->name};
    $variation_string = $top_set->name ;
    my $sub_sets = $top_set->get_all_sub_VariationSets(1);
    my $sub_set_string = " (";
    foreach my $sub_set( sort { $a->name cmp $b->name } @$sub_sets ){ 
      next unless exists $sets_observed{$sub_set->name};
      $sub_set_string .= $sub_set->name .", ";  
    }
    if ($sub_set_string =~/\(\w/){
      $sub_set_string =~s/\,\s+$//;
      $sub_set_string .= ")";
      $variation_string .= $sub_set_string;
    }
    push(@vs,$variation_string);
  }
  return \@vs;
}

sub get_variation_sets {
  my $self = shift;
  my $vari_set_adaptor = $self->hub->database('variation')->get_VariationSetAdaptor;
  my $sets = $vari_set_adaptor->fetch_all_by_Variation($self->vari); 
  return $sets;
}

# Variation mapping ###########################################################


sub variation_feature_mapping { ## used for snpview

  ### Variation_mapping
  ### Example    : my @vari_features = $object->variation_feature_mappin
  ### Description: gets the Variation features found on a variation object;
  ### Returns Arrayref of Bio::EnsEMBL::Variation::VariationFeatures

  my $self = shift;
  my $recalculate = shift;
 
  my %data;
  foreach my $vari_feature_obj (@{ $self->get_variation_features }) { 
     my $varif_id = $vari_feature_obj->dbID;
     $data{$varif_id}{Type}           = $self->region_type($vari_feature_obj);
     $data{$varif_id}{Chr}            = $self->region_name($vari_feature_obj);
     $data{$varif_id}{start}          = $self->start($vari_feature_obj);
     $data{$varif_id}{end}            = $vari_feature_obj->end;
     $data{$varif_id}{strand}         = $vari_feature_obj->strand;
     $data{$varif_id}{transcript_vari} = $self->transcript_variation($vari_feature_obj, undef, $recalculate);
  }
  return \%data;
}


# Calls for variation features -----------------------------------------------

sub unique_variation_feature { 

  ### Variation_features
  ### Description: returns {{Bio::Ensembl::Variation::Feature}} object if
  ### this {{Bio::Ensembl::Variation}} has a unique mapping
  ### Returns undef if no mapping
  ### Returns a arrayref of single Bio::Ensembl::Variation::Feature object if one mapping
  ### Returns a arrayref of Bio::Ensembl::Variation::Feature object if multiple mapping

  my $self = shift;
  my @variation_features = @{ $self->get_variation_features || [] };
  return [] unless  @variation_features;
  return \@variation_features unless $#variation_features > 0; # if unique mapping

  # Must have multiple mapping
  my ($sr, $start, $type) = $self->seq_region_data;
  return \@variation_features unless $sr; #$sr undef if no unique mapping

  my @return;
  foreach (@variation_features) {  # try to find vf which matches unique mapping
    next unless $self->start($_) eq $start;
    next unless $self->region_name($_) eq $sr;
    next unless $self->region_type($_) eq $type;
    push @return, $_;
  }
  return \@return;
}



sub get_variation_features {

  ### Variation_features
  ### Example    : my @vari_features = $object->get_variation_features;
  ### Description: gets the Variation features found  on a variation object;
  ### Returns Arrayref of Bio::EnsEMBL::Variation::VariationFeatures

   my $self = shift; 
   return $self->vari ? $self->vari->get_all_VariationFeatures : [];
}

sub region_type { 

  ### Variation_features
  ### Args      : Bio::EnsEMBL::Variation::Variation::Feature
  ### Example    : my $type = $data->region_type($vari)
  ### Description: gets the VariationFeature slice seq region type
  ### Returns String

  my ($self, $vari_feature) = @_;
  my $slice =  $vari_feature->slice;
  return $slice->coord_system_name if $slice;
}

sub region_name { 
  ### Variation_features
  ### Args      : Bio::EnsEMBL::Variation::Variation::Feature
  ### Example    : my $chr = $data->region_name($vari)
  ### Description: gets the VariationFeature slice seq region name
  ### Returns String
  
  my ($self, $vari_feature) = @_;
  my $slice =  $vari_feature->slice;
  return $slice->seq_region_name() if $slice;
}



sub start {

  ### Variation_features
  ### Args      : Bio::EnsEMBL::Variation::Variation::Feature
  ### Example    : my $vari_start = $object->start($vari);
  ### Description: gets the Variation start coordinates
  ### Returns String

  my ($self, $vari_feature) = @_;
  return $vari_feature->start;
}


sub transcript_variation {

  ### Variation_features
  ### Args[0]    : Bio::EnsEMBL::Variation::Variation::Feature
  ### Args[1]    : string transcript stable id (optional)
  ### Args[2]    : boolean recalculate (optional) - discards DB consequences and recalculates (used for HGMD)
  ### Example    : my $consequence = $object->consequence($vari);
  ### Description: returns SNP consequence (synonymous, stop gained, ...). If a transcript stable id is specifed, will only return transcript_variations on that transcript
  ### Returns arrayref of transcript variation objs

  my ($self, $vari_feature, $tr_stable_id, $recalculate) = @_;
  
  $self->hub->database('variation')->dnadb($self->database('core'));
  
  if($recalculate) {
    $vari_feature->allele_string('A/C/G/T');
    delete $vari_feature->{transcript_variations};
    delete $vari_feature->{dbID};
  }
  
  my $transcript_variation_obj =  $vari_feature->get_all_TranscriptVariations;
  
  return [] unless $transcript_variation_obj;

  my @data;
  foreach my $tvari_obj ( @{ $transcript_variation_obj } )  {
    next unless $tvari_obj->transcript;
    next if $tr_stable_id && $tvari_obj->transcript->stable_id ne $tr_stable_id;
     
    foreach my $tva_obj(@{ $tvari_obj->get_all_alternate_TranscriptVariationAlleles }) {
      my $type = join ", " , map {$_->display_term} @{ $tva_obj->get_all_OverlapConsequences || [] };
  
      push (@data, {
              vf_allele =>        $tva_obj->variation_feature_seq,
              tr_allele =>        $tva_obj->feature_seq,
              conseq =>           $type,
              transcriptname =>   $tvari_obj->transcript->stable_id,
              proteinname  =>     $tvari_obj->transcript->translation ? $tvari_obj->transcript->translation->stable_id : '-',
              cdna_start =>       $tvari_obj->cdna_start,
              cdna_end =>         $tvari_obj->cdna_end,
              cds_start =>        $tvari_obj->cds_start,
              cds_end =>          $tvari_obj->cds_end,
              translation_start =>$tvari_obj->translation_start,
              translation_end =>  $tvari_obj->translation_end,
              pepallele =>        $tva_obj->pep_allele_string,
              codon =>            $tva_obj->display_codon_allele_string,
              tva =>              $tva_obj,
              tv  =>              $tvari_obj,
              vf  =>              $vari_feature,
              hgvs_genomic =>     $tva_obj->hgvs_genomic,
              hgvs_coding =>      $tva_obj->hgvs_coding,
              hgvs_protein =>     $tva_obj->hgvs_protein,
      });
    }
  }

  return \@data;
}



# LD stuff ###################################################################


sub ld_pops_for_snp {

  ### LD
  ### Description: gets an LDfeature container for this SNP and calls all the populations on this
  ### Returns array ref of population IDs

  my $self = shift; 
  my @vari_mappings = @{ $self->unique_variation_feature }; 
  return [] unless @vari_mappings;                    # must have mapping
  return [] unless $self->counts->{'individuals'};    # must have genotypes
  return [] unless $self->vari_class =~ /snp/i;  # must be a SNP or mixed

  my @pops;
  foreach ( @vari_mappings ) {    
    push @pops, map {$_->dbID} @{$_->get_all_LD_Populations};
  }
  return \@pops;
}


sub ld_location {
  my $self = shift;
  my $start = $self->seq_region_start;
  my $end = $self->seq_region_end;
  my $length = $end - $start +1;
  my $offset = (20000 - $length)/2;
  $start -= $offset;
  $end += $offset;
  $start =~s/\.5//;
  $end =~s/\.5//;
  my $location = $self->seq_region_name .":". $start .'-'. $end;
  return $location;
}

sub find_location {

  ### LD
  ### Example    : my $data = $object->find_location
  ### Description: returns the genomic location for the current slice
  ### Returns hash of data

  my $self = shift;
  my $width = shift || $self->param('w') || 50000;
  unless ( $self->{'_slice'} ) {
    $self->_get_slice($width);
  }

  my $slice = $self->{'_slice'};
  return {} unless $slice;
  return $slice->name;
}




sub pop_obj_from_id {

  ### LD
  ### Args      : Population ID
  ### Example    : my $pop_name = $object->pop_obj_from_id($pop_id);
  ### Description: returns population name for the given population dbID
  ### Returns population object

  my $self = shift;
  my $pop_id = shift;
  my $variation_db = $self->database('variation')->get_db_adaptor('variation');
  my $pa  = $variation_db->get_PopulationAdaptor;
  my $pop_obj = $pa->fetch_by_dbID($pop_id);
  return {} unless $pop_obj;
  my %data;
  $data{$pop_id}{Name}    = $self->pop_name($pop_obj);
  $data{$pop_id}{Size}    = $self->pop_size($pop_obj);
  $data{$pop_id}{PopLink} = $self->pop_links($pop_obj);
  $data{$pop_id}{Description}= $self->pop_description($pop_obj);
  $data{$pop_id}{PopObject}= $pop_obj;  ## ok maybe this is cheating..
  return \%data;
}


sub get_default_pop_name {

  ### LD
  ### Example: my $pop_id = $object->get_default_pop_name
  ### Description: returns population id for default population for this species
  ### Returns population dbID

  my $self = shift;
  my $variation_db = $self->database('variation')->get_db_adaptor('variation');
  my $pop_adaptor = $variation_db->get_PopulationAdaptor;
  return unless $pop_adaptor;
  my $pop = $pop_adaptor->fetch_default_LDPopulation();
  return unless $pop;
  return [ $self->pop_name($pop) ];
}

sub location { return $_[0]; }

sub get_source {
  my $self = shift;
  my $default = shift;

  my $vari_adaptor = $self->Obj->adaptor->db->get_db_adaptor('variation');
  unless ($vari_adaptor) {
    warn "ERROR: Can't get variation adaptor";
    return ();
  }

  if ($default) {
    return  $vari_adaptor->get_VariationAdaptor->get_default_source();
  }
  else {
    return $vari_adaptor->get_VariationAdaptor->get_all_sources();
  }

}

=head2 hgvs

 Arg[0]      : int $vfid (optional)
 Description : Returns a hash with unique HGVS strings for the variation and variation feature with allele as key. 
               If multiple mappings, will pick the one specified or alternatively, the one stored in the hub.
 Return type : a hash ref

=cut

sub hgvs {
  my $self = shift;
  my $vfid = shift;
  my $tr_stable_id = shift;
  
  # Pick out the correct variation feature
  my $mappings      = $self->variation_feature_mapping;
  my $mapping_count = scalar keys %$mappings;
  
  # skip if no mapping or somatic mutation with mutation ref base different to ensembl ref base
  return {} unless $mapping_count && !$self->is_somatic_with_different_ref_base; 
  
  if ($mapping_count == 1) {
    ($vfid) = keys %$mappings;
  } elsif (!$vfid) {
    $vfid = $self->hub->param('vf');
  }
  
  return {} unless $vfid;
  
  my $vf = $self->Obj->get_VariationFeature_by_dbID($vfid);
  
  return {} unless $vf;
  
  # Get all transcript variations and put them in a hash with allele seq as key
  my %tvs_by_allele;
  
  push @{$tvs_by_allele{$_->{'vf_allele'}}}, $_ for @{$self->transcript_variation($vf,$tr_stable_id)};

  # Sort the HGVS notations so that LRGs end up last
  $tvs_by_allele{$_} = [ map $_->[1], sort { $a->[0] <=> $b->[0] } map [ $_->{'hgvs_genomic'} =~ /^LRG/ ? 1 : 0, $_ ], @{$tvs_by_allele{$_}} ] for keys %tvs_by_allele;
  
  # Loop over the transcript variations and get the unique (and interesting to us) HGVS notations
  my %hgvs;
  
  foreach my $allele (keys %tvs_by_allele) {
    my %seen_genomic;
    
    # Loop over the transcript variations 
    foreach my $tv (@{$tvs_by_allele{$allele}}) {      
      # Loop over the genomic, coding and protein HGVS strings
      foreach my $type ('hgvs_genomic', 'hgvs_coding', 'hgvs_protein') {
        my $h = $tv->{$type};
        
        next unless $h && $h !~ m/\(p\.=\)/;
        next if $type eq 'hgvs_genomic' && $seen_genomic{$h}++;
        
        push @{$hgvs{$allele}}, $h;
      }
    }
  }
  
  return \%hgvs;
}

sub get_hgvs_names_url {
  my $self        = shift;
  my $display_all = shift;
  
  # Get the HGVS names
  my $hgvs_hash = $self->hgvs(@_);
 
  # Loop over and format the URLs
  my %url;
  
  foreach my $allele (keys %$hgvs_hash) {
    foreach my $hgvs (@{$hgvs_hash->{$allele}}) {
      my $url = $self->hgvs_url($display_all,$hgvs);
      push @{$url{$allele}}, $url ? qq{<a href="$url->[0]">$url->[1]</a>$url->[2]} : $hgvs;
    }
  }
  
  return \%url;
}
  
=head2 hgvs_url

 Arg[0]      : string $hgvs
 Arg[1]      : hashref $params (optional)
 Example     : my $url = hgvs_url('LRG_5_t1.4:c.345G>A',{v => $object->name()});
               echo '<a href="' . $url->[0] . '">' . $url->[1] . '</a>' . $url->[2];
 Description : Returns a listref with the url string, display name and remaining part of the hgvs
 Return type : an array ref

=cut

sub hgvs_url {
  my $self        = shift;
  my $display_all = shift;
  my $hgvs        = shift || '';
  my $params      = shift || {};
  my $obj         = $self->Obj;
  my $hub         = $self->hub;
  my $max_length  = 40;
  
  # Split the HGVS string into components. We are mainly interested in 1) Reference sequence, 2) Version (optional), 3) Notation type (optional) and 4) The rest of the description 
  my ($refseq, $version, $type, $description) = $hgvs =~ m/^((?:ENS[A-Z]*[GTP]\d+)|(?:LRG_\d+[^\.]*)|(?:[^\:]+?))(\.\d+)?\:(?:([mrcgp])\.)?(.*)$/;

  # Return undef if the HGVS could not be properly parsed (i.e. if the refseq and the description could not be obtained)
  return undef unless $refseq && $description;

  my $p = {
    action => 'Summary',
    db     => 'core',
    source => $obj->source,
    v      => $obj->name,
    r      => undef,
  };
  
  my $config_param = ($obj->is_somatic ? 'somatic_mutation_COSMIC=normal' : 'variation_feature_variation=normal') . ($obj->failed_description ? ',variation_set_fail_all=normal' : '');
  
  # Treat the URL differently depending on if it will take us to a regular page or a LRG page
  if ($refseq =~ /^LRG/) {
    my ($id, $tr, $pr) = $refseq =~ m/^(LRG_\d+)\_?(t\d+)?\_?(p\d+)?$/; # Split the reference into LRG_id, transcript and protein
    
    $p->{'type'}    = 'LRG';
    $p->{'lrg'}     = $id;
    $p->{'__clear'} = 1;
     
    if ($type eq 'g') { # genomic position
      $p->{'action'}           = 'Summary';
      $p->{'contigviewbottom'} = $config_param;
    } else {
      $p->{'action'} = 'Variation_LRG';
      $p->{'lrgt'} = "${id}_$tr";
    }
  } else {
    if ($type eq 'g') { # genomic position
      $p->{'type'}             = 'Location';
      $p->{'action'}           = 'View';
      $p->{'contigviewbottom'} = $config_param;
    } elsif ($type eq 'p') { # protein position
      $p->{'type'}   = 'Transcript';
      $p->{'action'} = 'ProtVariations';
      $p->{'t'}      = $refseq;
    } else { # $type eq c: cDNA position, no $type: special cases where the variation falls in e.g. a pseudogene. Default to transcript
      $p->{'type'}   = 'Transcript';
      $p->{'action'} = ($hub->species_defs->databases->{'DATABASE_VARIATION'}->{'#STRAINS'} > 0 ? 'Population' : 'Summary');
      $p->{'t'}      = $refseq;
    }
  }
  
  # Add or override the parameters with the ones supplied to the method
  $p->{$_} = $params->{$_} for keys %$params;
  
  my $hgvs_string;
  if ($display_all) {
    $hgvs_string =   substr($hgvs, length $refseq);
  } else {
    $hgvs_string = substr($hgvs, length $refseq, ($max_length - length $refseq)) . (length $hgvs > $max_length ? '...' : '');
  }
  # Return an arrayref with the elements: [0] -> URL, [1] -> display_name, [2] -> the rest of the HGVS string (capped at a maximum length)
  return [ $hub->url($p), $refseq, $hgvs_string ];
}

1;