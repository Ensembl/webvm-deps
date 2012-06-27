package EnsEMBL::Web::Data::Record::URL;

use strict;
use warnings;
use base qw(EnsEMBL::Web::Data::Record);

__PACKAGE__->set_type('url');

__PACKAGE__->add_fields(
  url       => 'text',
  filesize  => 'int',
  species   => 'text',
  code      => 'text',
  name      => 'text',
  nearest   => 'text',
  colour    => 'text',
  style     => 'text',
  display   => 'text',
  format    => 'text',
  timestamp => 'int',
);

1;
