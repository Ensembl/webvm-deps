package EnsEMBL::Web::Tools::OpenSearchDescription;

use strict;

sub create {
  ### Returns: none
  my $sd = shift;
  my ($root) = grep -e $_, @{$sd->ENSEMBL_HTDOCS_DIRS||[]};
  
  return unless $root;

  my $template = sprintf '<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription
      xmlns="http://a9.com/-/spec/opensearch/1.1/">
 <ShortName>%s (%%s)</ShortName>
 <Description>Search %s - %%s</Description>
 <InputEncoding>UTF-8</InputEncoding>
 <Tags>Ensembl genome browser %s %%s</Tags>
 <Image width="16" height="16" type="image/png">%s%%s</Image>
 <Url type="text/html"
      template="%s/%%s/psychic?q={searchTerms};site=%%s"/>
</OpenSearchDescription>
', 
  $sd->ENSEMBL_SITE_NAME_SHORT,
  $sd->ENSEMBL_SITE_NAME,
  $sd->ENSEMBL_SITE_NAME,
  $sd->img_url,
  $sd->ENSEMBL_BASE_URL;

  unless( -e "$root/opensearch" ) {
    mkdir "$root/opensearch";
  }
  open O,">$root/opensearch/all.xml";
  printf O $template, 'All', 'All species', 'All species', $sd->ENSEMBL_STYLE->{'SITE_ICON'}, 'common', 'ensembl_all';
  close O;
  foreach( $sd->valid_species ) {
    my $sn = substr( $sd->get_config($_,'SPECIES_BIO_SHORT'),0,5);
    my $cn = $sd->get_config($_,'SPECIES_COMMON_NAME');
    my $bn = $sd->get_config($_,'SPECIES_BIO_NAME');
    open O,">$root/opensearch/$_.xml";
    printf O $template, $sn, "$cn - $bn", "$cn $bn", $sd->ENSEMBL_STYLE->{'SITE_ICON'}, $_, 'ensembl';
    close O;
  }
}

1;
