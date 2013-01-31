# $Id: ComparaTree.pm,v 1.1 2011-05-19 09:49:04 sb23 Exp $

package EnsEMBL::Web::ViewConfig::GeneTree::ComparaTree;

use strict;

use base qw(EnsEMBL::Web::ViewConfig::Gene::ComparaTree);

sub form { 
  my $self = shift;
  
  $self->SUPER::form;
  
  my $fieldset = $self->get_fieldset(0);
  
  $_->remove for grep scalar @{$_->get_elements_by_name('collapsability')}, @{$fieldset->fields};
}

1;
