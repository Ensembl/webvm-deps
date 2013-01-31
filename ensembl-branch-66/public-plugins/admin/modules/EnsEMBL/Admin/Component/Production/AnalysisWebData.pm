package EnsEMBL::Admin::Component::Production::AnalysisWebData;

use strict;

use base qw(EnsEMBL::Admin::Component::Production);

sub caption {
  return '';
}

sub content {
  my $self = shift;
  
  my $hub     = $self->hub;
  my $records = $self->object->rose_objects;

  my $content = $self->dom->create_element('div', {'class' => '_tabselector'});
  my $buttons = $content->append_child('div', {'class' => 'ts-buttons-wrap'});
  my $tabs    = $content->append_child('div', {'class' => 'spinner ts-spinner _ts_loading'});

  my $groups  = {};

  ## create a data structure of all the records
  foreach my $record (@$records) {
    foreach my $groupby (qw(web_data_id analysis_description_id species_id db_type)) {
      my $val = $record->$groupby;
      push @{$groups->{$groupby}{$_ || '0'} ||= []}, $record for ref $val eq 'ARRAY' ? @$val : $val;
    }
  }

  ## Iterate through the data structure to print the list
  foreach my $key (sort keys %$groups) {

    (my $method = $key) =~ s/_id$//;

    $buttons->append_child('a', {'class' => '_ts_button ts-button', 'href' => "#$method", 'inner_HTML' => join(' ', map {(ucfirst $_)} split '_', $method)});
    my $tab = $tabs->append_child('div', {'class' => '_ts_tab ts-tab prod-list'});
    my @bg  = qw(bg1 bg2);

    for (sort keys %{$groups->{$key}}) {

      ## add to the list
      $tab->append_child('div', {
        'class'       => "prod-group $bg[0]",
        'inner_HTML'  => sprintf(
          '<span%s>%s</span> (<a href="%s">%d records</a>)',
          $method eq 'web_data' ? ' class="_datastructure"' : '',
          $method eq 'db_type'  ? $_ : $self->get_printable($groups->{$key}{$_}[0]->$method),
          $hub->url({'action' => 'LogicName', $key => $_}),
          scalar @{$groups->{$key}{$_}}
        )
      });

      @bg = reverse @bg;
    }
    
    $tab->first_child->set_attribute('class', 'prod-group-first');
    $tab->last_child->set_attribute('class', 'prod-group-last');

  }

  return $content->render;
}

1;