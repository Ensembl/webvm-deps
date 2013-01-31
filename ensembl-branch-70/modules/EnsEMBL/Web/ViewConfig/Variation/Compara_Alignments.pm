# $Id: Compara_Alignments.pm,v 1.1 2012-10-11 16:00:43 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Variation::Compara_Alignments;

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::ViewConfig::Compara_Alignments);

sub init { 
  my $self = shift;
  
  $self->SUPER::init;
  
  # Set a default align parameter (the smallest multiway alignment with available for this species)
  if (!$self->hub->param('align')) {
    my @alignments = map { /species_(\d+)/ && $self->{'options'}{join '_', 'species', $1, lc $self->species} ? $1 : () } keys %{$self->{'options'}};
    my %align;
    
    $align{$_}++ for @alignments;
    
    $self->hub->param('align', [ sort { $align{$a} <=> $align{$b} } keys %align ]->[0]);
  }
  
  $self->set_defaults({
    title_display => 'yes',
  });
}

sub form {
  my $self = shift;
  my %general_markup_options = EnsEMBL::Web::Constants::GENERAL_MARKUP_OPTIONS;
  my %other_markup_options   = EnsEMBL::Web::Constants::OTHER_MARKUP_OPTIONS;
  
  $self->add_form_element($general_markup_options{'line_numbering'});
  $self->add_form_element($other_markup_options{'title_display'});
  $self->alignment_options;
}

1;