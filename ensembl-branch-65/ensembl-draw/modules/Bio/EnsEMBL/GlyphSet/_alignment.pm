package Bio::EnsEMBL::GlyphSet::_alignment;

use strict;

use base qw(Bio::EnsEMBL::GlyphSet_wiggle_and_block );
use Data::Dumper;

#==============================================================================
# The following functions can be over-riden if the class does require
# something diffirent - main one to be over-riden is probably the
# features call - as it will need to take different parameters...
#==============================================================================
sub _das_link {
## Returns the 'group' that a given feature belongs to. Features in the same
## group are linked together via an open rectangle. Can be subclassed.
  my $self = shift;
  return de_camel( $self->my_config('object_type') || 'dna_align_feature' );
}

sub feature_group {
  my( $self, $f ) = @_;
  #this regexp will remove the differences in names between the ends of BACs/FOSmids.
  (my $name = $f->hseqname) =~ s/(\..*|T7|SP6)$//;;
#  (my $name = $f->hseqname) =~ s/(\.?[xyz][abc]|T7|SP6)$//;;
  return $name;
#  return $f->hseqname;    ## For core features this is what the sequence name is...
}

sub feature_label {
  my( $self, $f, $db_name ) = @_;
  return $f->hseqname;
}

sub feature_title {
  my( $self, $f,$db_name ) = @_;
  $db_name ||= 'External Feature';
  return "$db_name ".$f->hseqname;
}

sub features {
  my ($self) = @_;
  my $method      = 'get_all_'.( $self->my_config('object_type') || 'DnaAlignFeature' ).'s';
  my $db          = $self->my_config('db');
  my @logic_names = @{ $self->my_config( 'logic_names' )||[] };
  $self->timer_push( 'Initializing don', undef, 'fetch' );
  my @results = map { $self->{'container'}->$method($_,undef,$db)||() } @logic_names;
  #force all features to be on one strand if the config requests it
  if (my $strand_shown = $self->my_config('show_strands')) {
    foreach my $r (@results) {
      foreach my $f (@$r) {
	$f->strand($strand_shown);
      }
    }
  }
  $self->timer_push( 'Retrieved features', undef, 'fetch' );
  my %results = ( $self->my_config('name') => [@results] );
  return %results;
}

sub href {
### Links to /Location/Genome
  my( $self, $f ) = @_;
  my $r = $f->seq_region_name.':'.$f->seq_region_start.'-'.$f->seq_region_end;
  my $action = $self->my_config('zmenu') ?  $self->my_config('zmenu') :  'Genome';
  my $ln = $f->can('analysis') ? $f->analysis->logic_name : '';
  my $id = $f->display_id;
  if ( $ln eq 'alt_seq_mapping'){
    $id = $f->dbID;
  }

  return $self->_url({
    'action'  => $action,
    'ftype'   => $self->my_config('object_type') || 'DnaAlignFeature',
    'r'       => $r,
    'id'      => $id,
    'db'      => $self->my_config('db'),
    'species' => $self->species,
    'ln'      => $ln,
  });
}

#==============================================================================
# Next we have the _init function which chooses how to render the
# features...
#==============================================================================

sub render_unlimited {
  my $self = shift;
  $self->render_normal( 1, 1000 );
}

sub render_stack {
  my $self = shift;
  $self->render_normal( 1, 40 );
}

sub render_simple {
  my $self = shift;
  $self->render_normal();
}

sub render_half_height {
  my $self = shift;
  $self->render_normal( $self->my_config('height')/2 || 4);
}

sub colour_key {
  my( $self, $feature_key ) = @_;
  return $self->my_config( 'colour_key' ) ? $self->my_config( 'colour_key' ) : $self->my_config( 'sub_type' );
}

sub render_labels {
  my $self = shift;
  $self->{'show_labels'} = 1;
  $self->render_normal();
}

