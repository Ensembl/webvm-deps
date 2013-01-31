package EnsEMBL::Web::Component::Interface::Add;

### Module to create generic data creation form for Document::Interface and its associated modules

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Interface);
use EnsEMBL::Web::Form;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return $self->object->interface->caption('add') || 'Add a New Record';
}

sub content {
  my $self = shift;
  my $action = $self->object->interface->no_preview ? 'Save': 'Preview';

  my $form = $self->data_form('add', $action);

  ## navigation elements
  $form->add_element( 'type' => 'Submit', 'value' => 'Next');

  return $form->render;
}

1;
