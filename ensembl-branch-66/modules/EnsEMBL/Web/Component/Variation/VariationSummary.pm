# $Id: VariationSummary.pm,v 1.39 2011-06-30 11:03:46 sb23 Exp $

package EnsEMBL::Web::Component::Variation::VariationSummary;

use strict;

use base qw(EnsEMBL::Web::Component::Variation);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  return ''; # Currently not in use
}


1;
