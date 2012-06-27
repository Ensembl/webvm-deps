# $Id: Image.pm,v 1.104 2011-11-28 15:40:10 sb23 Exp $

package EnsEMBL::Web::Document::Image;

use strict;

use POSIX qw(ceil);

use Bio::EnsEMBL::VDrawableContainer;

use EnsEMBL::Web::TmpFile::Image;

sub new {
  my ($class, $species_defs, $image_configs) = @_;

  my $self = {
    species_defs       => $species_defs,
    image_configs      => $image_configs || [],
    drawable_container => undef,
    imagemap           => 'no',
    image_type         => 'image',
    image_name         => undef,
    introduction       => undef,
    tailnote           => undef,
    caption            => undef,
    button_title       => undef,
    button_name        => undef,
    button_id          => undef,
    format             => 'png',
  };

  bless $self, $class;
  return $self;
}

sub object             :lvalue { $_[0]->{'object'};             }
sub drawable_container :lvalue { $_[0]->{'drawable_container'}; }
sub imagemap           :lvalue { $_[0]->{'imagemap'};           }
sub button             :lvalue { $_[0]->{'button'};             }
sub button_id          :lvalue { $_[0]->{'button_id'};          }
sub button_name        :lvalue { $_[0]->{'button_name'};        }
sub button_title       :lvalue { $_[0]->{'button_title'};       }
sub image_type         :lvalue { $_[0]->{'image_type'};         }
sub image_name         :lvalue { $_[0]->{'image_name'};         }
sub introduction       :lvalue { $_[0]->{'introduction'};       }
sub tailnote           :lvalue { $_[0]->{'tailnote'};           }
sub caption            :lvalue { $_[0]->{'caption'};            }
sub format             :lvalue { $_[0]->{'format'};             }

sub image_width { $_[0]->drawable_container->{'config'}->get_parameter('image_width'); }

#----------------------------------------------------------------------------
# FUNCTIONS FOR CONFIGURING AND CREATING KARYOTYPE IMAGES
#----------------------------------------------------------------------------

sub karyotype {
  my ($self, $hub, $object, $highs, $config_name) = @_;
  my @highlights = ref($highs) eq 'ARRAY' ? @$highs : ($highs);

  $config_name ||= 'Vkaryotype';
  my $chr_name;

  my $image_config = $hub->get_imageconfig($config_name);
  
  # set some dimensions based on number and size of chromosomes
  if ($image_config->get_parameter('all_chromosomes') eq 'yes') {
    my $total_chrs = @{$hub->species_defs->ENSEMBL_CHROMOSOMES};
    my $rows       = $hub->param('rows') || ceil($total_chrs / 18);
    my $chr_length = $hub->param('chr_length') || 200;
       $chr_name   = 'ALL';

    if ($chr_length) {
      $image_config->set_parameters({
        image_height => $chr_length,
        image_width  => $chr_length + 25,
      });
    }
    
    $image_config->set_parameters({ 
      container_width => $hub->species_defs->MAX_CHR_LENGTH,
      rows            => $rows,
      slice_number    => '0|1',
    });
  } else {
    $chr_name = $object->seq_region_name if $object;
    
    my $seq_region_length = $object ? $object->seq_region_length : '';
    
    $image_config->set_parameters({
      container_width => $seq_region_length,
      slice_number    => '0|1'
    });
    
    $image_config->{'_rows'} = 1;
  }

  $image_config->{'_aggregate_colour'} = $hub->param('aggregate_colour') if $hub->param('aggregate_colour');

  # get some adaptors for chromosome data
  my ($sa, $ka, $da);
  my $species = $hub->param('species') || $hub->species;
  
  return unless $species;

  my $db = $hub->databases->get_DBAdaptor('core', $species);
  
  eval {
    $sa = $db->get_SliceAdaptor,
    $ka = $db->get_KaryotypeBandAdaptor,
    $da = $db->get_DensityFeatureAdaptor
  };
  
  return $@ if $@;

  # create the container object and add it to the image
  $self->drawable_container = new Bio::EnsEMBL::VDrawableContainer({
    sa  => $sa, 
    ka  => $ka, 
    da  => $da, 
    chr => $chr_name,
    format =>$hub->param('export')
  }, $image_config, \@highlights) if($hub->param('_format') ne 'Excel');

  return undef; # successful
}

