# $Id: ManageConfigs.pm,v 1.20 2013-01-24 17:04:48 sb23 Exp $

package EnsEMBL::Web::Component::UserConfig::ManageConfigs;

use strict;

use base qw(EnsEMBL::Web::Component);

sub content {
  my $self = shift;
  
  return sprintf('
    <input type="hidden" class="panel_type" value="ConfigManager" />
    <div class="config_manager">
      <div class="sets">
        <div class="info">
          <h3>Help</h3>
          <div class="message-pad"><p>You change names and descriptions by clicking on them in the table</p></div>
        </div>
        <h2>Your configurations for this page</h2>
        %s
      </div>
      <div class="edit_set">
        <h4>Select sets for the configuration:</h4>
        %s
      </div>
    </div>',
    $self->records_table,
    $self->sets_table
  );
}

sub records_table {
  my $self        = shift;
  my $hub         = $self->hub;
  my $referer     = $hub->referer;
  my $module_name = "EnsEMBL::Web::Configuration::$referer->{'ENSEMBL_TYPE'}";
  my @components  = $self->dynamic_use($module_name) ? @{$module_name->new_for_components($hub, $referer->{'ENSEMBL_ACTION'}, $referer->{'ENSEMBL_FUNCTION'})} : ();
  my $html;

  if (scalar @components) {
    my $adaptor  = $hub->config_adaptor;
    my $sets     = $adaptor->all_sets;
    my $img_url  = $self->img_url;
    my $editable = qq{<div><div class="heightWrap"><div class="val" title="Click here to edit">%s</div></div>%s<a rel="%s" href="%s" class="save"></a></div>};
    my $list     = qq{<div><div class="heightWrap"><ul>%s</ul></div></div>};
    my $active   = qq{<a class="edit icon_link" href="%s" rel="%s"><div class="sprite _ht use_icon" title="Use this configuration">&nbsp;</div></a><div class="config_used">Configuration applied</div>};
    my (%configs, %rows);
    
    my @columns = (
      { key => 'name',   title => 'Name',          width => '20%',  align => 'left',                  },
      { key => 'desc',   title => 'Description',   width => '20%',  align => 'left',                  },
      { key => 'config', title => 'Configuration', width => '35%',  align => 'left',   sort => 'none' },
      { key => 'sets',   title => 'In sets',       width => '20%',  align => 'left',   sort => 'none' },
      { key => 'active', title => '',              width => '20px', align => 'center', sort => 'none' },
    );
    
    push @columns, { key => 'edit',   title => '', width => '20px', align => 'center', sort => 'none' } if scalar keys %$sets;
    push @columns, { key => 'delete', title => '', width => '20px', align => 'center', sort => 'none' };
    
    foreach (@components) {
      my $view_config = $hub->get_viewconfig(@$_);
      my $component   = $view_config->component;
      my $title       = $view_config->title;
      my $code        = $view_config->code;
         $code        =~ s/^.+?::/$_->[1]::/ unless $code =~ /^$_->[1]::/;
         $configs{$_} = { component => $component, title => $title } for grep $_, $code, $view_config->image_config;
    }
    
    my $filtered_configs = $adaptor->filtered_configs({ code => [ sort keys %configs ] });
    my @config_records   = values %$filtered_configs;
    my %linked_configs   = map { !$_->{'active'} && $_->{'link_id'} ? ($_->{'record_id'} => $_) : () } @config_records;
    
    foreach (sort { $a->{'name'} cmp $b->{'name'} } grep { !$_->{'active'} && !($_->{'type'} eq 'image_config' && $_->{'link_id'}) } @config_records) {
      my $record_id   = $_->{'record_id'};
      my $code        = $_->{'type'} eq 'image_config' && $_->{'link_code'} ? $_->{'link_code'} : $_->{'code'};
      (my $desc       = $_->{'description'}) =~ s/\n/<br \/>/g;
      my ($vc, $ic)   = $_->{'type'} eq 'view_config' ? ($_, $linked_configs{$_->{'link_id'}}) : ($linked_configs{$_->{'link_id'}}, $_); 
      my %params      = ( action => 'ModifyConfig', __clear => 1, record_id => $record_id );
      my @sets        = sort { $a->[0] cmp $b->[0] } map [ $sets->{$_}{'name'}, $sets->{$_}{'record_id'} ], $adaptor->record_to_sets($record_id);
         $sets[0][0] .= ' <b class="ellipsis">...</b>' if scalar @sets > 1;
      my @config;
      
      if ($vc) {
        my $view_config = $hub->get_viewconfig(reverse split '::', $vc->{'code'});
        my $settings    = eval $vc->{'data'} || {};
        
        $view_config->build_form;
        
        my $labels       = $view_config->{'labels'};
        my $value_labels = $view_config->{'value_labels'};
        
        push @config, [ $labels->{$_} || $_, $value_labels->{$_}{$settings->{$_}} || ($settings->{$_} eq lc $settings->{$_} ? ucfirst $settings->{$_} : $settings->{$_}) ] for sort keys %$settings;
      }

      if ($ic) {
        my $image_config = $hub->get_imageconfig($ic->{'code'});
        my $settings     = eval $ic->{'data'} || {};
        
        if ($image_config->multi_species) {
          my $species_defs = $hub->species_defs;
          
          foreach my $species (keys %$settings) {
            my $label        = $species_defs->get_config($species, 'SPECIES_COMMON_NAME');
               $image_config = $hub->get_imageconfig($ic->{'code'}, undef, $species);
            
            while (my ($key, $data) = each %{$settings->{$species}}) {
              push @config, $self->image_config_description($image_config, $key, $data, $label);
            }
          }
        } else {
          while (my ($key, $data) = each %$settings) {
            push @config, $self->image_config_description($image_config, $key, $data);
          }
        }
      }
      
      push @{$rows{$code}}, {
        name   => { value => sprintf($editable, $_->{'name'}, '<input type="text" maxlength="255" name="name" />', $_->{'record_id'}, $hub->url({ function => 'edit_details', %params })), class => 'editable wrap' },
        desc   => { value => sprintf($editable, $desc,        '<textarea rows="5" name="description" />',          $_->{'record_id'}, $hub->url({ function => 'edit_details', %params })), class => 'editable wrap' },
        config => { value => scalar @config ? sprintf($list, join '', map qq{<li>$_->[0]: <span class="cfg">$_->[1]</span></li>}, sort { $a->[0] cmp $b->[0] } @config) : '', class => 'wrap' },
        sets   => { value => scalar @sets   ? sprintf($list, join '', map qq{<li class="$_->[1]">$_->[0]</li>}, @sets)                                                  : '', class => 'wrap' },
        active => sprintf($active, $hub->url({ function => 'activate', %params }), $configs{$code}{'component'}),
        edit   => sprintf('<a class="edit_record icon_link" href="#" rel="%s"><div class="sprite _ht edit_icon" title="Edit sets">&nbsp;</div></a>', $record_id),
        delete => sprintf('<a class="edit icon_link" href="%s" rel="%s"><div class="sprite _ht delete_icon" title="Delete">&nbsp;</div></a>', $hub->url({ function => 'delete', %params, link_id => $_->{'link_id'} }), $record_id),
      };
    }

    foreach (sort keys %rows) {
      $html .= sprintf('
        <div class="config_group">
          %s
          %s
        </div>',
        $configs{$_}{'title'} ? qq{<h4>Configurations for $configs{$_}{'title'}</h4>} : '',
        $self->new_table(\@columns, $rows{$_}, { data_table => 'no_col_toggle', exportable => 0, class => 'fixed editable heightwrap_inside' })->render,
      );
    }
  }

  return $html || '<p>You have no custom configurations for this page.</p>';
}