#variable height renderer
sub render_histogram {
  my $self = shift;
  $self->{'max_score'} = $self->my_config('hist_max_height') || 50; # defines scaling factor, plus any feature with a score >= this shown at max height (set to 50 for rna-seq but can be configured via web-data)
  $self->{'height'} = 30; # overall track height
  my $strand = $self->strand;
  my %features = $self->features;
  foreach my $feature_key (keys %features) {
    my $colour_key     = $self->colour_key( $feature_key );
    my $feature_colour = $self->my_colour( $colour_key, undef  );
    my $non_can_feature_colour = $self->my_colour( $colour_key.'_non_can', undef) || '';
    my $join_colour    = $self->my_colour( $colour_key, 'join' );
    my ($sorted_feats, $sorted_can_feats, $sorted_non_can_feats, $hrefs) = ([],[],[],{});
    my $feats = $features{$feature_key};
    foreach my $f (
	    map { $_->[1] }
      sort{ $a->[0] <=> $b->[0] }
	    map { [$_->start,$_ ] }
	      @{$feats->[0]}
	  ){

      next if ($f->strand ne $strand);

      #artificially set score to the max allowed score if it's greater than that
      if ($f->score > $self->{'max_score'}) {
        $f->score($self->{'max_score'});
      }

      #sort into canonical and non-canonical
      if ($f->display_id =~ /non canonical$/) {
        push @$sorted_non_can_feats, $f;
      }
      else {
        push @$sorted_can_feats, $f;
      }
      $hrefs->{$f->display_id} = $self->href($f);
    }
    #draw canonical first and then non-canonical features
    push @{$sorted_feats}, @$_ for $sorted_can_feats, $sorted_non_can_feats;

    $self->draw_wiggle_plot(
      $sorted_feats,                      ## Features array
      { 'min_score'    => 0,
	'max_score'    => $self->{'max_score'},
	'score_colour' => $feature_colour,
	'no_axis'      => 1,
	'axis_label'   => 'off',
	'hrefs'        => $hrefs,
	'non_can_score_colour'  => $non_can_feature_colour,
      }
    );
  }
}

