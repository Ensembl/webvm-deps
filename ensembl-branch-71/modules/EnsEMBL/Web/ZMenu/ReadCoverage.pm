# $Id: ReadCoverage.pm,v 1.2 2010-07-12 15:08:18 sb23 Exp $

package EnsEMBL::Web::ZMenu::ReadCoverage;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self       = shift;
  my $hub        = $self->hub;
  my $disp_level = $hub->param('disp_level');
  
  return unless $disp_level;
  
  $self->caption("Resequencing read coverage: $disp_level");
  
  $self->add_entry({
    type  => 'bp',
    label => $hub->param('pos')
  });
  
  $self->add_entry({
    type  => 'Sample',
    label => $hub->param('sp')
  });
  
  $self->add_entry({
    type  => 'Source',
    label => 'Sanger'
  });
}

1;
