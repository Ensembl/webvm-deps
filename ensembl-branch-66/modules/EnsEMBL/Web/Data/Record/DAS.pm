package EnsEMBL::Web::Data::Record::DAS;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Data::Record);

__PACKAGE__->set_type('das');

__PACKAGE__->add_fields(
  species     => 'text',
  logic_name  => 'text',
  url         => 'text',
  dsn         => 'text',
  maintainer  => 'text',
  description => 'text',
  on          => 'text',
  homepage    => 'text',
  label       => 'text',
  category    => 'text',
  coords      => 'text',
  _altered    => 'text',
);

1;