sub add_pointers {
  my ($self, $hub, $extra) = @_;

  my $config_name = $extra->{'config_name'};
  my @data        = @{$extra->{'features'}};
  my $species     = $hub->species;
  my $color       = lc($extra->{'color'} || $hub->param('col')) || 'red';     # set sensible defaults
  my $style       = lc($extra->{'style'} || $hub->param('style')) || 'rharrow'; # set style before doing chromosome layout, as layout may need tweaking for some pointer styles
  my $high        = { style => $style };
  my ($p_value_sorted, $html_id, $max_colour);
  my $i = 1;
  
  # colour gradient 
  my @gradient = @{$extra->{'gradient'}||[]};
  if ($color eq 'gradient' && scalar @gradient) {    
    my @colour_scale = $hub->colourmap->build_linear_gradient(@gradient); # making an array of the colour scale

    foreach my $colour (@colour_scale) {
      $p_value_sorted->{$i} = $colour;
      $i = sprintf("%.1f", $i + 0.1);
      $max_colour = $colour;
    }
  }

  foreach my $row (@data) {
    my $chr = $row->{'chr'} || $row->{'region'};
    $html_id =  ($row->{'html_id'}) ? $row->{'html_id'} : '';    
    my $col = $p_value_sorted->{sprintf("%.1f",$row->{'p_value'})};

    my $point = {
      start   => $row->{'start'},
      end     => $row->{'end'},
      id      => $row->{'label'},
      col     => $p_value_sorted->{sprintf("%.1f",$row->{'p_value'})} || $max_colour || $color,
      href    => $row->{'href'},
      html_id => $html_id,
    };
    
    if (exists $high->{$chr}) {
      push @{$high->{$chr}}, $point;
    } else {
      $high->{$chr} = [ $point ];
    }
  }
  
  return $high;
}

sub set_button {
  my ($self, $type, %pars) = @_;
 
  $self->button           = $type;
  $self->{'button_id'}    = $pars{'id'}     if exists $pars{'id'};
  $self->{'button_name'}  = $pars{'id'}     if exists $pars{'id'};
  $self->{'button_name'}  = $pars{'name'}   if exists $pars{'name'};
  $self->{'URL'}          = $pars{'URL'}    if exists $pars{'URL'};
  $self->{'hidden'}       = $pars{'hidden'} if exists $pars{'hidden'};
  $self->{'button_title'} = $pars{'title'}  if exists $pars{'title'};
  $self->{'hidden_extra'} = $pars{'extra'}  if exists $pars{'extra'};
}

####################################################################################################
#
# Renderers
#
####################################################################################################

# Having a usemap causes drag selecting to become a real pain, so disabled
sub extra_html {
  my $self = shift;
  
  my $extra = qq{class="imagemap" };

#  if ($self->imagemap eq 'yes') {
#    my $map_name = $self->{'token'};
#    $extra .= qq{usemap="#$map_name" };
#  }
  
  return $extra;
}

sub extra_style {
  my $self = shift;
  return $self->{'border'} ? sprintf('border: %s %dpx %s;', $self->{'border_colour'} || '#000', $self->{'border'}, $self->{'border_style'} || 'solid') : '';
}

sub render_image_tag {
  my ($self, $image) = @_;
  
  my $url    = $image->URL;
  my $width  = $image->width;
  my $height = $image->height;
  my $html;

  if ($width > 5000) {
    $html = qq{
       <p style="text-align:left">
         The image produced was $width pixels wide,
         which may be too large for some web browsers to display.
         If you would like to see the image, please right-click (MAC: Ctrl-click)
         on the link below and choose the 'Save Image' option from the pop-up menu.</p>
       <p><a href="$url">Image download</a></p>
    };
  } else {
    $html = sprintf(
      '<img src="%s" alt="" style="width: %dpx; height: %dpx; %s display: block" %s />',
      $url,
      $width,
      $height,
      $self->extra_style,
      $self->extra_html
    );

    $self->{'width'}  = $width;
    $self->{'height'} = $height;
  }

  return $html;
} 

sub render_image_button {
  my ($self, $image) = @_;

  return sprintf(
    '<input style="width: %dpx; height: %dpx; %s display: block" type="image" name="%s" src="%s" alt="%s" title="%s" %s />',
    $image->width,
    $image->height,
    $self->extra_style,
    $self->{'button_name'},
    $image->URL,
    $self->{'button_title'},
    $self->{'button_title'}
  );
} 

sub render_image_map {
  my ($self, $image) = @_;

  my $imagemap = $self->drawable_container->render('imagemap');
  my $map_name = $image->token;
  
  my $map = qq{
    <map name="$map_name">
      $imagemap
    </map>
  };
  
  $map .= '<input type="hidden" class="panel_type" value="ImageMap" />';
  
  return $map;
}

