# $Id: View.pm,v 1.12 2010-10-12 10:47:21 sb23 Exp $

package EnsEMBL::Web::Component::Blast::View;

use strict;

use base qw(EnsEMBL::Web::Component::Blast);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
  $self->configurable(0);
}

sub colours { return qw(gold orange chocolate firebrick darkred); }

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $html         = sprintf '<h2>%s Blast Results</h2>', $species_defs->ENSEMBL_SITETYPE;
  my ($species, $alignments) = $self->object->retrieve_data;

  if (ref $alignments eq 'ARRAY' && scalar @$alignments) {
    ## Display alignments in various ways!

    ## Summary
    (my $species_name = $species) =~ s/_/ /g;
    
    $html .= "<h3>Displaying unnamed sequence alignments vs $species_name LATESTGP database</h3>";
    $html .= "<h3>Alignment location vs karyotype</h3>"; ## Karyotype (if available)
    
    if ($species_defs->get_config($species, 'ENSEMBL_CHROMOSOMES')) {
      $html .= $self->draw_karyotype($species, $alignments);
    } else {
      $html .= '<p>Sorry, this species has not been assembled into chromosomes</p>';
    }

    ## Alignment image
    $html .= $self->draw_key;
    $html .= '<h3>Alignment locations vs query</h3>';
    $html .= $self->draw_alignment($species, $alignments);

    ## Alignment table
    $html .= '<h3>Alignment summary</h3>';
    $html .= $self->display_alignment_table($species, $alignments);
  } else {
    ## Show error message
    $html .= '<p>Sorry, no alignments found.</p>';
  }
  return $html;
}

sub draw_karyotype {
  my ($self, $species, $alignments) = @_;
  my $hub         = $self->hub;
  my $config_name = 'Vkaryotype';
  my $config      = $hub->get_imageconfig($config_name);
  my $image       = $self->new_karyotype_image($config);
  my @colours     = $self->colours;

  ## Create highlights - arrows and outline box
  my %all_hits = (style => 'rharrow');
  my %top_hit  = (style => 'outbox');

  # Create per-hit glyphs
  my @glyphs;
  my $first = 1;
  
  foreach (@$alignments) {
    my ($hit, $hsp) = @$_;
    my $gh          = $hsp->genomic_hit;
    my $chr         = $gh->seq_region_name;
    my $chr_start   = $gh->seq_region_start;
    my $chr_end     = $gh->seq_region_end;
    my $caption     = 'Alignment vs ' . $hsp->hit->seq_id;
    my $score       = $hsp->score;
    my $pct_id      = $hsp->percent_identity;
    my $colour_id   = int(($pct_id-1)/20);
    my $colour      = $colours[$colour_id];

    $config->{'col'}   = $colour;
    $config->{'start'} = $chr_start;
    $config->{'end'}   = $chr_end;
    $config->{'score'} = $score;

    if ($first) {
      $first = 0;
      $top_hit{$chr} ||= [];
      push @{$top_hit{$chr}}, $config;
    }
    
    $all_hits{$chr} ||= [];
    push @{$all_hits{$chr}}, $config;
  }

  $image->image_name = 'blast-karyotype';
  $image->set_button('form', 'id' => 'vclick', 'URL' => "/$species/jump_to_location_view");
  $image->karyotype($hub, $self->object, [ \%all_hits, \%top_hit ], $config_name);

  return $image->render;
}

sub draw_key {
  my $self    = shift;
  my @colours = $self->colours;
  my $html = '
    <h4>Key to colours (percentage identity)</h4>
    <table>
      <tr>
  ';
  
  ## Print out colours in percentage intervals of 20
  for (my $i = 0; $i < scalar @colours; $i++) {
    $html .= sprintf(
      '<td style="width:10%%;background-color:%s">&nbsp;</td><td style="width:10%%">%d-%d</td>', 
      $colours[$i], $i * 20, ($i+1) * 20
    ); 
  }

  $html .= '
    </tr>
  </table>
  ';
  
  return $html;
}

