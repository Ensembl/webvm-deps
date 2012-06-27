package EnsEMBL::Web::Component::LRG::LRGSNPImage;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::LRG);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
  $self->has_image(1);
}

sub caption {
  return undef;
}

sub _content {
  my $self    = shift;
  my $no_snps = shift; 
  my $object  = $self->object;
  my $image_width  = $self->image_width || 800;  
#  my $context      = $object->param( 'context' ) || 100; 
  my $context      = $object->param( 'context' ) || 'FULL'; 
#  my $extent       = $context eq 'FULL' ? 1000 : $context;
  my $extent       = $context eq 'FULL' ? 5000 : $context;


  my @genes = @{$object->Obj->get_all_Genes('LRG_import')};
  my $lrg_gene = shift @genes;

  my $master_config = $object->get_imageconfig( "lrgsnpview_transcript" );
     $master_config->set_parameters( {
       'image_width' =>  $self->image_width || 800,
       'container_width' => 100,
       'slice_number' => '1|1',
       'context'      => $context,
     });



  # Padding-----------------------------------------------------------
  # Get 4 configs - and set width to width of context config
  # Get two slice -  gene (4/3x) transcripts (+-EXTENT)
  my $Configs;
  my @confs = qw(gene transcripts_top transcripts_bottom);
  push @confs, 'snps' unless $no_snps;  

  foreach( @confs ){ 
    $Configs->{$_} = $object->get_imageconfig( "lrgsnpview_$_" );
    $Configs->{$_}->set_parameters({ 'image_width' => $image_width, 'context' => $context });
  }
  
   $object->get_gene_slices( ## Written...
    $master_config,
    [ 'gene',        'normal', '33%'  ],
    [ 'transcripts', 'munged', $extent ]
  );

  my $transcript_slice = $object->__data->{'slices'}{'transcripts'}[1]; 
  my $sub_slices       =  $object->__data->{'slices'}{'transcripts'}[2];  

  # Fake SNPs -----------------------------------------------------------
  # Grab the SNPs and map them to subslice co-ordinate
  # $snps contains an array of array each sub-array contains [fake_start, fake_end, B:E:Variation object] # Stores in $object->__data->{'SNPS'}
  my ($count_snps, $snps, $context_count) = $object->getVariationsOnSlice( $transcript_slice, $sub_slices  );  
  my $start_difference =  $object->__data->{'slices'}{'transcripts'}[1]->start - $object->__data->{'slices'}{'gene'}[1]->start;

  my @tt = @{$lrg_gene->get_all_Transcripts || []};
  
  $start_difference -= $lrg_gene->start;

#  warn join ' *** ', $transcript_slice->start, $object->Obj->feature_Slice->start, $lrg_gene->start, $tt[0]->start;

  $start_difference = 0;

  
#  warn "START DIFFS $start_difference";

  my @fake_filtered_snps;
  map { push @fake_filtered_snps,
     [ $_->[2]->start + $start_difference,
       $_->[2]->end   + $start_difference,
       $_->[2]] } @$snps;


$Configs->{'gene'}->{'filtered_fake_snps'} = \@fake_filtered_snps unless $no_snps;


  # Make fake transcripts ----------------------------------------------
 $object->store_TransformedTranscripts();        ## Stores in $transcript_object->__data->{'transformed'}{'exons'|'coding_start'|'coding_end'}

  my @domain_logic_names = qw(Pfam scanprosite Prints pfscan PrositePatterns PrositeProfiles Tigrfam Superfamily Smart PIRSF);
  foreach( @domain_logic_names ) { 
    $object->store_TransformedDomains( $_ );    ## Stores in $transcript_object->__data->{'transformed'}{'Pfam_hits'}
  }
  $object->store_TransformedSNPS() unless $no_snps;      ## Stores in $transcript_object->__data->{'transformed'}{'snps'}


  ### This is where we do the configuration of containers....
  my @transcripts            = ();
  my @containers_and_configs = (); ## array of containers and configs

## sort so trancsripts are displayed in same order as in transcript selector table  
  my $strand = $object->Obj->strand;
  my @trans = @{$object->get_all_transcripts};
  my @sorted_trans;
  if ($strand ==1 ){
    @sorted_trans = sort { $b->Obj->external_name cmp $a->Obj->external_name || $b->Obj->stable_id cmp $a->Obj->stable_id } @trans;
  } else {
    @sorted_trans = sort { $a->Obj->external_name cmp $b->Obj->external_name || $a->Obj->stable_id cmp $b->Obj->stable_id } @trans;
  } 

#  $Configs->{'gene'}->{'snps'} = $snps  unless $no_snps;


  foreach my $trans_obj (@sorted_trans ) {  
## create config and store information on it...
    $trans_obj->__data->{'transformed'}{'extent'} = $extent;
    my $CONFIG = $object->get_imageconfig( "lrgsnpview_transcript" );
    $CONFIG->{'geneid'}     = $object->stable_id;
    $CONFIG->{'snps'}       = $snps unless $no_snps;
    $CONFIG->{'subslices'}  = $sub_slices;
    $CONFIG->{'extent'}     = $extent;
    $CONFIG->{'_add_labels'} = 1;

      ## Store transcript information on config....
    my $TS = $trans_obj->__data->{'transformed'};
#        warn Data::Dumper::Dumper($TS);
    $CONFIG->{'transcript'} = {
      'exons'        => $TS->{'exons'},
      'coding_start' => $TS->{'coding_start'},
      'coding_end'   => $TS->{'coding_end'},
      'transcript'   => $trans_obj->Obj,
      'gene'         => $object->Obj,
      $no_snps ? (): ('snps' => $TS->{'snps'})
    }; 
    
    $CONFIG->modify_configs( ## Turn on track associated with this db/logic name
      [$CONFIG->get_track_key( 'gsv_transcript', $object )],
      {qw(display normal show_labels off),'caption' => ''}  ## also turn off the transcript labels...
    );

    foreach ( @domain_logic_names ) { 
      $CONFIG->{'transcript'}{lc($_).'_hits'} = $TS->{lc($_).'_hits'};
    }  

   # $CONFIG->container_width( $object->__data->{'slices'}{'transcripts'}[3] ); 
   $CONFIG->set_parameters({'container_width' => $object->__data->{'slices'}{'transcripts'}[3],   });  
  $CONFIG->tree->dump("Transcript configuration", '([[caption]])')
    if 0;#$object->species_defs->ENSEMBL_DEBUG_FLAGS & $object->species_defs->ENSEMBL_DEBUG_TREE_DUMPS;

   if( $object->seq_region_strand < 0 ) {
      push @containers_and_configs, $transcript_slice, $CONFIG;
    } else {
      ## If forward strand we have to draw these in reverse order (as forced on -ve strand)
      unshift @containers_and_configs, $transcript_slice, $CONFIG;
   }
    push @transcripts, { 'exons' => $TS->{'exons'} };
  }

## -- Map SNPs for the last SNP display --------------------------------- ##
  my $SNP_REL     = 5; ## relative length of snp to gap in bottom display...
  my $fake_length = -1; ## end of last drawn snp on bottom display...
  my $slice_trans = $transcript_slice;

## map snps to fake evenly spaced co-ordinates...
  my @snps2;
  unless( $no_snps ) {
    @snps2 = map {
      $fake_length+=$SNP_REL+1;
      [ $fake_length-$SNP_REL+1 ,$fake_length,$_->[2], $slice_trans->seq_region_name,
        $slice_trans->strand > 0 ?
          ( $slice_trans->start + $_->[2]->start - 1,
            $slice_trans->start + $_->[2]->end   - 1 ) :
          ( $slice_trans->end - $_->[2]->end     + 1,
            $slice_trans->end - $_->[2]->start   + 1 )
      ]
    } sort { $a->[0] <=> $b->[0] } @{ $snps };
## Cache data so that it can be retrieved later...
    #$object->__data->{'gene_snps'} = \@snps2; fc1 - don't think is used
    foreach my $trans_obj ( @{$object->get_all_transcripts} ) {
      $trans_obj->__data->{'transformed'}{'gene_snps'} = \@snps2;
    }
  }

## -- Tweak the configurations for the five sub images ------------------ ##
## Gene context block;
  my $gene_stable_id = $object->gene->stable_id;


## Transcript block
  $gene_stable_id = $lrg_gene->stable_id;

  $Configs->{'gene'}->{'geneid'}      = $gene_stable_id; 
#  $Configs->{'gene'}->set_parameters({ 'container_width' => $object->__data->{'slices'}{'gene'}[1]->length() }); 
  $Configs->{'gene'}->set_parameters({ 'container_width' => $object->Obj->length() }); 

  $Configs->{'gene'}->modify_configs( ## Turn on track associated with this db/logic name
    [$Configs->{'gene'}->get_track_key( 'transcript', $object )],
    {'display'=> 'transcript_nolabel'}  
  );
  $Configs->{'gene'}->modify_configs( ## Turn on track associated with this db/logic name
    ['variation_feature_variation'],
    {'display'=> 'off'}
  ) if $no_snps;
 
  $Configs->{'gene'}->get_node('snp_join')->set('display','off') if $no_snps;
## Intronless transcript top and bottom (to draw snps, ruler and exon backgrounds)
  foreach(qw(transcripts_top transcripts_bottom)) {
    $Configs->{$_}->get_node('snp_join')->set('display','off') if $no_snps;
    $Configs->{$_}->{'extent'}      = $extent;
    $Configs->{$_}->{'geneid'}      = $gene_stable_id;
    $Configs->{$_}->{'transcripts'} = \@transcripts;
    $Configs->{$_}->{'snps'}        = $object->__data->{'SNPS'} unless $no_snps;
    $Configs->{$_}->{'subslices'}   = $sub_slices;
    $Configs->{$_}->{'fakeslice'}   = 1;
    $Configs->{$_}->set_parameters({ 'container_width' => $object->__data->{'slices'}{'transcripts'}[3] }); 
  }
  $Configs->{'transcripts_bottom'}->get_node('spacer')->set('display','off') if $no_snps;
## SNP box track...
  unless( $no_snps ) {
    $Configs->{'snps'}->{'fakeslice'}   = 1;
    $Configs->{'snps'}->{'snps'}        = \@snps2; 
    $Configs->{'snps'}->set_parameters({ 'container_width' => $fake_length }); 
    $Configs->{'snps'}->{'snp_counts'} = [$count_snps, scalar @$snps, $context_count];
  } 

  $master_config->modify_configs( ## Turn on track associated with this db/logic name
    [$master_config->get_track_key( 'gsv_transcript', $object )],
    {qw(display normal show_labels off)}  ## also turn off the transcript labels...
  );

## -- Render image ------------------------------------------------------ ##
  my $image    = $self->new_image([
#    $object->__data->{'slices'}{'gene'}[1],        $Configs->{'gene'},
    $object->Obj,        $Configs->{'gene'},

    $transcript_slice, $Configs->{'transcripts_top'},
    @containers_and_configs,
    $transcript_slice, $Configs->{'transcripts_bottom'},
    $no_snps ? ():($transcript_slice, $Configs->{'snps'})
  ],
  [ $object->stable_id ]
  );
  return if $self->_export_image($image, 'no_text');

  $image->imagemap = 'yes';
  $image->{'panel_number'} = 'top';
  $image->set_button( 'drag', 'title' => 'Drag to select region' );

  my $html = $image->render; 
  if ($no_snps){
    $html .= $self->_info(
      'Configuring the display',
      "<p>Tip: use the '<strong>Configure this page</strong>' link on the left to customise the protein domains  displayed above.</p>"
    );
    return $html;
  }
  my $info_text = config_info($Configs->{'snps'});
  $html .= $self->_info(
    'Configuring the display',
    "<p>Tip: use the '<strong>Configure this page</strong>' link on the left to customise the protein domains and types of variations displayed above.<br />Please note the default 'Context' settings will probably filter out some intronic SNPs.<br />" .$info_text.'</p>'
 );

  return $html;
}

