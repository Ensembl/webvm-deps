# $Id: ModalButtons.pm,v 1.12.2.1 2012-12-17 15:24:16 ap5 Exp $

package EnsEMBL::Web::Document::Element::ModalButtons;

# Generates the tools buttons below the control panel left menu - add track, reset configuration, save configuration

use strict;

use base qw(EnsEMBL::Web::Document::Element::ToolButtons);

sub label_classes {
  return {
    'Save as...'          => 'save',
    'Load configuration'  => 'config-load',
    'Reset configuration' => 'config-reset',
    'Reset track order'   => 'order-reset',
    'Add your data'    => 'data',
  };
}

sub init {
  my $self       = shift;  
  my $controller = shift;
  my $hub        = $controller->hub;
  
  if ($hub->script eq 'Config') {
    my $action       = $hub->action;
    my $image_config = $hub->get_imageconfig($hub->get_viewconfig($action)->image_config);
    my $rel          = "modal_config_$action";
       $rel         .= '_' . lc $hub->species if $image_config && $image_config->multi_species && $hub->referer->{'ENSEMBL_SPECIES'} ne $hub->species;

    $self->add_entry({
      caption => 'Save as...',
      class   => 'save_configuration',
      url     => $hub->url({
        type    => 'UserData',
        action  => 'SaveConfig',
        __clear => 1 
      })
    });
    
    $self->add_entry({
      caption => 'Load configuration',
      class   => 'modal_link',
      rel     => 'modal_manage_cfg',
      url     => $hub->url({
        type    => 'UserConfig',
        action  => 'ManageConfigs',
        __clear => 1 
      })
    });
    
    $self->add_entry({
      caption => 'Reset configuration',
      class   => 'modal_link',
      rel     => $rel,
      url     => $hub->url('Config', {
        reset => 1
      })
    });
    
    if ($image_config) {
      if ($image_config->get_parameter('sortable_tracks')) {
        $self->add_entry({
          caption => 'Reset track order',
          class   => 'modal_link',
          rel     => $rel,
          url     => $hub->url('Config', {
            reset   => 'track_order',
            __clear => 1 
          })
        });
      }
      
      $self->add_entry({
        caption => 'Add your data',
        class   => 'modal_link',
        url     => $hub->url({
          type    => 'UserData',
          action  => 'SelectFile',
          __clear => 1 
        })
      });
    }
  }
}

1;