sub render_normal {
  my $self = shift;
  
  return $self->render_text if $self->{'text_export'};
  
  my $tfh    = $self->{'config'}->texthelper()->height($self->{'config'}->species_defs->ENSEMBL_STYLE->{'GRAPHIC_FONT'});
  my $h      = @_ ? shift : ($self->my_config('height') || 8);
  my $dep    = @_ ? shift : ($self->my_config('dep'   ) || 6);
  my $gap    = $h<2 ? 1 : 2;   
## Information about the container...
  my $strand = $self->strand;
  my $strand_flag    = $self->my_config('strand');

  my $length = $self->{'container'}->length();
## And now about the drawing configuration
  my $pix_per_bp     = $self->scalex;
  my $DRAW_CIGAR     = ( $self->my_config('force_cigar') eq 'yes' )|| ($pix_per_bp > 0.2) ;
  
## Highlights...
  my %highlights = map { $_,1 } $self->highlights;
  my $hi_colour = 'highlight1';

  if( $self->{'extras'} && $self->{'extras'}{'height'} ) {
    $h = $self->{'extras'}{'height'};
  }

## Get array of features and push them into the id hash...
  my %features = $self->features;

  #get details of external_db - currently only retrieved from core since they should be all the same
  my $db = 'DATABASE_CORE';
#  my $db = 'DATABASE_'.uc($self->my_config('db'));
  my $extdbs = $self->species_defs->databases->{$db}{'tables'}{'external_db'}{'entries'};

  my $y_offset = 0;

  my $features_drawn = 0;
  my $features_bumped = 0;
  my $label_h = 0;
  my( $fontname, $fontsize ) ;
  if( $self->{'show_labels'} ) {
    ( $fontname, $fontsize ) = $self->get_font_details( 'outertext' );
    my( $txt, $bit, $w,$th ) = $self->get_text_width( 0, 'X', '', 'ptsize' => $fontsize, 'font' => $fontname );
    $label_h = $th;
  }

  ## Sort (user tracks) by priority 
  my @sorted = $self->sort_features_by_priority(%features);
  unless (@sorted) {
    @sorted = $strand < 0 ? sort keys %features : reverse sort keys %features;
  }

  foreach my $feature_key (@sorted) {
    ## Fix for userdata with per-track config
    my ($config, @features);
    $self->{'track_key'} = $feature_key;
    next unless $features{$feature_key};
    my @T = @{$features{$feature_key}};
    if (ref($T[0]) eq 'ARRAY') {
      @features =  @{$T[0]};
      $config   = $T[1];
      $dep      ||= $T[1]->{'dep'};
    }
    else {
      @features = @T;
    }

    $self->_init_bump( undef, $dep );
    my %id = ();
    foreach my $f (
      map { $_->[2] }
      sort{ $a->[0] <=> $b->[0] }
      map { [$_->start,$_->end, $_ ] }
      @features
    ){
      my $hstrand  = $f->can('hstrand')  ? $f->hstrand : 1;
      my $fgroup_name = $self->feature_group( $f );
      my $s =$f->start;
      my $e =$f->end;
      my $db_name = $f->can('external_db_id') ? $extdbs->{$f->external_db_id}{'db_name'} : 'OLIGO';
      next if $strand_flag eq 'b' && $strand != ( ($hstrand||1)*$f->strand || -1 ) || $e < 1 || $s > $length ;
      push @{$id{$fgroup_name}}, [$s,$e,$f,int($s*$pix_per_bp),int($e*$pix_per_bp),$db_name];
    }

    ## Now go through each feature in turn, drawing them
    my ($cgGrades, $score_per_grade, @colour_gradient);
    my @greyscale      = (qw/cccccc a8a8a8 999999 787878 666666 484848 333333 181818 000000/);
    my $y_pos;
    my $colour_key     = $self->colour_key( $feature_key );
    my $feature_colour = $self->my_colour( $colour_key, undef  );
    my $label_colour   = $feature_colour;
    my $join_colour    = $self->my_colour( $colour_key, 'join' );
    my $max_score      = $config->{'max_score'} || 1000;
    my $min_score      = $config->{'min_score'} || 0;
    if ($config && $config->{'useScore'} == 2) {
      $cgGrades = $config->{'cgGrades'} || 20;
      $score_per_grade =  ($max_score - $min_score)/ $cgGrades ;
      my @cgColours = map { $config->{$_} }
                      grep { (($_ =~ /^cgColour/) && $config->{$_}) }
                      sort keys %$config;
      if (my $ccount = scalar(@cgColours)) {
        if ($ccount == 1) {
          unshift @cgColours, 'white';
        }
      }
      else {
        @cgColours = ('yellow', 'green', 'blue');
      }
      my $cm = new Sanger::Graphics::ColourMap;
      @colour_gradient = $cm->build_linear_gradient($cgGrades, \@cgColours);
    }

    my $regexp = $pix_per_bp > 0.1 ? '\dI' : ( $pix_per_bp > 0.01 ? '\d\dI' : '\d\d\dI' );

    next unless keys %id;
    foreach my $i ( sort {
      $id{$a}[0][3] <=> $id{$b}[0][3]  ||
      $id{$b}[-1][4] <=> $id{$a}[-1][4]
    } keys %id){
      my @F          = @{$id{$i}}; # sort { $a->[0] <=> $b->[0] } @{$id{$i}};
      my $START      = $F[0][0] < 1 ? 1 : $F[0][0];
      my $END        = $F[-1][1] > $length ? $length : $F[-1][1];
      my $db_name    = $F[0][5];
      my( $txt, $bit, $w, $th );
      my $bump_start = int($START * $pix_per_bp) - 1;
      my $bump_end   = int($END * $pix_per_bp);

      if ($config) {
        my $f = $F[0][2];
        if ($config->{'useScore'} == 1 && !$feature_colour) {
          my $index = int(($f->score * scalar(@greyscale)) / 1000);
          $feature_colour = $greyscale[$index];
        }
        elsif ($config->{'useScore'} == 2) {
          my $score = $f->score || 0;
          $score = $min_score if ($score < $min_score);
          $score = $max_score if ($score > $max_score);
          my $grade = ($score >= $max_score) ? ($cgGrades - 1) : int(($score - $min_score) / $score_per_grade);
          $feature_colour = $colour_gradient[$grade];
        }
      }
      if( $self->{'show_labels'} ) {
        my $title = $self->feature_label( $F[0][2],$db_name );
        my( $txt, $bit, $tw,$th ) = $self->get_text_width( 0, $title, '', 'ptsize' => $fontsize, 'font' => $fontname );
        my $text_end = $bump_start + $tw + 1;
        $bump_end = $text_end if $text_end > $bump_end;
      }
      my $row        = $self->bump_row( $bump_start, $bump_end );
      if( $row > $dep ) {
        $features_bumped++;
        next;
      }
      $y_pos = $y_offset - $row * int( $h + $gap * $label_h ) * $strand;

      my $Composite = $self->Composite({
        'href'  => $self->href( $F[0][2] ),
        'x'     => $F[0][0]> 1 ? $F[0][0]-1 : 0,
        'width' => 0,
        'y'     => 0,
        'title' => $self->feature_title($F[0][2],$db_name),
	      'class' => 'group',
      });
      my $X = -1e8;
      foreach my $f ( @F ){ ## Loop through each feature for this ID!
        my( $s, $e, $feat ) = @$f;
        if ($config->{'itemRgb'} =~ /on/i) {
          $feature_colour = $feat->external_data->{'item_colour'}[0];
        }
        next if int($e * $pix_per_bp) <= int( $X * $pix_per_bp );
        $features_drawn++;
        my $cigar;
        eval { $cigar = $feat->cigar_string; };
        if($DRAW_CIGAR || $cigar =~ /$regexp/ ) {
           my $START = $s < 1 ? 1 : $s;
           my $END   = $e > $length ? $length : $e;
           $X = $END;
           $Composite->push($self->Space({
             'x'          => $START-1,
             'y'          => 0, # $y_pos,
             'width'      => $END-$START+1,
             'height'     => $h,
             'absolutey'  => 1,
          }));

          $self->draw_cigar_feature({
            composite      => $Composite, 
            feature        => $feat, 
            height         => $h, 
            feature_colour => $feature_colour, 
            label_colour   => $label_colour,
            delete_colour  => 'black', 
            scalex         => $pix_per_bp
          });
        } else {
          my $START = $s < 1 ? 1 : $s;
          my $END   = $e > $length ? $length : $e;
          $X = $END;
          $Composite->push($self->Rect({
            'x'          => $START-1,
            'y'          => 0, # $y_pos,
            'width'      => $END-$START+1,
            'height'     => $h,
            'colour'     => $feature_colour,
            'label_colour' => $label_colour,
            'absolutey'  => 1,
          }));
        }
      }
      if( $h > 1 ) {
        $Composite->bordercolour($feature_colour) unless $self->my_config('format') eq 'SNP_EFFECT'; # HACK omfg
      } else {
        $Composite->unshift( $self->Rect({
          'x'         => $Composite->{'x'},
          'y'         => $Composite->{'y'},
	        'width'     => $Composite->{'width'},
	        'height'    => $h,
	        'colour'    => $join_colour,
	        'absolutey' => 1
        }));
      }
      $Composite->y( $Composite->y + $y_pos );
      $self->push( $Composite );
      if( $self->{'show_labels'} ) {
        $self->push( $self->Text({
          'font'      => $fontname,
          'colour'    => $label_colour,
          'height'    => $fontsize,
          'ptsize'    => $fontsize,
          'text'      => $self->feature_label($F[0][2],$db_name),
          'title'     => $self->feature_title($F[0][2],$db_name),
          'halign'    => 'left',
          'valign'    => 'center',
          'x'         => $Composite->{'x'},
          'y'         => $Composite->{'y'} + $h + 2,
          'width'     => $Composite->{'x'} + ($bump_end-$bump_start) / $pix_per_bp,
          'height'    => $label_h,
          'absolutey' => 1
        }));
      }
      if(exists $highlights{$i}) {
        $self->unshift( $self->Rect({
          'x'         => $Composite->{'x'} - 1/$pix_per_bp,
          'y'         => $Composite->{'y'} - 1,
          'width'     => $Composite->{'width'} + 2/$pix_per_bp,
          'height'    => $h + 2,
          'colour'    => 'highlight1',
          'absolutey' => 1,
        }));
      }
    }
    $y_offset -= $strand * ( ($self->_max_bump_row ) * ( $h + $gap + $label_h ) + 6 );
  }
  $self->errorTrack("No features from '" . $self->my_config('name') . "' in this region") unless $features_drawn || $self->{'no_empty_track_message'} || $self->{'config'}->get_option('opt_empty_tracks') == 0;

  if( $self->get_parameter( 'opt_show_bumped') && $features_bumped ) {
    my $y_pos = $strand < 0
              ? $y_offset
              : 2 + $self->{'config'}->texthelper()->height($self->{'config'}->species_defs->ENSEMBL_STYLE->{'GRAPHIC_FONT'})
              ;
    $self->errorTrack( sprintf( q(%s features from '%s' omitted), $features_bumped, $self->my_config('name')), undef, $y_offset );
  }
  $self->timer_push( 'Features drawn' );
## No features show "empty track line" if option set....
}

