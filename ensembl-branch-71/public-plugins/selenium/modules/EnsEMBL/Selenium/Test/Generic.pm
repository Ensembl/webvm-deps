# $Id: Generic.pm,v 1.17.6.4 2013-04-09 11:14:48 ma7 Exp $
package EnsEMBL::Selenium::Test::Generic;
use strict;
use base 'EnsEMBL::Selenium::Test';
use Test::More; 

__PACKAGE__->set_default('timeout', 50000);

#------------------------------------------------------------------------------
# Ensembl generic test
#------------------------------------------------------------------------------
sub test_homepage {
 my ($self, $links) = @_;
 my $sel          = $self->sel;
 my $SD           = $self->get_species_def;   
 my $this_release = $SD->ENSEMBL_VERSION;
 my $location     = $self->get_location();  

 $sel->open_ok("/"); 

 $sel->ensembl_wait_for_page_to_load
 and $sel->ensembl_is_text_present("Ensembl release $this_release")
 and $sel->ensembl_is_text_present("What's New in Release $this_release")
 and $sel->ensembl_is_text_present('Did you know')
 and $sel->ensembl_click_links(["link=View full list of all Ensembl species"]);
 
 $sel->go_back();
 $sel->ensembl_wait_for_page_to_load;
 $sel->ensembl_click_links(["link=acknowledgements page"]); 
 
}

sub test_species_list {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $SD = $self->get_species_def;
 my $release_version = $SD->ENSEMBL_VERSION;
 my @valid_species = $SD->valid_species;
 my $url = $self->url;
 
 $sel->open_ok("/info/about/species.html");

 foreach my $species (@valid_species) {   
   my $species_label = $SD->species_label($species,1);

   $species_label =~ s/(\s\(.*?\))// if($species_label =~ /\(/);    
   $sel->ensembl_click_links(["link=$species_label"],'10000');

   #my $species_image = qq{pic_$species};
   #$species_image = qq{pic_Pongo_pygmaeus} if($species eq 'Pongo_abelii'); #hack for Pongo as it is the only species which did not follow the species image naming rule. 

   #CHECK FOR SPECIES IMAGES
   $sel->run_script(qq{
     var x = jQuery.ajax({
                    url: '$url/i/species/64/$species.png',
                    async: false,
              }).state();
     if (x == 'resolved') {
       jQuery('body').append("<p>Species images present</p>");
     }
  });
    my $species_latin_name = $SD->get_config($species,'SPECIES_BIO_NAME');
    $species_label =~ s/Ciona /C./g; #species label shorten for Ciona
    $sel->ensembl_is_text_present("Species images present")
    and $sel->ensembl_is_text_present($species_latin_name)
    and $sel->ensembl_is_text_present("What's New in $species_label release $release_version");
    
    $sel->go_back();
 }
}

sub test_blog {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 
 $sel->open_ok("/"); 
 #$sel->ensembl_wait_for_page_to_load_ok;
 $sel->ensembl_click("link=More release news on our blog ?");
 $sel->ensembl_wait_for_page_to_load("50000")
 and $sel->ensembl_is_text_present('Category Archives'); 
}

sub test_robots_file {
  my ($self, $links) = @_;
  my $sel = $self->sel;
  
  next unless $sel->open_ok("/robots.txt")
  and $sel->ensembl_is_text_present('User-agent: *')
  and $sel->ensembl_is_text_present('Disallow:*/Gene/A*')
  and $sel->ensembl_is_text_present('Sitemap: http://www.ensembl.org/sitemap-index.xml');
}

sub test_sitemap {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $sitemap_url = $self->url =~ /test.ensembl.org/ ? "$sel->{browser_url}/sitemaps/sitemap-index.xml" : "$sel->{browser_url}/sitemap-index.xml";

 next unless $sel->open_ok("$sitemap_url");  #ignore just a dummy open so that we can get the url, will always return ok
 my $response = $sel->ua->get("$sitemap_url");

 ok($response->is_success, 'Request for sitemap was successful') 
 and ok($response->decoded_content =~ /sitemapindex/, "First line contains 'sitemapindex'")
 and ok($response->decoded_content =~ /sitemap_Homo_sapiens_1\.xml/, "Home Sapiens xml is present");
}

