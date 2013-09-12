# $Id: IntronSupportingEvidenceAlignment.pm,v 1.1 2013-03-08 17:13:47 st3 Exp $

package EnsEMBL::Web::ZMenu::IntronSupportingEvidenceAlignment;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self       = shift;
  my $hub        = $self->hub;
  my $hit_name   = $hub->param('hit_name');
  my $score      = $hub->param('score');
  $self->caption($hit_name);
  $self->add_entry({
    type  => 'Score',
    label => $score,
  });
}

1;
