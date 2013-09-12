package EnsEMBL::Web::Data::Record::Upload;

use strict;
use warnings;
use base qw(EnsEMBL::Web::Data::Record);

__PACKAGE__->set_type('upload');

__PACKAGE__->add_fields(
  filename         => 'text',
  filesize         => 'int',
  name             => 'text',
  code             => 'text',
  md5              => 'text',
  format           => 'text',
  species          => 'text',
  assembly         => 'text',
  share_id         => 'int',
  analyses         => 'text',
  browser_switches => 'text',
  style            => 'text',
  display          => 'text',
  nearest          => 'text',
  timestamp        => 'int',
);

1;
