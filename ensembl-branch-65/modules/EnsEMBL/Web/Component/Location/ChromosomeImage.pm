package EnsEMBL::Web::Component::Location::ChromosomeImage;

### Module to replace part of the former MapView, in this case displaying 
### an overview image of an individual chromosome 

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Location);

sub _init {
  my $self = shift;
  $self->cacheable( 1 );
  $self->ajaxable(  1 );
  $self->configurable( 1 );
}

sub content {
  my $self = shift;
  my $object = $self->object;

  my $config_name = 'Vmapview';
  my $species   = $object->species;
  my $chr_name  = $object->seq_region_name;

  my $config = $object->get_imageconfig($config_name);
     $config->set_parameters({
       'container_width', $object->Obj->{'slice'}->seq_region_length,
       'slice_number'    => '2|1'
     });
  my $ideo_height = $config->get_parameter('image_height');
  my $top_margin  = $config->get_parameter('top_margin');
  my $hidden = {
    'seq_region_name'   => $chr_name,
    'seq_region_width'  => '100000',
    'seq_region_left'   => '1',
    'seq_region_right'  => $object->Obj->{'slice'}->seq_region_length,
    'click_right'       => $ideo_height+$top_margin,
    'click_left'        => $top_margin,
  };

  $config->get_node('Videogram')->set('label',   ucfirst($object->seq_region_type) );
  $config->get_node('Videogram')->set('label_2', $chr_name );

  #configure two Vega tracks in one
  if ($config->get_node('Vannotation_status_left') && $config->get_node('Vannotation_status_right')) {
    $config->get_node('Vannotation_status_left')->set('display', $config->get_node('Vannotation_status_right')->get('display'));
  }
  my $image    = $self->new_karyotype_image($config);
  $image->image_type         = 'chromosome';
  $image->image_name         = $species.'-'.$chr_name;
  $image->set_button('drag', 'title' => 'Click or drag to jump to a region' );
  $image->imagemap         = 'yes';
  $image->{'panel_number'} = 'chrom';

  ## Add user tracks if turned on
  my @pointers;
  my $user_features = $config->create_user_features;
  if (keys %$user_features) {
    @pointers = $self->create_user_pointers($image, $user_features);
  }

  my $script = $object->species_defs->NO_SEQUENCE ? 'Overview' : 'View';
  $image->karyotype($self->hub, $object, \@pointers, $config_name);
  $image->caption = 'Click on the image above to zoom into that point';
  return $image->render;
}

1;
