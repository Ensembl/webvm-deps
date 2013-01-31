# $Id: MLSS.pm,v 1.11.2.1 2013-01-10 16:33:30 ap5 Exp $

package EnsEMBL::Web::Document::HTML::Compara::MLSS;

use strict;

use Math::Round;

use EnsEMBL::Web::Hub;
use EnsEMBL::Web::Document::Table;

use base qw(EnsEMBL::Web::Document::HTML::Compara);

## CONFIGURATION

our $blastz_options = {
  O => 'Gap open penalty',
  E => 'Gap extend penalty',
  K => 'HSP threshold',
  L => 'Threshold for gapped extension',
  H => 'Threshold for alignments between gapped alignment blocks',
  M => 'Masking count',
  T => 'Seed and Transition value',
  Q => 'Scoring matrix',
};

our @blastz_order = qw(O E K L H M T Q); 

our $blastz_parameters = {
  O => 400,
  E => 30,
  K => 3000,
  T => 1,
};

our $tblat_options = {
  minScore => 'Minimum score',
  t        => 'Database type',
  q        => 'Query type',
  mask     => 'Mask out repeats',
  qMask    => 'Mask out repeats on query',     
};

our @tblat_order = qw(minScore t q mask qMask);

our %pretty_method = (
  BLASTZ_NET          => 'BlastZ',
  LASTZ_NET           => 'LastZ',
  TRANSLATED_BLAT_NET => 'Translated Blat',
);

