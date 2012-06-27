# $Id: Compara_Alignments.pm,v 1.13 2011-05-19 09:49:51 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Location::Compara_Alignments;

use strict;

use base qw(EnsEMBL::Web::ViewConfig::Compara_Alignments);

sub init { 
  my $self = shift;
  
  $self->SUPER::init;
  
  $self->set_defaults({
    flank5_display => 0,
    flank3_display => 0,
    strand         => 1
  });
  
  $self->{'no_flanking'}   = 1;
  $self->{'strand_option'} = 1;
}

1;
