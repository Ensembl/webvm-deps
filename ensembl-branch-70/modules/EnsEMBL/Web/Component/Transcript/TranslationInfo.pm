# $Id: TranslationInfo.pm,v 1.2.10.1 2013-02-26 10:45:11 st3 Exp $

package EnsEMBL::Web::Component::Transcript::TranslationInfo;

use strict;

use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self         = shift;
  my $object       = $self->object;
  my $table        = $self->new_twocol;
  my $transcript   = $object->Obj;
  my $translation  = $transcript->translation;

  $table->add_row($self->object->species_defs->ENSEMBL_SITETYPE . ' version', $translation->stable_id.'.'.$translation->version);

  return $table->render;
}

1;

