# $Id: Table.pm,v 1.23 2012-12-12 13:23:31 ds23 Exp $

package EnsEMBL::Web::Document::Table;

use strict;

use JSON qw(from_json to_json);

use base qw(EnsEMBL::Web::Root);

sub new {
  my ($class, $cols, $rows, $options, $spanning) = @_;
  
  $cols     ||= [];
  $rows     ||= [];
  $options  ||= {};
  $spanning ||= [];
  
  my $self = {
    columns    => $cols,
    rows       => $rows,
    options    => $options,
    spanning   => $spanning,
    format     => 'HTML',
  };
  
  bless $self, $class;
  $self->preprocess_widths();
  $self->preprocess_hyphens();
  return $self;
}

sub session    :lvalue { $_[0]{'session'};    }
sub code       :lvalue { $_[0]{'code'}        }
sub format     :lvalue { $_[0]{'format'};     }
sub export_url :lvalue { $_[0]{'export_url'}; }
sub filename   :lvalue { $_[0]{'filename'};   }

sub has_rows { return ! !@{$_[0]{'rows'}}; }

sub preprocess_widths {
  my ($self) = @_;
  
  my $perc_remaining = 100;
  my $units_used = 0;
  my @unitcols;
  foreach my $column (@{$self->{'columns'}}) {
          local $_ = $column->{'width'};
          my $units = -1;
          if(/(\d+)%/) {
                  $perc_remaining -= $1;
          } elsif(/(\d+)px/) {
                  return;
          } elsif(/(\d+)u/) {
                  $units_used += $1;
                  push @unitcols,{ units => $1, column => $column, percent => 0 };
          }
  }
  return unless $units_used;
  # careful alg. to avoid 99%, 101% tables due to rounding.
  my $perc_per_unit = $perc_remaining / $units_used;
  my $total = -0.5; # correct for rounding bias
  foreach (@unitcols) {
          $_->{'total'} = $_->{'units'}*$perc_per_unit + $total;
          $total += $_->{'units'}*$perc_per_unit;
  }
  my $col = 0;
  for(my $i=0;$i<$perc_remaining;$i++) {
          $col++ if($i>$unitcols[$col]->{'total'} && $col < @unitcols);
          $unitcols[$col]->{'percent'}++;
  }       
  $_->{'column'}->{'width'} = $_->{'percent'}."%" for (@unitcols);
}

