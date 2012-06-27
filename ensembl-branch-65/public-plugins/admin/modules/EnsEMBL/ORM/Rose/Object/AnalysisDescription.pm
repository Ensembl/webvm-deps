package EnsEMBL::ORM::Rose::Object::AnalysisDescription;

### NAME: EnsEMBL::ORM::Rose::Object::AnalysisDescription
### ORM class for the biotype table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table         => 'analysis_description',

  columns       => [
    analysis_description_id => {type => 'serial', primary_key => 1, not_null => 1}, 
    logic_name              => {type => 'varchar', 'length' => 128 },
    description             => {type => 'text'},
    display_label           => {type => 'varchar', 'length' => 256 },
  ],

  title_column  => 'logic_name',

  unique_key    => ['logic_name'],

  relationships => [
    analysis_web_data => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::AnalysisWebData',
      'column_map'  => {'analysis_description_id' => 'analysis_description_id'}
    },
  ],
);

1;