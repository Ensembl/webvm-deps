# $Id: LogOut.pm,v 1.9 2011-05-19 09:04:46 sb23 Exp $

package EnsEMBL::Web::Command::Account::LogOut;

use strict;

use EnsEMBL::Web::Cookie;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;

  ## setting a (blank) expired cookie deletes the current one
  my $user_cookie = new EnsEMBL::Web::Cookie({
    host    => $species_defs->ENSEMBL_COOKIEHOST,
    name    => $species_defs->ENSEMBL_USER_COOKIE,
    value   => '',
    env     => 'ENSEMBL_USER_ID',
    hash    => {
      offset  => $species_defs->ENSEMBL_ENCRYPT_0,
      key1    => $species_defs->ENSEMBL_ENCRYPT_1,
      key2    => $species_defs->ENSEMBL_ENCRYPT_2,
      key3    => $species_defs->ENSEMBL_ENCRYPT_3,
      expiry  => $species_defs->ENSEMBL_ENCRYPT_EXPIRY,
      refresh => $species_defs->ENSEMBL_ENCRYPT_REFRESH
    }
  });
  
  $user_cookie->clear($self->r);
  $hub->redirect($hub->referer->{'absolute_url'});
}

1;
