# $Id: SaveFavourites.pm,v 1.10 2012-11-07 11:00:28 sb23 Exp $

package EnsEMBL::Web::Command::Account::SaveFavourites;

use strict;

use JSON qw(from_json to_json);

use EnsEMBL::Web::Data::Record::SpeciesList;
use EnsEMBL::Web::Document::HTML::FavouriteSpecies;
use EnsEMBL::Web::Document::HTML::SpeciesList;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub  = $self->hub;
  my $user = $hub->user;
  
  my ($species_list) = $user->specieslists;
  $species_list    ||= EnsEMBL::Web::Data::Record::SpeciesList::User->new;
    
  $species_list->favourites($hub->param('favourites'));
  $species_list->user_id($user->id);
  $species_list->save;

  print to_json({
    list => EnsEMBL::Web::Document::HTML::FavouriteSpecies->new($hub)->render('fragment'),
    dropdown => EnsEMBL::Web::Document::HTML::SpeciesList->new($hub)->render('fragment'),
  });
}

1;
