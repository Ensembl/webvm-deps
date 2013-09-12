package EnsEMBL::Web::Command::Interface::Delete;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $object = $self->object;
  my $interface = $object->interface;

  my $success;

  if ($interface->permit_delete) {
    $success = $interface->data->destroy;
  }
  else {
    $interface->data->status('inactive');
    $success = $interface->data->save;
  }
  my $type;
  if ($success) {
    $type = 'List';
  }
  else {
    $type = 'Problem';
  }

  my $url = $self->url('/'.$interface->script_name.'/'.$type);
  $self->ajax_redirect($url);
}

1;
