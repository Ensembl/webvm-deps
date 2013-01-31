# $Id: SegFeature.pm,v 1.2 2011-11-09 11:46:09 ma7 Exp $

package EnsEMBL::Web::ZMenu::SegFeature;

use strict;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self              = shift;
  my $hub               = $self->hub; 
  my $object            = $self->object;  
  my $cell_line         = $hub->param('cl');
  my $dbid              = $hub->param('dbid');
     
  my $funcgen_db          = $hub->database('funcgen');
  my $seg_feature_adaptor = $funcgen_db->get_SegmentationFeatureAdaptor; 
  my $seg_feat            = $seg_feature_adaptor->fetch_by_dbID($dbid);  
  my $location            = $seg_feat->slice->seq_region_name . ':' . $seg_feat->start . '-' . $seg_feat->end;
  
  $self->caption('Regulatory Segment - ' . $cell_line);

  $self->add_entry ({
    type   => 'Type',
    label  => $seg_feat->feature_type->name,
  });
  
  $self->add_entry({
    type       => 'Location',
    label_html => $location,
    link       => $hub->url({
      type   => 'Location',
      action => 'View',
      r      => $location
    })
  });
  
  $self->add_entry ({
    type        => 'Analysis',
    label_html  => $seg_feat->analysis->description,
  });
      
}

1;