sub test_doc {
 my ($self, $links) = @_;
 my $sel      = $self->sel;
 my $location = $self->get_location();
 my @skip_link = ("Home");
 
 $sel->open_ok("/info/index.html");
 print "URL:: $location \n\n" unless $sel->ensembl_wait_for_page_to_load; 
 $sel->ensembl_click_all_links('#main', \@skip_link); 
}

sub test_faq {
  my ($self, $links) = @_;
  my $sel      = $self->sel;
  my $location = $self->get_location(); 
  
  $sel->open_ok("/");
  print "URL:: $location \n\n" unless $sel->ensembl_wait_for_page_to_load; 
  
  my @skip_link = ("Home", "contact our HelpDesk", "developers' mailing list");
  
  $sel->ensembl_click_ok("link=FAQs",'50000')
  and $sel->wait_for_pop_up_ok("", "5000")
  and $sel->select_window_ok("name=popup_selenium_main_app_window")  #thats only handling one popup with no window name cannot be used for multiple popups
  and $sel->ensembl_click_all_links(".content", \@skip_link, 'More FAQs');
}

sub test_login {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $location = $self->get_location(); 

 $sel->open_ok("/");
 
 $sel->ensembl_click("link=Login/Register")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000)
 and $sel->type_ok("name=email", "ma7\@sanger.ac.uk")
 and $sel->type_ok("name=password", "selenium")
 and $sel->ensembl_click("name=submit")
 and $sel->ensembl_wait_for_page_to_load; 
 
 $sel->ensembl_click_links(["link=Logout"]);
 #$sel->ensembl_wait_for_page_to_load_ok;
}

sub test_register {
 my ($self, $links) = @_;
 my $sel = $self->sel;

 $sel->open_ok("/");
 #$sel->ensembl_wait_for_page_to_load_ok;
 $sel->ensembl_click("link=Login/Register")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000);
 
 $sel->ensembl_click("link=Register")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000);
 
 $sel->ensembl_is_text_present("Name");
 
 $sel->ensembl_click("link=Lost Password")
 and $sel->ensembl_wait_for_ajax_ok(undef,5000)
 and $sel->ensembl_is_text_present("If you have lost your password");
}

sub test_search {
 my ($self, $links) = @_;
 my $sel      = $self->sel;
 my $location = $self->get_location();

 $sel->open_ok("/");
 #$sel->ensembl_wait_for_page_to_load_ok;
 
 $sel->type_ok("name=q", "BRCA2");
 $sel->ensembl_click_links(["//input[\@type='image']"]);
 #$sel->ensembl_wait_for_page_to_load_ok;
 $sel->ensembl_is_text_present("returned the following results:");
 $sel->ensembl_click("link=Gene");
 $sel->ensembl_is_text_present("Human (");
 
 next unless $sel->open_ok("/Homo_sapiens/Search/Details?species=Homo_sapiens;idx=Gene;q=brca2");  
 print "URL:: $location \n\n" unless $sel->ensembl_wait_for_page_to_load;
 $sel->ensembl_is_text_present("Genes match your query");  
}

sub test_contact_us {
 my ($self, $links) = @_;
 my $sel = $self->sel;
 my $sd = $self->get_species_def;

 $sel->open_ok("/");
 #$sel->ensembl_wait_for_page_to_load_ok;
 
 $sel->ensembl_click_links(["link=Contact Us"]);
 $sel->ensembl_is_text_present("Contact Ensembl");
 $sel->ensembl_click("link=email Helpdesk"); 
 $sel->wait_for_pop_up_ok("", "5000");
 $sel->select_window_ok("name=popup_selenium_main_app_window");  #thats only handling one popup with no window name cannot be used for multiple popups
 ok($sel->get_title !~ /Internal Server Error|404 error/i, 'No Internal or 404 Server Error')
 and $sel->ensembl_is_text_present("Your name");
 $sel->close();
 $sel->select_window();
}
1;