sub hover_labels {
  my $self    = shift;
  my $img_url = $self->{'species_defs'}->img_url;
  my ($html, %done);
  
  foreach my $label (map values %{$_->{'hover_labels'} || {}}, @{$self->{'image_configs'}}) {
    next if $done{$label->{'class'}};
    
    my $desc = join '', map "<p>$_</p>", split /; /, $label->{'desc'};
    my $renderers;
    
    foreach (@{$label->{'renderers'}}) {
      my $text = $_->{'text'};
      
      if ($_->{'current'}) {
        $renderers .= qq{<li class="current"><img src="${img_url}render/$_->{'current'}.gif" alt="$text" title="$text" /><img src="${img_url}tick.png" class="tick" alt="Selected" title="Selected" /> $text</li>};
      } else {
        $renderers .= qq{<li><a href="$_->{'url'}" class="config" rel="$label->{'component'}"><img src="${img_url}render/$_->{'val'}.gif" alt="$text" title="$text" /> $text</a></li>};
      }
    }
    
    $html .= sprintf(qq{
      <div class="hover_label floating_popup %s">
        <p class="header">%s</p>
        %s
        %s
        <img class="url" src="${img_url}link.png" alt="Link" title="URL to turn this track on" />
        <a href="$label->{'fav'}[1]" class="config favourite%s" rel="$label->{'component'}" title="Favourite track"></a>
        <a href="$label->{'off'}" class="config" rel="$label->{'component'}"><img src="${img_url}cross_red_13.png" alt="Turn track off" title="Turn track off" /></a>
        <div class="desc">%s</div>
        <div class="config">%s</div>
        <div class="url"><p>Copy <a href="$label->{'conf_url'}">this link</a> to force this track to be turned on</p></div>
        <div class="spinner"></div>
      </div>},
      $label->{'class'},
      $label->{'header'},
      $label->{'desc'}   ? qq{<img class="desc" src="${img_url}info_blue_13.png" alt="Info" title="Info" />} : '',
      $renderers         ? qq{<img class="config" src="${img_url}config_13.png" alt="Change track style" title="Change track style" />} : '',
      $label->{'fav'}[0] ? ' selected' : '',
      $desc,
      $renderers         ? "<p>Change track style:</p><ul>$renderers</ul>" : ''
    );
  }
  
  return $html;
}

sub track_boundaries {
  my $self            = shift;
  my $container       = $self->drawable_container;
  my $config          = $container->{'config'};
  my $spacing         = $config->get_parameter('spacing');
  my $top             = $config->get_parameter('margin') * 2 - $spacing;
  my @sortable_tracks = grep { $_->get('display') ne 'off' } $config->get_sortable_tracks;
  my %track_ids       = map  { $_->id => 1 } @sortable_tracks;
  my %strand_map      = ( f => 1, r => -1 );
  my @boundaries;
  
  foreach my $glyphset (@{$container->{'glyphsets'}}) {
    next unless scalar @{$glyphset->{'glyphs'}};
    
    my $height = $glyphset->height + $spacing;
    my $type   = $glyphset->_type;
    my $node;  
    
    if ($track_ids{$type}) {
      while (scalar @sortable_tracks) {
        my $track  = $sortable_tracks[0];
        my $strand = $track->get('drawing_strand');
        
        last if $type eq $track->id && (($strand && $strand_map{$strand} == $glyphset->strand) || !$strand);
        shift @sortable_tracks;
      }
      
      $node = shift @sortable_tracks;
    }
    
    push @boundaries, [ $top, $height, $type, $node->get('drawing_strand'), $node->get('order') ] if $node && $node->get('sortable') && !scalar keys %{$glyphset->{'tags'}};
    
    $top += $height;
  }
  
  return \@boundaries;
}

sub moveable_tracks {
  my ($self, $image) = @_;
  my $config = $self->drawable_container->{'config'};
  
  return unless $config->hub->check_ajax && $config->get_parameter('sortable_tracks') eq 'drag';
  
  my $species = $config->species;
  my $url     = $image->URL;
  my ($top, $html);
  
  foreach (@{$self->track_boundaries}) {
    my ($t, $h, $type, $strand, $order) = @$_;
    
    $html .= sprintf(
      '<li class="%s%s" style="height:%spx;background:url(%s) 0 %spx%s">
        <p class="handle" style="height:%spx"%s></p>
        <i class="%s"></i>
      </li>',
      $type, $strand ? " $strand" : '',
      $h, $url, 3 - $t,
      $h == 0 ? ';display:none' : '',
      $h - 1,
      $strand ? sprintf(' title="%s strand"', $strand eq 'f' ? 'Forward' : 'Reverse') : '',
      $order
    );
    
    $top ||= $t - 3 if $h;
  }
  
  return qq{<div class="boundaries_wrapper" style="top:${top}px"><div class="up"></div><ul class="$species boundaries">$html</ul><div class="down"></div></div>} if $html;
}

