# $Id: Location.pm,v 1.20.2.1 2013-04-08 12:11:43 ma7 Exp $
package EnsEMBL::Selenium::Test::Location;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);
#------------------------------------------------------------------------------
# Ensembl Location link test
# Can add more cases or extend the existing test cases
#------------------------------------------------------------------------------
sub test_location {
  my ($self) = @_;
  my $sel    = $self->sel;
  my $SD     = $self->get_species_def;
  my $sp_bio_name = $SD->get_config($self->species,'SPECIES_BIO_NAME'); 

  $self->open_species_homepage($self->species,undef, $sp_bio_name);  
  my $location_text = $SD->get_config(ucfirst($self->species), 'SAMPLE_DATA')->{LOCATION_TEXT};

  if($location_text) {
    $sel->ensembl_click_links(["link=Example region"]);
    my @location_array = split(/\:/,$location_text);
    $sel->ensembl_is_text_present($SD->thousandify(@location_array[1]))
    and $sel->ensembl_is_text_present("Region in detail");
#    and $sel->ensembl_images_loaded;

    $sel->ensembl_click("link=Configure this page") and $sel->ensembl_wait_for_ajax_ok(undef,4000);

    #turn ncRNA track on/off(only for the species having ncrna tracks)
     if($sel->is_text_present("ncRNA(")){
      $sel->ensembl_click("modal_bg");
      
      $self->turn_track("ncRNA", "//form[\@id='location_viewbottom_configuration']/div[4]/div/ul/li", "on");
      $self->turn_track("ncRNA", "//form[\@id='location_viewbottom_configuration']/div[4]/div/ul/li", "off");      
      #next;
    } else {
      print "  No ncRNA Tracks \n";
      $sel->ensembl_click("modal_bg");
    }

    #Test ZMENU (only for human)
    if(lc($self->species) eq 'homo_sapiens') {
      #Searching and adding decipher track
      $self->turn_track("Variation","//form[\@id='location_viewbottom_configuration']/div[5]/div[7]/div/ul[3]/li", "on", "decipher");
      
      #simulate ZMenu for this track (decipher)
      $sel->pause(5000); #pausing a bit to make sure the location panel loads fine from adding the track
      $sel->ensembl_open_zmenu('ViewBottom',"href*=decipher","Decipher track");
      $sel->ensembl_is_text_present("decipher:");
      
      #Test attach das
      $self->attach_das;
      $sel->ensembl_wait_for_ajax_ok(25000,7000);
      
      $sel->ensembl_open_zmenu('Summary',"class^=drag");
      $sel->ensembl_click("link=Centre here")
      and $sel->ensembl_wait_for_ajax_ok(undef,'5000');           
      
      #$sel->go_back(); #for some reason the page is not going back but just the bottom panel gets reloaded so we click through other links to get back to where we were
      $sel->ensembl_click("link=Human*")
      and $sel->ensembl_wait_for_ajax_ok(undef,'5000')
      and $sel->ensembl_click("link=Example region")
      and $sel->ensembl_wait_for_ajax_ok(undef,'5000');
      
      #TODO:: ZMenu on viewtop and ViewBottom panel
    }
    #Whole genome link    
    $sel->ensembl_click_links(["link=Whole genome"]);
    $sel->ensembl_is_text_present("This genome has yet to be assembled into chromosomes") if(!scalar @{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')});

    @location_array[0] =~ s/chr//;
    #Chromosome summary link (only click for sepcies with chromosome)
    if(grep(/@location_array[0]/,@{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')})) {
      $sel->ensembl_click_links(["link=Chromosome summary"]);
      $sel->ensembl_is_text_present("Chromosome Statistics");
    }

    $sel->ensembl_click_links(["link=Region overview","link=Region in detail","link=Comparative Genomics"]);

    my %synteny_hash  = $SD->multi('DATABASE_COMPARA', 'SYNTENY');    
    my $synteny_count = scalar keys %{$synteny_hash{ucfirst($self->species)}};
    my %alignments    = $SD->multi('DATABASE_COMPARA', 'ALIGNMENTS');
    
    my ($alignment_count,$multi_species_count) = $self->alignments_count($SD);

    if($alignment_count) {
      $sel->ensembl_click_links(["link=Alignments (image) ($alignment_count)"],'20000');
      
      if(lc($self->species) eq 'homo_sapiens' || lc($self->species) eq 'mus_musculus') {
        $sel->select_ok("align", "label=13 eutherian mammals EPO")
        and $sel->ensembl_click("link=Go")
        and $sel->ensembl_wait_for_page_to_load(60000);
      }
      
      $sel->ensembl_click_links(["link=Alignments (text) ($alignment_count)","link=Region Comparison*"],'20000');
    }
    $sel->ensembl_click_links(["link=Synteny ($synteny_count)"], '20000') if(grep(/@location_array[0]/,@{$SD->get_config(ucfirst($self->species), 'ENSEMBL_CHROMOSOMES')}) && $synteny_count);

    #Markers
    if($SD->table_info_other(ucfirst($self->species),'core', 'marker_feature')->{'rows'}) {
      $sel->ensembl_click_links(["link=Markers"]);

      if(lc($self->species) eq 'homo_sapiens') {
        $sel->ensembl_is_text_present("mapped markers found:");
        $sel->ensembl_click_links(["link=D6S989"]);
        $sel->ensembl_is_text_present("Marker D6S989");
        $sel->go_back();
      }
    }

    my $resequencing_counts = $SD->databases(ucfirst($self->species))->{'DATABASE_VARIATION'}{'#STRAINS'} if exists $SD->databases(ucfirst($self->species))->{'DATABASE_VARIATION'};
    $sel->ensembl_click_links(["link=Resequencing ($resequencing_counts)"]) if($resequencing_counts);
    
    #Testing genetic variations last for human only
    if(lc($self->species) eq 'homo_sapiens') {      
      $sel->type_ok("loc_r", "6:27996744-27996844");
      $sel->ensembl_click("link=Go");
      $sel->pause(15000);
      $sel->ensembl_is_text_present("Basepairs in secondary ");

      $sel->open_ok("Homo_sapiens/Location/LD?db=core;r=6:27996744-27996844;pop1=12131");
      $sel->pause(5000);
      $sel->ensembl_is_text_present("Prediction method");
      
      $sel->ensembl_click_links(["link=Region in detail"]);
      $self->export_data('CSV (Comma separated values)','seqname,source');
    }

  } else {
    print "  No Location \n";
    $sel->ensembl_is_text_present("Location (not available)");
  }
}
1;
