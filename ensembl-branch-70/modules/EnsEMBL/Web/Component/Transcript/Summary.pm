# $Id: Summary.pm,v 1.44.2.1 2012-12-18 18:10:47 ds23 Exp $

package EnsEMBL::Web::Component::Transcript::Summary;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

# status warnings would be eg out-of-date page, dubious evidence, etc
# which need to be displayed prominently at the top of a page. Only used
# in Vega plugin at the moment, but probably more widely useful.
sub status_warnings { return undef; }
sub status_hints    { return undef; }

sub content {
  my $self = shift;
  my $object = $self->object;

  return sprintf '<p>%s</p>', $object->Obj->description if $object->Obj->isa('EnsEMBL::Web::Fake');
  return '<p>This transcript is not in the current gene set</p>' unless $object->Obj->isa('Bio::EnsEMBL::Transcript');
  
  my $html = "";
 
  my @warnings = $self->status_warnings;
  if(@warnings>1 and $warnings[0] and $warnings[1]) {
    $html .= $self->_info_panel($warnings[2]||'warning',
                                $warnings[0],$warnings[1]);
  }
  my @hints = $self->status_hints;
  if(@hints>1 and $hints[0] and $hints[1]) {
    $html .= $self->_hint($hints[2],$hints[0],$hints[1]);
  }
  $html .= $self->transcript_table;
  
  if ($object->gene) {
    $html .= $self->_hint('transcript', 'Transcript and Gene level displays', sprintf('
      <p>
        Views in %s are separated into gene based views and transcript based views according to which level the information is more appropriately associated with. 
        This view is a transcript level view. To flip between the two sets of views you can click on the Gene and Transcript tabs in the menu bar at the top of the page.
      </p>', $object->species_defs->ENSEMBL_SITETYPE, $object->species_defs->ENSEMBL_SITETYPE
    ));
  }
  
  return $html;
}

1;