sub draw_alignment {
  my ($self, $species, $alignments) = @_;
  my $image = $self->object->new_hsp_image($alignments);
  return $image->render_image_button;
}

sub display_alignment_table {
  my ($self, $species, $alignments) = @_;
  
  my $hub    = $self->hub;
  my $object = $self->object;
  
  ## Do options table -----------------------------------
  ## TODO: move to ViewConfig
  my $ticket = $hub->param('ticket');
  my $run_id = $hub->param('run_id');
  
  my $html = qq{
  <form action="/Blast/View" method="post">
    <input type="hidden" name="ticket" value="$ticket" />
    <input type="hidden" name="ticket" value="$run_id" />
  };
  
  ## Make big array of settings
  ## Standard dropdown is to be off by default
  my @standard_off = (
    { 'value' => 'off',         'text' => '-off-', 'default' => 1 },
    { 'value' => 'name',        'text' => 'Name',  'default' => 0 },
    { 'value' => 'start',       'text' => 'Start', 'default' => 0 },
    { 'value' => 'end',         'text' => 'End',   'default' => 0 },
    { 'value' => 'orientation', 'text' => 'Ori',   'default' => 0 },
  );
  
  ## Some settings however are on by default
  my @standard_on = (
    { 'value' => 'off',         'text' => '-off-', 'default' => 0 },
    { 'value' => 'name',        'text' => 'Name',  'default' => 1 },
    { 'value' => 'start',       'text' => 'Start', 'default' => 1 },
    { 'value' => 'end',         'text' => 'End',   'default' => 1 },
    { 'value' => 'orientation', 'text' => 'Ori',   'default' => 1 },
  );

  my @settings = ({
    'name'   => 'query',
    'label'  => 'Query',
    'values' => \@standard_on,
  }, {
    'name'   => 'subject',
    'label'  => 'Subject',
    'values' => \@standard_off,
  });

  my %coords   = reverse %{$object->fetch_coord_systems};
  my $toplevel = $coords{1};
  my @coord_systems = sort { $coords{$a} <=> $coords{$b} } values %coords;
  my $coord_settings; ## We need to be able to access these separately from other settings
  
  foreach my $C (@coord_systems) {
    my $values = $C eq $toplevel ? \@standard_on : \@standard_off;
    my $coord_select = {
      'name'   => $C,
      'label'  => ucfirst($C),
      'values' => $values,
    };
    
    push @$coord_settings, $coord_select;
  }
  
  push @settings, @$coord_settings;

  my $stat_values = [
    { 'value' => 'score',    'text' => 'Score',  'default' => 1 },
    { 'value' => 'evalue',   'text' => 'E-val',  'default' => 1 },
    { 'value' => 'pvalue',   'text' => 'P-val',  'default' => 0 },
    { 'value' => 'identity', 'text' => '% ID',   'default' => 1 },
    { 'value' => 'length',   'text' => 'Length', 'default' => 1 },
  ];
  
  my @stat_types = qw(score evalue pvalue identity length);
  push @settings, { 'name' => 'stats', 'label' => 'Stats', 'values' => $stat_values };

  my $sort_values = [
    { 'value' => 'query_asc',   'text' => '&lt;Query',   'default' => 0 },
    { 'value' => 'query_dsc',   'text' => '&gt;Query',   'default' => 0 },
    { 'value' => 'subject_asc', 'text' => '&lt;Subject', 'default' => 0 },
    { 'value' => 'subject_dsc', 'text' => '&gt;Subject', 'default' => 0 },
  ];
  
  foreach my $setting (@$coord_settings) {
    my $cs   = $setting->{'name'};
    my $text = $setting->{'label'};
    push @$sort_values, { 'value' => $cs.'_asc', 'text' => '&lt;'.$text, 'default' => 0 };
    push @$sort_values, { 'value' => $cs.'_dsc', 'text' => '&gt;'.$text, 'default' => 0 };
  }
  
  foreach my $value (@$stat_values) {
    my $key = $value->{'value'};
    my $set = $key eq 'score' ? 1 : 0; ## default sort is score_dsc
    push @$sort_values, { 'value' => $key.'_asc', 'text' => '&lt;'.ucfirst($key), 'default' => 0    };
    push @$sort_values, { 'value' => $key.'_dsc', 'text' => '&gt;'.ucfirst($key), 'default' => $set };
  }
  
  push @settings, { 'name' => 'sort_by', 'label' => 'Sort by', 'values' => $sort_values };

  ## Now do the selection widgets
  my $opt_table = $self->new_table;
  my $width     = int(100 / scalar(@settings));
  my ($selector, $type);
  
  foreach $type (@settings) {
    my $name = $type->{'name'};
    $opt_table->add_columns({ 'key' => $name, 'title' => $type->{'label'}, 'width' => $width.'%', 'align' => 'left' });
    my $widget = qq{<select name="view_$name" multiple="multiple" size="3">\n"};
    
    foreach my $V (@{$type->{'values'}}) {
      $widget .= qq{<option value="$V->{'value'}"};
      $widget .= $V->{'default'} == 1 ? ' selected="selected"' : '';
      $widget .= ">$V->{'text'}</option>";
    }
    
    $widget .= "</select>\n";
    $selector->{$name} = $widget;
  }
  
  $opt_table->add_row($selector);

  $html .= $opt_table->render; 
  $html .= qq{<p class="space-below">Select rows to include in table, and type of sort (Use the 'ctrl' key to select multiples) <input type="submit" name="submit" class="submit" value="Refresh display" /></p>};
  $html .= '<p style="margin-bottom:1em">&nbsp;</p>';

  ## Finally, do actual results table! --------------------------------------------------
  my @sorted = scalar @$alignments > 1 ? @{$object->sort_table_values($alignments, \@coord_systems)} : @$alignments;
  
  my @display_types; ## only show the requested columns
  my $column_count;
  
  foreach $type (@settings) {
    next if $type->{'name'} eq 'sort_by';
    
    my $off_by_default = 0;
    my $columns        = [];
    
    foreach my $V (@{$type->{'values'}}) {
      if ($V->{'value'} eq 'off' && $V->{'default'} == 1) {
        $off_by_default = 1;
      }
    }
    
    my $chosen = $hub->param("view_$type->{'name'}");
    
    if (ref $chosen eq 'ARRAY') { ## CASE 1: columns have been selected by user
      foreach my $V (@{$type->{'values'}}) {
        my $value   = $V->{'value'};
        my @matches = grep /^$value$/, @$chosen;
        
        if ($matches[0]) {
          push @$columns, $V;
        }
      }
      
      $column_count += scalar(@$columns);
    } elsif ($chosen eq 'off' || $off_by_default) { ## CASE 2: this type is turned off
      next;
    } else { ## CASE 3: this type is turned on by default
      foreach my $V (@{$type->{'values'}}) {
        next if $V->{'value'} eq 'off';
        
        if ($V->{'default'} == 1) {
          push @$columns, $V;
        }
      }
      
      $column_count += scalar @$columns;
    }
    
    push @display_types, { 'name' => $type->{'name'}, 'label' => $type->{'label'}, 'columns' => $columns };
  }

  my $result_table = $self->new_table; 
  ## Top level of headers
  $width = int(100 / $column_count);
  
  $result_table->add_spanning_headers({ 'title' => 'Links' });
  $result_table->add_columns({ 'key' => 'links', 'title' => '', 'width' => $width.'%', 'align' => 'left' });
  
  foreach $type (@display_types) {
    $result_table->add_spanning_headers({ 'title' => $type->{'label'}, 'colspan' => scalar @{$type->{'columns'}} });
    
    foreach my $col (@{$type->{'columns'}}) {
      $result_table->add_columns({ 'key' => $type->{'name'}.'_'.$col->{'value'}, 'title' => $col->{'text'}, 'width' => $width.'%', 'align' => 'left' });
    }
  }

  ## Finally, the results!
  foreach my $A (@$alignments) {
    my ($hit, $hsp) = @$A;
    
    next unless $hit && $hsp;
    
    my $align_info = $self->munge_alignment($hsp, \@coord_systems, \@stat_types);
    my $result_row;

    my @align_parameters = (
      'ticket=' . $hub->param('ticket'),
      'run_id=' . $hub->param('run_id'),
      'hit_id=' . $hit->token,
      'hsp_id=' . $hsp->token,
    );
    
    my $parameter_string = "species=$species;";
    $parameter_string   .= join ';', @align_parameters;

    my $location_parameters = sprintf('r=%s:%s-%s', $align_info->{'generic'}->{'name'},
        $align_info->{'generic'}->{'start'}, $align_info->{'generic'}->{'end'},
    );

    $result_row->{'links'} = sprintf('
        <a href="%s" style="text-decoration:none;" title="Alignment">[A]</a> 
        <a href="%s" style="text-decoration:none;" title="Query Sequence">[S]</a> 
        <a href="%s" style="text-decoration:none;" title="Genome Sequence">[G]</a> 
        <a href="%s" style="text-decoration:none;" title="Region in Detail">[R]</a>
      ',
      "/Blast/Alignment?display=align;$parameter_string", 
      "/Blast/Alignment?display=query;$parameter_string", 
      "/Blast/Alignment?display=genomic;$parameter_string",
      "/$species/Location/View?$location_parameters",
    );
    
    foreach $type (@display_types) {
      my $name = $type->{'name'};
      
      foreach my $col (@{$type->{'columns'}}) {
        my $value = $col->{'value'};
        
        if ($type->{'name'} eq 'chromosome' && $value eq 'name') {
          $result_row->{$name.'_'.$value} = sprintf(
            '<a href="/%s/Location/Chromosome?%s">Chr %s</a>',
            $species, $location_parameters, $align_info->{'generic'}->{'name'}, 
          );
        } else {
          $result_row->{$name.'_'.$value} = $align_info->{$name}->{$value} || '&nbsp;';
        }
      }
    }
    
    $result_table->add_row($result_row);
  }

  $html .= $result_table->render; 
}

sub munge_alignment {
  ### Helper method to get useable information for displaying in alignments table
  
  my ($self, $hsp, $coord_systems, $stat_types) = @_;
  my $gh = $hsp->genomic_hit;
  my $info;
  
  if ($gh) {
    my $context = 2000;
    $info->{'generic'}->{'name'}  = $gh->seq_region_name;
    $info->{'generic'}->{'start'} = $gh->start - $context;
    $info->{'generic'}->{'end'}   = $gh->end   + $context;
  }
  
  foreach my $C (@$coord_systems) {
    $gh = $hsp->genomic_hit($C);
    
    next unless $gh;
    
    $info->{$C}->{'name'}        = $gh->seq_region_name;
    $info->{$C}->{'start'}       = $gh->start;
    $info->{$C}->{'end'}         = $gh->end;
    $info->{$C}->{'orientation'} = $gh->strand < 0 ? '-' : '+';
  }
  
  $info->{'query'}->{'name'}        = $hsp->query->seq_id;
  $info->{'query'}->{'start'}       = $hsp->query->start;
  $info->{'query'}->{'end'}         = $hsp->query->end;
  $info->{'query'}->{'orientation'} = $hsp->query->strand < 0 ? '-' : '+';
  
  my $subject_name = $hsp->hit->seq_id;
  $subject_name    =~ s/^\w+://o;
  
  $info->{'subject'}->{'name'}        = $subject_name;
  $info->{'subject'}->{'start'}       = $hsp->hit->start;
  $info->{'subject'}->{'end'}         = $hsp->hit->end;
  $info->{'subject'}->{'orientation'} = $hsp->hit->strand < 0 ? '-' : '+';
  
  foreach my $S (@$stat_types) {
    my $method = $S;
    $method    = 'percent_identity' if $method eq 'identity';
    $info->{'stats'}->{$S} = $hsp->$method || 'N/A';
  }
  
  return $info;
}

1;
