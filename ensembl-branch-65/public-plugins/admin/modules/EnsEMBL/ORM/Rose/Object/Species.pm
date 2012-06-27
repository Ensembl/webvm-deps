package EnsEMBL::ORM::Rose::Object::Species;

### NAME: EnsEMBL::ORM::Rose::Object::Species
### ORM class for the species table in ensembl_production

### STATUS: Stable 

use strict;
use warnings;

use base qw(EnsEMBL::ORM::Rose::Object::Trackable);

use constant ROSE_DB_NAME => 'production';

## Define schema
__PACKAGE__->meta->setup(
  table       => 'species',

  columns     => [
    species_id        => {type => 'serial', primary_key => 1, not_null => 1}, 
    db_name           => {type => 'varchar', 'length' => 255 },
    common_name       => {type => 'varchar', 'length' => 255 },
    web_name          => {type => 'varchar', 'length' => 255 },
    taxon             => {type => 'varchar', 'length' => 20 },
    species_prefix    => {type => 'varchar', 'length' => 20 },
    is_current        => {type => 'integer'},
  ],
  
  unique_key            => ['db_name'],
  title_column          => 'web_name',
  inactive_flag_column  => 'is_current',

  relationships         => [
    changelog         => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::ChangelogSpecies',
      'map_from'    => 'species',
      'map_to'      => 'changelog',
    },
    meta_key          => {
      'type'        => 'many to many',
      'map_class'   => 'EnsEMBL::ORM::Rose::Object::MetaKeySpecies',
      'map_from'    => 'species',
      'map_to'      => 'meta_key',
    },
    analysis_web_data => {
      'type'        => 'one to many',
      'class'       => 'EnsEMBL::ORM::Rose::Object::AnalysisWebData',
      'column_map'  => {'species_id' => 'species_id'}
    }
  ],
);

1;