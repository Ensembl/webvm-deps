# $Id: Alignments.pm,v 1.7 2011-04-11 11:37:46 ma7 Exp $

package EnsEMBL::Web::Component::Export::Alignments;

use strict;

use URI::Escape qw(uri_unescape);

use EnsEMBL::Web::Constants;

use base 'EnsEMBL::Web::Component::Export';

sub content {
  my $self  = shift;
  my $hub   = $self->hub;
  my $align = $hub->referer->{'params'}->{'align'}->[0];
  
  my $params = {
    action   => 'Location', 
    type     => 'Export/Output', 
    function => 'Alignment',
    output   => 'alignment',
    align    => $align
  };
  
  my $form = $self->modal_form('export_output_configuration', '#', { no_button => 1, method => 'get' });
  
  $form->add_fieldset;
  
  if ($align) {
    my $href    = uri_unescape($hub->url($params));
    my %formats = EnsEMBL::Web::Constants::ALIGNMENT_FORMATS;
    my @list    = map qq{<a class="modal_close" href="$href;format=$_;_format=Text" rel="external">$formats{$_}</a>}, sort keys %formats;
    
    $form->add_notes({ class => undef, text => 'Please choose a format for your exported data' });
    $form->add_notes({ class => undef, list => \@list });
  } else {
    $form->add_notes({ class => undef, text => 'Please choose an alignment to export on the main page' });
  }
  
  return '<h2>Export Configuration - Genomic Alignments</h2>' . $form->render;
}

1;