sub image_config_description {
  my ($self, $image_config, $key, $data, $label) = @_;
  
  return () if $key eq 'track_order';
  
  my $node = $image_config->get_node($key);
  
  return () unless $node;
  
  my $renderers = $node->get('renderers') || [ 'off', 'Off', 'normal', 'On' ];
  my %valid     = @$renderers;
  return [ join(' - ', grep $_, $label, $node->get('caption')), $valid{$data->{'display'}} || $valid{'normal'} || $renderers->[3] ];
}

sub sets_table {
  my $self    = shift;
  my $hub     = $self->hub;
  my @sets    = values %{$hub->config_adaptor->all_sets};
  
  return unless scalar @sets;
  
  my $img_url = $self->img_url;
  my $add     = '<div><a class="add_to_set" href="#" title="Add to set"></a><input type="hidden" name="set_id" class="update" value="%s" /></div>';
  my $wrap    = qq{<div><div class="heightWrap"><div>%s</div></div></div>};
  my @rows;
  
  my @columns = (
    { key => 'name',        title => 'Name',        width => '30%',  align => 'left'                  },
    { key => 'description', title => 'Description', width => '65%',  align => 'left', class => 'wrap' },
    { key => 'add',         title => '',            width => '20px', align => 'center'                },
  );
  
  foreach (sort { $a->{'name'} cmp $b->{'name'} } @sets) {
    push @rows, {
      name        => sprintf($wrap, $_->{'name'}),
      description => { value => sprintf($wrap, $_->{'description'}), class => 'wrap' },
      add         => sprintf($add,  $_->{'record_id'}),
    };
  }
  
  return
    $self->new_table(\@columns, \@rows, { data_table => 'no_col_toggle no_sort', exportable => 0, class => 'fixed' })->render .
    $self->modal_form('', $hub->url({ action => 'ModifyConfig', function => 'edit_sets' }), { label => 'Save', class => 'edit_sets' })->render;
}

1;
