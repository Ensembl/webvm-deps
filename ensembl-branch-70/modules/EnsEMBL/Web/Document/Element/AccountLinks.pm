# $Id: AccountLinks.pm,v 1.3 2012-04-05 12:50:37 sb23 Exp $

package EnsEMBL::Web::Document::Element::AccountLinks;

### Generates links to user account (currently in masthead)

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $species = $hub->species;
     $species = !$species || $species eq 'Multi' || $species eq 'common' ? 'Multi' : $species;
  my $html;
  my $species_defs = $self->species_defs;
  if ($species_defs->has_userdb and $species_defs->ENSEMBL_LOGINS) {
    if ($hub->user) {
      $html .= sprintf '<a class="constant modal_link" style="display:none" href="%s">Account</a>',            $hub->url({ __clear => 1, species => $species, type => 'Account', action => 'Links'  });
      $html .= sprintf ' &middot; <a class="constant" href="%s">Logout</a>',                                   $hub->url({ __clear => 1, species => $species, type => 'Account', action => 'Logout' });
    } else {
      $html .= sprintf '<a class="constant modal_link" style="display:none" href="%s">Login</a>',              $hub->url({ __clear => 1, species => $species, type => 'Account', action => 'Login' });
      $html .= sprintf ' &middot; <a class="constant modal_link" style="display:none" href="%s">Register</a>', $hub->url({ __clear => 1, species => $species, type => 'Account', action => 'User', function => 'Add' });
    }
  }

  return $html;
}

1;