sub render_ungrouped_labels {
  my $self = shift;
  $self->{'show_labels'} = 1;
  $self->render_ungrouped(@_);
}

sub render_ungrouped {
  my $self        = shift;
  my $strand      = $self->strand;
  my $strand_flag = $self->my_config('strand');

  my $length      = $self->{'container'}->length();
  my $pix_per_bp  = $self->scalex;
  my $DRAW_CIGAR  = ( $self->my_config('force_cigar') eq 'yes' )|| ($pix_per_bp > 0.2) ;
  my $h           = $self->my_config('height')||8;
  my $regexp = $pix_per_bp > 0.1 ? '\dI' : ( $pix_per_bp > 0.01 ? '\d\dI' : '\d\d\dI' );
  my $features_drawn = 0;
  my $X             = -1e8; ## used to optimize drawing!
  my %features = $self->features;

## Grab all the features;
## Remove those not on this display strand
## Create an array of arrayrefs [start,end,feature]
## Sort according to start of feature....

  my $y_offset = 0;

  my $label_h = 0;
  my( $fontname, $fontsize ) ;

  if( $self->{'show_labels'} ) {
    ( $fontname, $fontsize ) = $self->get_font_details( 'outertext' );
    my( $txt, $bit, $w,$th ) = $self->get_text_width( 0, 'X', '', 'ptsize' => $fontsize, 'font' => $fontname );
    $label_h = $th;
  }

  foreach my $feature_key ( $strand < 0 ? sort keys %features : reverse sort keys %features ) {
    my $flag = 0;
    $self->{'track_key'} = $feature_key;
    my $colour_key     = $self->colour_key( $feature_key );
    my $feature_colour = $self->my_colour( $colour_key, undef  );
    my $A = $features{$feature_key};

    ## Sanity check - make sure the feature set only contains arrayrefs, or the fancy transformation
    ## below will barf (mainly when trying to handle userdata, which includes a config hashref)
    my @ok_features;
    foreach my $f (@{$features{$feature_key}}) {
      next unless ref($f) eq 'ARRAY';
      push @ok_features, $f;
    }

    $self->_init_bump( undef, '0.5' );
    foreach my $f (
      sort { $a->[0] <=> $b->[0]      }
      map  { [$_->start, $_->end,$_ ] }
      grep { !($strand_flag eq 'b' && $strand != ( ( $_->can('hstrand') ? 1 : 1 ) * $_->strand||-1) || $_->start > $length || $_->end < 1) } 
      map  { @$_                      } @ok_features
    ) {
      my($start,$end,$feat) = @$f;
      ($start,$end)         = ($end, $start) if $end<$start; # Flip start end YUK!
      $start                = 1 if $start < 1;
      $end                  = $length if $end > $length;
      ### This is where we now grab the colours
      next if( $end * $pix_per_bp ) == int( $X * $pix_per_bp );
      $X                    = $start;
      $features_drawn++;
      my $cigar;
      eval { $cigar = $feat->cigar_string; };
      $flag++;
      
      if ($DRAW_CIGAR || $cigar =~ /$regexp/ ) {
        $self->draw_cigar_feature({
          composite      => $self, 
          feature        => $feat, 
          height         => $h, 
          feature_colour => $feature_colour, 
          delete_colour  => 'black', 
          scalex         => $pix_per_bp
        });
      } else {
        $self->push($self->Rect({
          'x'          => $X-1,
          'y'          => $y_offset, # $y_pos,
          'width'      => $end-$X+1,
          'height'     => $h,
          'colour'     => $feature_colour,
          'absolutey'  => 1,
        }));
      }
      if( $self->{'show_labels'} ) {
        my( $txt, $bit, $w, $th );
        my $bump_start = int($X * $pix_per_bp) - 1;
        my $title = $self->feature_label( $f->[2] );
        my( $txt, $bit, $tw,$th ) = $self->get_text_width( 0, $title, '', 'ptsize' => $fontsize, 'font' => $fontname );
        my $bump_end = $bump_start + $tw + 1;
        my $row        = $self->bump_row( $bump_start, $bump_end );
        if( $row < 0.5 ) {
          $self->push( $self->Text({
            'font'      => $fontname,
            'colour'    => $feature_colour,
            'height'    => $fontsize,
            'ptsize'    => $fontsize,
            'text'      => $title,
            'title'     => $title,
            'halign'    => 'left',
            'valign'    => 'center',
            'x'         => $X,
            'y'         => $y_offset + $h,
            'width'     => ($bump_end-$bump_start) / $pix_per_bp,
            'height'    => $label_h,
            'absolutey' => 1
          }));
        }
      }
    }
    
    $y_offset -= $strand * ($h+2);
  }
  
  $self->errorTrack('No ' . $self->my_config('name') . ' features in this region') unless $features_drawn || $self->{'no_empty_track_message'} || $self->{'config'}->get_option('opt_empty_tracks') == 0;
}

sub render_text {
  my $self = shift;
  
  my $strand = $self->strand;
  my %features = $self->features;
  my $method = $self->can('export_feature') ? 'export_feature' : '_render_text';
  my $export;
  
  foreach my $feature_key ($strand < 0 ? sort keys %features : reverse sort keys %features) {
    foreach my $f (@{$features{$feature_key}}) {
      foreach (map { $_->[2] } sort { $a->[0] <=> $b->[0] } map { [ $_->start, $_->end, $_ ] } @{$f||[]}) {
        $export .= $self->$method($_, $self->my_config('caption'), { 'headers' => [ 'id' ], 'values' => [ $_->can('hseqname') ? $_->hseqname : $_->can('id') ? $_->id : '' ] });
      }
    }
  }
  
  return $export;
}

1;
