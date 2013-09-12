# $Id: LDImage.pm,v 1.3 2011-11-16 13:13:10 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Location::LDImage;

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self     = shift;
  my %options  = EnsEMBL::Web::Constants::VARIATION_OPTIONS;
  my $defaults = {};

  foreach (keys %options) {
    my %hash = %{$options{$_}};
    $defaults->{lc $_} = $hash{$_}[0] for keys %hash;
  }
  
  $self->set_defaults($defaults);
  $self->add_image_config('ldview', 'nodas');
  $self->title = 'Linkage Disequilibrium'; 
}

sub extra_tabs {
  my $self = shift;
  my $hub  = $self->hub;
  
  return [
    'Select populations',
    $hub->url('Component', {
      action   => 'Web',
      function => 'SelectPopulation/ajax',
      time     => time,
      %{$hub->multi_params}
    })
  ];
}

1;
