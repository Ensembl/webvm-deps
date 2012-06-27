# $Id: FooterLinks.pm,v 1.1 2010-09-28 15:16:58 sb23 Exp $

package EnsEMBL::Web::Document::Element::FooterLinks;

### Generates release info for the footer

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  my $species_defs = shift->species_defs;
  return sprintf '<div class="twocol-right right unpadded">%s release %d - %s</div>', $species_defs->ENSEMBL_SITE_NAME, $species_defs->ENSEMBL_VERSION, $species_defs->ENSEMBL_RELEASE_DATE
}

1;

