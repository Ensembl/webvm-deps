# $Id: ResetFavourites.pm,v 1.4 2011-05-19 09:05:01 sb23 Exp $

package EnsEMBL::Web::Command::Account::ResetFavourites;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub  = $self->hub;
  my $user = $hub->user;
  $user->specieslists->delete_all;
  $hub->redirect($hub->species_defs->ENSEMBL_BASE_URL);
}

1;