# \f -- optional hyphenation point
# \v -- optional break point (no hyphen)
sub hyphenate {
  my ($self,$data,$key) = @_;

  return unless exists $data->{$key};
  my $any = ($data->{$key} =~ s/\f/&shy;/g or 
             $data->{$key} =~ s/\v/&#8203;/g   );
  return $any;
}

sub preprocess_hyphens {
  my ($self) = @_;

  foreach my $c (@{$self->{'columns'}}) {
    my $h = 0;
    $h ||= $self->hyphenate($c,'label') if $c->{'label'};
    $c->{'class'} .= ' hyphenated' if $h;
  }
}

sub export_options {
  my $self = shift;

  my @options;
  my $index = -1;
  foreach my $column (@{$self->{'columns'}}) {
    $index++;
    next unless defined $column->{'export_options'};
    $options[$index] = $column->{'export_options'};
  }
  return to_json(\@options);
}

sub render {
  my $self = shift;
  
  return unless @{$self->{'columns'}};
  
  my $func = 'render_' . $self->format;
  
  return $self->$func if $self->can($func);
  
  my $options     = $self->{'options'}        || {};
  my $style       = [ split(';', $options->{'style'} || ''), $options->{'margin'} ? "margin: $options->{'margin'}" : ()];
  my $width       = $options->{'width'}       || '100%';
  my $padding     = $options->{'cellpadding'} || 0;
  my $spacing     = $options->{'cellspacing'} || 0;
  my $align       = $options->{'align'}       || 'autocenter';
  my $table_id    = $options->{'id'} ? qq( id="$options->{'id'}" ) : '';
  my $data_table  = $options->{'data_table'};
  my $toggleable  = $options->{'toggleable'};
  my %table_class = map { $_ => 1 } split ' ', $options->{'class'};
  my $config;
  
  if ($table_class{'fixed_width'}) {
    $width = 'auto';
    $align = '';
  }
  
  $table_class{$align}         = 1 if $align;
  $table_class{'toggle_table'} = 1 if $toggleable;
  $table_class{'toggleable'}   = 1 if $toggleable && !$data_table;
  $table_class{'ss'}           = 1;
  
  if ($data_table) {
    $table_class{'data_table'} = 1;
    $table_class{$data_table}  = 1 if $data_table =~ /[a-z]/i;
    $table_class{'exportable'} = 1 unless $options->{'exportable'} eq '0';
    $config = $self->data_table_config;
  }
  
  my $class   = join ' ', keys %table_class;
  my $wrapper = join ' ', grep $_, $width ne '100%' && $table_class{'autocenter'} ? 'autocenter_wrapper' : '', $toggleable && $options->{'id'} ? $options->{'id'} : '';
  my ($head, $body) = $self->process;
  my ($thead, $tbody);
  
  if ($options->{'header'} ne 'no') {
    if (scalar @{$self->{'spanning'}}) {
      $thead .= '<tr class="ss_header">';
      
      foreach my $header (@{$self->{'spanning'}}) {
        my $span = $header->{'colspan'} || 1;
        $thead .= qq(<th colspan="$span"><em>$header->{'title'}</em></th>);
      }
      
      $thead .= '</tr>';
    }
    
    $thead .= sprintf '<tr%s>%s</tr>', $head->[1], join('', @{$head->[0]});
  }

  if ($options->{'header_repeat'} && !$data_table) { ## can't use both these options together
    my $repeat = $options->{'header_repeat'};
    my $i = 1;
    foreach (@$body) {
      $tbody .= sprintf '<tr%s>%s</tr>', $_->[1], join('', @{$_->[0]});
      $tbody .= $thead unless ($i % $repeat);
      $i++;
    }
  }
  else { 
    $tbody = join '', map { sprintf '<tr%s>%s</tr>', $_->[1], join('', @{$_->[0]}) } @$body;
  }
   
  $thead  = "<thead>$thead</thead>" if $thead;
  $tbody  = "<tbody>$tbody</tbody>" if $tbody;
  
  $style  = join ';', @$style, "width: $width";

  my $table = qq(
    <table$table_id class="$class" style="$style" cellpadding="$padding" cellspacing="$spacing">
      $thead
      $tbody
    </table>
    $config
  );
  
  if ($data_table && $options->{'exportable'} ne '0') {
    my $id       = $options->{'id'};
       $id       =~ s/[\W_]table//g;
    my $filename = join '-', grep $_, $id, $self->filename;
    
    my $options =  sprintf(qq{<input type="hidden" name='expopts' value='%s' />},$self->export_options);
    $table .= qq{
      <form class="data_table_export" action="/Ajax/table_export" method="post">
        <input type="hidden" name="filename" value="$filename" />
        <input type="hidden" class="data" name="data" value="" />
        $options
      </form>
    };
  }
    
  $table .= sprintf qq{<div class="other_tool"><p><a class="export" href="%s;_format=Excel" title="Download all tables as CSV">Download view as CSV</a></p></div>}, $self->export_url if $self->export_url;
  
  # A wrapper div is needed for data tables so that export and config forms can be found by checking the table's siblings
  if ($data_table) {
    $wrapper = qq{ class="$wrapper"} if $wrapper; 
    $table   = qq{<div$wrapper>$table</div>};
  }
  
  return $table;
}

sub render_Text {
  my $self = shift;
  
  return unless @{$self->{'columns'} || []};
  
  my ($head, $body) = $self->process;
  my $output;
  
  foreach my $row ([ @$head ], @$body) {
    $output .= sprintf qq{%s\n}, join "\t", map $self->strip_HTML($_), @{$row->[0]};
  }
  
  return $output;
}

sub _strip_outer_HTML {
  my $self = shift;
  local $_ = shift;
  
  s/^\s*<.*?>//;
  s/<.*?>\s*$//;
  return $_;
}

sub render_JSON {
  my $self = shift;
  
  return unless @{$self->{'columns'} || []};
  
  my ($head, $body) = $self->process;
  my @json;
  
  foreach my $row ([ @$head ], @$body) {
    push @json, [ map $self->_strip_outer_HTML($_), @{$row->[0]} ];
  }
  
  return to_json(\@json);
}

sub render_Excel {
  my $self = shift;
  
  return unless @{$self->{'columns'} || []};
  
  my $options = $self->{'options'} || {};
  my $align   = $options->{'align'} ? $options->{'align'} : 'autocenter';
  my $width   = $options->{'width'} ? $options->{'width'} : '100%';
  my ($head, $body) = $self->process;
  my $output;
  
  foreach my $row ([ @$head ], @$body) {
    $output .= sprintf qq{"%s"\n}, join '","', map $self->csv_escape($_), @{$row->[0]};
  }
  
  return $output;
}

sub csv_escape {
  my $self  = shift;
  my $value = $self->strip_HTML(shift);
  $value    =~ s/"/""/g;
  return $value;
}

# Returns a hidden input used to configure the sorting options for a javascript data table
sub data_table_config {
  my $self      = shift;
  my $code      = $self->code;
  my $col_count = scalar @{$self->{'columns'}};
  
  return unless $code && scalar @{$self->{'rows'}} && $col_count;
  my $i            = 0;
  my %columns      = map { $_->{'key'} => $i++ } @{$self->{'columns'}};
  my $session_data = $self->session ? $self->session->get_data(type => 'data_table', code => $code) : {};
  my $sorting      = $session_data->{'sorting'} ?        from_json($session_data->{'sorting'})        : $self->{'options'}->{'sorting'} || [];
  my $hidden       = $session_data->{'hidden_columns'} ? from_json($session_data->{'hidden_columns'}) : [];
  my $config       = qq{<input type="hidden" name="code" value="$code" />};
  my $sort         = [];
  
  foreach (@$sorting) {
    my ($col, $dir) = split / /;
    $col = $columns{$col} unless $col =~ /^\d+$/ && $col < $col_count;
    push @$sort, [ $col, $dir ] if defined $col;
  }
  
  if (scalar @$sort) {
    (my $aaSorting = $self->jsonify($sort)) =~ s/"/'/g;
    $config .= qq{<input type="hidden" name="aaSorting" value="$aaSorting" />};
  }
  
  $config .= sprintf '<input type="hidden" name="hiddenColumns" value="%s" />', $self->jsonify($hidden) if scalar @$hidden;
  
  foreach (keys %{$self->{'options'}{'data_table_config'}}) {
    my $option = $self->{'options'}{'data_table_config'}{$_};
    my $val;
    
    if (ref $option) {
      ($val = $self->jsonify($option)) =~ s/"/'/g;
    } else {
      $val = $option;
    }
    
    $config .= qq{<input type="hidden" name="$_" value="$val" />};
  }
  
  $config .= sprintf(qq{<input type="hidden" name='expopts' value='%s' />},$self->export_options);
 
  return qq{<form class="data_table_config" action="#">$config</form>};
}

sub process {
  my $self        = shift;
  my $columns     = $self->{'columns'};
  my @row_colours = $self->{'options'}{'data_table'} ? () : exists $self->{'options'}{'rows'} ? @{$self->{'options'}{'rows'}} : ('bg1', 'bg2');
  my (@head, @body);
  
  # Allow unit style widths
  
  
  foreach my $col (@$columns) {
    my $label = exists $col->{'label'} ? $col->{'label'} 
                : exists $col->{'title'} ? $col->{'title'} : $col->{'key'};
    my %style = $col->{'style'} ? ref $col->{'style'} eq 'HASH' ? %{$col->{'style'}} : map { s/(^\s+|\s+$)//g; split ':' } split ';', $col->{'style'} : ();
    
    $style{'text-align'} ||= $col->{'align'} if $col->{'align'};
    $style{'width'}      ||= $col->{'width'} if $col->{'width'};
    
    $col->{'style'}  = join ';', map { join ':', $_, $style{$_} } keys %style;
    $col->{'class'} .= ($col->{'class'} ? ' ' : '') . "sort_$col->{'sort'}" if $col->{'sort'};
    if ($col->{'help'}) {
      delete $col->{'title'};
      $label = qq(<span class="ht _ht" title="$col->{'help'}">$label</span>);
    }
    
    push @{$head[0]}, sprintf '<th%s>%s</th>', join('', map { $col->{$_} ? qq( $_="$col->{$_}") : () } qw(id class title style colspan rowspan)), $label;
  }
  
  $head[1] = ' class="ss_header"';
  
  foreach my $row (@{$self->{'rows'}}) {
    my ($options, @cells) = ref $row eq 'HASH' ? ($row->{'options'}, map $row->{$_->{'key'}}, @$columns) : ({}, @$row);
    my $i = 0;
    
    if (scalar @row_colours) {
      $options->{'class'} .= ($options->{'class'} ? ' ' : '') . $row_colours[0];
      push @row_colours, shift @row_colours
    }
    
    foreach my $cell (@cells) {
      $cell = { value => $cell } unless ref $cell eq 'HASH';
      
      my %style = $cell->{'style'} ? ref $cell->{'style'} eq 'HASH' ? %{$cell->{'style'}} : map { s/(^\s+|\s+$)//g; split ':' } split ';', $cell->{'style'} : ();
      
      $style{'text-align'} ||= $columns->[$i]{'align'} if $columns->[$i]{'align'};
      $style{'width'}      ||= $columns->[$i]{'width'} if $columns->[$i]{'width'};
      
      $cell->{'style'} = join ';', map { join ':', $_, $style{$_} } keys %style;
      
      $cell = sprintf '<td%s>%s</td>', join('', map { $cell->{$_} ? qq( $_="$cell->{$_}") : () } qw(id class title style colspan rowspan)), $cell->{'value'};
      
      $i++;
    }
    
    push @body, [ \@cells, join('', map { $options->{$_} ? qq( $_="$options->{$_}") : () } qw(id class style valign)) ];
  }
  
  return (\@head, \@body);
}

sub add_option {
  my $self = shift;
  my $key  = shift;
  
  if ($key eq 'class') {
    $self->{'options'}->{'class'} .= ($self->{'options'}->{'class'} ? ' ' : '') . $_[0];
  } elsif (ref $self->{'options'}->{$key} eq 'HASH') {
    $self->{'options'}->{$key} = { %{$self->{'options'}->{$key}}, %{$_[0]} };
  } elsif (ref $self->{'options'}->{$key} eq 'ARRAY') {
    push @{$self->{'options'}->{$key}}, @_;
  } elsif (scalar @_ == 1) {
    $self->{'options'}->{$key} = ref $_[0] eq 'ARRAY' ? [ $_[0] ] : $_[0];
  } else {
    $self->{'options'}->{$key} = \@_;
  }
}

sub add_columns {
  my $self = shift;
  push @{$self->{'columns'}}, @_;
}

sub add_spanning_headers {
  my $self = shift;
  push @{$self->{'spanning'}}, @_;
}

sub add_row {
  my ($self, $data) = @_;
  push @{$self->{'rows'}}, $data;
}

sub add_rows {
  my $self = shift;
  push @{$self->{'rows'}}, @_;
}
   
1;