our $references = {
  'Translated Blat' => qq{<a href="http://www.genome.org/cgi/content/abstract/12/4/656\">Kent W, Genome Res., 2002;12(4):656-64</a>},
  'LastZ'           => qq{<a href="http://www.bx.psu.edu/miller_lab/dist/README.lastz-1.02.00/README.lastz-1.02.00a.html">LastZ</a>},
  'BlastZ'          => qq{
    <a href="http://www.genome.org/cgi/content/abstract/13/1/103">Schwartz S et al., Genome Res.;13(1):103-7</a>, 
    <a href="http://www.pnas.org/cgi/content/full/100/20/11484">Kent WJ et al., Proc Natl Acad Sci U S A., 2003;100(20):11484-9</a>
  }
};

## HTML OUTPUT ######################################

sub render { 
  my $self    = shift;
  my $hub     = $self->hub;
  my $mlss_id = $hub->param('mlss');
  my $method  = $hub->param('method');
  my $type    = $pretty_method{$method};
  my $site    = $hub->species_defs->ENSEMBL_SITETYPE;
  my $html;

  my ($alignment_results, $ref_results, $non_ref_results, $pair_aligner_config, $blastz_parameters, $tblat_parameters, $ref_dna_collection_config, $non_ref_dna_collection_config) = $self->fetch_input($mlss_id);

  my $ref_sp          = $ref_dna_collection_config->{'name'};
  my $ref_common      = $ref_dna_collection_config->{'common_name'};
  my $ref_assembly    = $ref_results->{'assembly'};
  my $nonref_sp       = $non_ref_dna_collection_config->{'name'};
  my $nonref_common   = $non_ref_dna_collection_config->{'common_name'};
  my $nonref_assembly = $non_ref_results->{'assembly'};
  my $release         = $pair_aligner_config->{'ensembl_release'};

  ## HEADER AND INTRO
  $html .= sprintf('<h1>%s vs %s %s alignments</h1>',
                        $ref_common, $nonref_common, $pretty_method{$method},
            );

  if ($pair_aligner_config->{'download_url'}) {
    my $ucsc = $pair_aligner_config->{'download_url'};
    $html .= qq{<p>$ref_common (<i>$ref_sp</i>, $ref_assembly) and $nonref_common (<i>$nonref_sp</i>, $nonref_assembly)
alignments were downloaded from <a href="$ucsc">UCSC</a> in $site release $release.</p>};
  }
  else {
    $html .= sprintf '<p>%s (<i>%s</i>, %s) and %s (<i>%s</i>, %s) were aligned using the %s alignment algorithm (%s)
in %s release %s. %s was used as the reference species. After running %s, the raw %s alignment blocks
are chained according to their location in both genomes. During the final netting process, the best
sub-chain is chosen in each region on the reference species.</p>',
              $ref_common, $ref_sp, $ref_assembly, $nonref_common, $nonref_sp, $nonref_assembly,
              $type, $references->{$type}, $site, $release, $ref_common, $type, $type;
  }

  $html .= '<h2>Configuration parameters</h2>';

  ## CONFIG TABLE
  if (keys %$blastz_parameters || keys %$tblat_parameters) {
    my ($rows, $options, @order, $params);
    my $columns = [
      { key => 'param', title => 'Parameter' },
      { key => 'value', title => 'Value'     },
    ];
    
    if ($type eq 'Translated Blat') {
      $options = $tblat_options;
      @order   = @tblat_order;
      $params  = $tblat_parameters;
    } else {
      $options = $blastz_options;
      @order   = @blastz_order;
      $params  = $blastz_parameters;
    }

    push @$rows, { param => "$options->{$_} ($_)", value => $params->{$_} || ($_ eq 'Q' ? 'Default' : '') } for @order;

    $html .= EnsEMBL::Web::Document::Table->new($columns, $rows)->render;
  } else {
    $html .= '<p>No configuration parameters are available.</p>';
  }

  ## CHUNKING TABLE
  if ($ref_dna_collection_config->{'chunk_size'}) {
    $html .= qq{
      <h2>Chunking parameters</h2>
      <table style="width:80%">
        <tr>
          <th style="width:20%;padding:0 1em"></th>
          <th style="width:40%;padding:0 1em">$ref_common</th>
          <th style="width:40%;padding:0 1em">$nonref_common</th>
        </tr>
    };

    my @params = qw(chunk_size overlap group_set_size masking_options);

    foreach my $param (@params) {
      my $header = ucfirst $param;
         $header =~ s/_/ /g;
      my ($value_1, $value_2);
      
      if ($param eq 'masking_options') {
        $value_1 = $ref_dna_collection_config->{$param}     || '';
        $value_2 = $non_ref_dna_collection_config->{$param} || '';
      } else {
        $value_1 = $self->thousandify($ref_dna_collection_config->{$param})     || 0;
        $value_2 = $self->thousandify($non_ref_dna_collection_config->{$param}) || 0;
      }
      
      $html .= qq{
        <tr>
          <th style="padding:1em">$header</th>
          <td style="padding:1em">$value_1</td>
          <td style="padding:1em">$value_2</td>
        </tr>
      };
    } 

    $html .= '</table>';
  }

  ## PIE CHARTS
  $html .= qq{
    <h2>Results</h2>
    <p>Number of alignment blocks: $alignment_results->{'num_blocks'}</p>
    <div class="js_panel">
      <input class="panel_type" type="hidden" value="Piechart" />
      <input class="graph_config" type="hidden" name="colors" value="['#1751A7','#FFFFFF']" />
      <input class="graph_config" type="hidden" name="stroke" value="'#999'" />
      <input class="graph_dimensions" type="hidden" value="[80,80,75]" />
  };

  ## Create HTML blocks for piechart code
  my $i = 0;
  
  foreach my $sp ($ref_sp, $nonref_sp) {
    my $results = $i ? $non_ref_results : $ref_results; 

    foreach my $type ('alignment', 'alignment_exon') {
      my $coverage = $results->{"${type}_coverage"};
      my $total    = $type eq 'alignment' ? $results->{'length'} : $results->{'coding_exon_length'};
      my $percent  = round($coverage/$total * 100);
      my $inverse  = 100 - $percent;

      $html .= qq{<input class="graph_data" type="hidden" value="[$percent,$inverse]" />};
      $i++;
    }
  }

  $html .= '
    <table style="width:100%">
    <tr>
      <th></th>
      <th style="text-align:center">Genome coverage (bp)</th>
      <th style="text-align:center">Coding exon coverage (bp)</th>
    </tr>
  ';

  $i = 0;
  
  foreach my $sp ($ref_sp, $nonref_sp) {
    $html .= qq{
      <tr>
        <th style="vertical-align:middle">$sp</th>
    };
    
    my $results = $i ? $non_ref_results : $ref_results; 

    foreach my $type ('alignment', 'alignment_exon') {
      $html .= '<td style="text-align:center;padding:12px">';
    
      my $coverage = $results->{"${type}_coverage"};
      my $total    = $type eq 'alignment' ? $results->{'length'} : $results->{'coding_exon_length'}; 
      my $percent  = round($coverage/$total * 100);
      my $inverse  = 100 - $percent;

      $html .= qq{
        <div id="graphHolder$i" style="width:160px;height:160px;margin:0 auto"></div>
        <p><b>$percent%</b></p>
      };
      
      $html .= '<p>' . $self->thousandify($coverage) . ' out of ' . $self->thousandify($total).'</p>';
      $html .= '</td>';
      $i++;
    }

    $html .= '</tr>';
  }

  $html .= '</table></div>';

  return $html;
}

## HELPER METHODS ##################################

sub fetch_input {
  my ($self, $mlss_id) = @_;
  
  return unless $mlss_id;
  
  my $hub        = $self->hub;
  my $compara_db = $hub->database('compara');
  my ($results, $ref_results, $non_ref_results, $pair_aligner_config, $blastz_parameters, $tblat_parameters, $ref_dna_collection_config, $non_ref_dna_collection_config);
  
  if ($compara_db) {
    my $genome_db_adaptor             = $compara_db->get_adaptor('GenomeDB');
    my $mlss                          = $compara_db->get_adaptor('MethodLinkSpeciesSet')->fetch_by_dbID($mlss_id);
    my $num_blocks                    = $mlss->get_value_for_tag('num_blocks');
    my $ref_species                   = $mlss->get_value_for_tag('reference_species');
    my $non_ref_species               = $mlss->get_value_for_tag('non_reference_species');
    my $pairwise_params               = $mlss->get_value_for_tag('param');
    my $ref_genome_db                 = $genome_db_adaptor->fetch_by_name_assembly($ref_species);
    my $non_ref_genome_db             = $genome_db_adaptor->fetch_by_name_assembly($non_ref_species);
      
    ## hack for double-quotes
    my $string_ref_dna_collection_config  = $mlss->get_value_for_tag("ref_dna_collection");
    if ($string_ref_dna_collection_config) {
       $string_ref_dna_collection_config =~ s/\"/\'/g;
       $ref_dna_collection_config = eval $string_ref_dna_collection_config;
    }
    my $string_non_ref_dna_collection_config  = $mlss->get_value_for_tag("non_ref_dna_collection");
    if ($string_non_ref_dna_collection_config) {
       $string_non_ref_dna_collection_config =~ s/\"/\'/g;
       $non_ref_dna_collection_config = eval $string_non_ref_dna_collection_config;
    }
 
    $results->{'num_blocks'} = $num_blocks;
    
    $ref_results->{'name'}                    = $ref_genome_db->name;
    $ref_results->{'assembly'}                = $ref_genome_db->assembly;
    $ref_results->{'length'}                  = $mlss->get_value_for_tag('ref_genome_length');
    $ref_results->{'coding_exon_length'}      = $mlss->get_value_for_tag('ref_coding_length');
    $ref_results->{'alignment_coverage'}      = $mlss->get_value_for_tag('ref_genome_coverage');
    $ref_results->{'alignment_exon_coverage'} = $mlss->get_value_for_tag('ref_coding_coverage');
    
    $non_ref_results->{'name'}                    = $non_ref_genome_db->name;
    $non_ref_results->{'assembly'}                = $non_ref_genome_db->assembly;
    $non_ref_results->{'length'}                  = $mlss->get_value_for_tag('non_ref_genome_length');
    $non_ref_results->{'coding_exon_length'}      = $mlss->get_value_for_tag('non_ref_coding_length');
    $non_ref_results->{'alignment_coverage'}      = $mlss->get_value_for_tag('non_ref_genome_coverage');
    $non_ref_results->{'alignment_exon_coverage'} = $mlss->get_value_for_tag('non_ref_coding_coverage');

    $pair_aligner_config->{'method_link_type'} = $mlss->method->type;
    $pair_aligner_config->{'ensembl_release'}  = $mlss->get_value_for_tag('ensembl_release');
    $pair_aligner_config->{'download_url'}     = $mlss->url if $mlss->source eq 'ucsc';
    
    $ref_dna_collection_config->{'name'}        = $self->sci_name($ref_species);
    $ref_dna_collection_config->{'common_name'} = $self->common_name($ref_genome_db->name);
    
    $non_ref_dna_collection_config->{'name'}        = $self->sci_name($non_ref_genome_db->name);
    $non_ref_dna_collection_config->{'common_name'} = $self->common_name($non_ref_genome_db->name);
    
    if ($mlss->method->type eq 'TRANSLATED_BLAT_NET') {
      foreach my $param (split ' ', $pairwise_params) {
        my ($p, $v) = split '=', $param;
        $p =~ s/-//;
        $tblat_parameters->{$p} = $v;
      }
    } else {
      foreach my $param (split ' ', $pairwise_params) {
        my ($p, $v) = split '=', $param;
        
        if ($p eq 'Q' && $v =~ /^\/nfs/) {
          ## slurp in the matrix file
          my @path  = split '/', $v;
          my $file  = $path[-1];
          my $fh    = open IN, $hub->species_defs->ENSEMBL_SERVERROOT . "/public-plugins/ensembl/htdocs/info/docs/compara/$file";
          
          $v  = '<pre>';
          while (<IN>) {
            $v .= $_;
          }
          $v .= '</pre>';
        }
        
        if ($blastz_options->{$p}) {
          $blastz_parameters->{$p} = $v;
        } else {
          $blastz_parameters->{'other'} .= $param;
        }
      }
      ## Set default matrix
      unless ($blastz_parameters->{'Q'}) {
        my $fh    = open IN, $hub->species_defs->ENSEMBL_SERVERROOT . "/public-plugins/ensembl/htdocs/info/docs/compara/default.matrix";
        my $v  = '<pre>Default:
';
        while (<IN>) {
          $v .= $_;
        }
        $v .= '</pre>';
        $blastz_parameters->{'Q'} = $v;
      }
    }
  }
  
  return ($results, $ref_results, $non_ref_results, $pair_aligner_config, $blastz_parameters, $tblat_parameters, $ref_dna_collection_config, $non_ref_dna_collection_config);
}

1;
