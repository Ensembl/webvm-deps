# $Id: GenomeStatistics.pm,v 1.6 2012-10-17 13:48:40 ma7 Exp $
package EnsEMBL::Selenium::Test::GenomeStatistics;
use strict;
use base 'EnsEMBL::Selenium::Test::Species';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);
#------------------------------------------------------------------------------
# Ensembl Genome Statistics test
# Can add more cases or extend the existing test cases
#------------------------------------------------------------------------------
sub test_genome_statistics {
  my $self = shift;
  my $sel  = $self->sel;
  my $SD = $self->get_species_def;
  my $sp_bio_name = $SD->get_config($self->species,'SPECIES_BIO_NAME');  
  my $release_version = $SD->ENSEMBL_VERSION;

  $self->open_species_homepage($self->species,undef, $sp_bio_name);
  
  $sel->ensembl_click("link=More information and statistics"); #Link to genome statistics page on New species home page  
# $sel->ensembl_click_links(["//a[contains(\@href,'/Info/StatsTable')]"]); #Assembly and Genebuild page
  $sel->pause(1000);
  $sel->ensembl_is_text_present("assembly")
  and $sel->ensembl_is_text_present("annotation");  
  
#  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop40')]"]); #Top 40 InterPro hits
#  $sel->ensembl_is_text_present("InterPro name");
  
#  $sel->ensembl_click_links(["//a[contains(\@href,'Info/IPtop500')]"]); #Top 500 InterPro hits
#  $sel->ensembl_is_text_present("InterPro name");

# This is now a box on the new species home page and test move to Generic.pm in species_list sub
# $sel->ensembl_click_links(["//a[contains(\@href,'Info/WhatsNew')]"]);
# $sel->ensembl_is_text_present("What's New in Release $release_version");
}
1;
