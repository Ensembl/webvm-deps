# $Id: LogOut.pm,v 1.10 2012-08-09 14:31:06 hr5 Exp $

package EnsEMBL::Web::Command::Account::LogOut;

use strict;

use EnsEMBL::Web::Cookie;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;

  $hub->clear_cookie($species_defs->ENSEMBL_USER_COOKIE);

  $hub->redirect($hub->referer->{'absolute_url'});
}

1;