sub config_info {
  my ($self) = @_;
  my $configure_text,

  my $counts = $self->{'snp_counts'};
  return unless ref $counts eq 'ARRAY';

  my $text;
  if ($counts->[0]==0 ) {
    $text .= "There are no SNPs within the context selected for this transcript.";
  } elsif ($counts->[1] ==0 ) {
    $text .= "The options set in the page configuration have filtered out all $counts->[0] variations in this region.";
  } elsif ($counts->[0] == $counts->[1] ) {
    $text .= "None of the variations are filtered out by the Source, Class and Type filters.";
  } else {
    $text .= ($counts->[0]-$counts->[1])." of the $counts->[0] variations in this region have been filtered out by the Source, Class and Type filters.";
  }

  $configure_text .= $text;

# Context filter
  return $configure_text unless defined $counts->[2];

  my $context_text;
  if ($counts->[2]==0) {
    $context_text = "None of the intronic variations are removed by the Context filter.";
  }
  elsif ($counts->[2]==1) {
    $context_text = $counts->[2]." intronic variation has been removed by the Context filter.";
  }
 else {
    $context_text = $counts->[2]." intronic variations are removed by the Context filter.";
  }
#  $self->errorTrack( $context_text, 0, 28 );

  $configure_text .= '<br />' .$context_text;
  return $configure_text;
}

sub content {
  return $_[0]->_content(0);
}

1;