sub render {
  my ($self, $format) = @_;

  return unless $self->drawable_container;

  if ($format) {
    print $self->drawable_container->render($format);
    return;
  }

  my $html    = $self->introduction;
  my $image   = new EnsEMBL::Web::TmpFile::Image;
  my $content = $self->drawable_container->render('png');

  $image->content($content);
  $image->save;
  
  if ($self->button eq 'form') {
    my $image_html = $self->render_image_button($image);
    my $inputs;
    
    $self->{'hidden'}{'total_height'} = $image->height;
    
    $image_html .= sprintf '<div style="text-align: center; font-weight: bold">%s</div>', $self->caption if $self->caption;
    
    foreach (keys %{$self->{'hidden'}}) {
      $inputs .= sprintf(
        '<input type="hidden" name="%s" id="%s%s" value="%s" />', 
        $_, 
        $_, 
        $self->{'hidden_extra'} || $self->{'counter'}, 
        $self->{'hidden'}{$_}
      );
    }
    
    $html .= sprintf(
      '<div class="autocenter_wrapper"><form style="width: %spx" class="autocenter" action="%s" method="get"><div>%s</div><div class="autocenter">%s</div></form></div>',
      $image->width,
      $self->{'URL'},
      $inputs,
      $image_html
    );
    
    $self->{'counter'}++;
  } elsif ($self->button eq 'yes') {
    $html .= $self->render_image_button($image);
    $html .= sprintf '<div style="text-align: center; font-weight: bold">%s</div>', $self->caption if $self->caption;
  } elsif ($self->button eq 'drag') {
    my $img = $self->render_image_tag($image);

    # continue with tag html
    # This has to have a vertical padding of 0px as it is used in a number of places
    # butted up to another container - if you need a vertical padding of 10px add it
    # outside this module
    
    my $export;
    
    if ($self->{'export'}) {
      my @formats = (
        { f => 'pdf',     label => 'PDF' },
        { f => 'svg',     label => 'SVG' },
        { f => 'eps',     label => 'PostScript' },
      );
      ## PNG renderer will crash if image too tall!
      unless ($image->height > 32000) {
        push @formats, { f => 'png-10',  label => 'PNG (x10)' };
      }
      push @formats, (
        { f => 'png-5',   label => 'PNG (x5)' },
        { f => 'png-2',   label => 'PNG (x2)' },
        { f => 'png',     label => 'PNG' },
        { f => 'png-0.5', label => 'PNG (x0.5)' },
        { f => 'gff',     label => 'text (GFF)', text => 1 }
      );
      
      my $url = $ENV{'REQUEST_URI'};
      $url =~ s/;$//;
      $url .= ($url =~ /\?/ ? ';' : '?') . 'export=';
      
      for (@formats) {
        my $href = $url . $_->{'f'};
        
        if ($_->{'text'}) {
          next if $self->{'export'} =~ /no_text/;
          
          $export .= qq{<div><a href="$href" style="width:9em" rel="external">Export as $_->{'label'}</a></div>};
        } else {
          $export .= qq{<div><a href="$href;download=1" style="width:9em" rel="external">Export as $_->{'label'}</a><a class="view" href="$href" rel="external">[view]</a></div>};
        }
      }
      
      $export = qq{
        <div class="$self->{'export'}" style="width:$image->{'width'}px;"><a class="print_hide" href="${url}pdf">Export Image</a></div>
        <div class="iexport_menu">$export</div>
      };
    }
    
    my $wrapper = sprintf('
      <div class="drag_select" style="margin:0px auto; border:solid 1px black; position:relative; width:%dpx">
        %s
        %s
        %s
        %s
      </div>',
      $image->width,
      $img,
      $self->imagemap eq 'yes' ? $self->render_image_map($image) : '',
      $self->moveable_tracks($image),
      $self->hover_labels
    );
    
    $html .= sprintf('
      <div style="text-align:center">
        <div style="text-align:center; margin:auto; border:0px; padding:0px">
          %s
          %s
          %s
        </div>
      </div>',
      $wrapper,
      $export,
      $self->caption ? sprintf '<div style="text-align:center; font-weight:bold">%s</div>', $self->caption : ''
    );
  } else {
    $html .= join('',
      $self->render_image_tag($image),
      $self->imagemap eq 'yes' ? $self->render_image_map($image) : '',
      $self->moveable_tracks($image),
      $self->hover_labels,
      $self->caption ? sprintf('<div style="text-align:center; font-weight:bold">%s</div>', $self->caption) : ''
    );
  }

  $html .= $self->tailnote;
  
  if ($self->{'image_configs'}[0]) {
    $html .= qq{<input type="hidden" class="image_config" value="$self->{'image_configs'}[0]{'type'}" />};
    $html .= '<span class="hidden drop_upload"></span>' if $self->{'image_configs'}[0]->get_node('user_data');
  }
  
  $self->{'width'} = $image->width;
  $self->{'species_defs'}->timer_push('Image->render ending', undef, 'draw');
  
  return $html;
}

1;
