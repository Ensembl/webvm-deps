#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2002-04-17
# Last Modified: $Date: 2007/02/13 18:47:26 $
#
# draw lists in html tables
#
package Website::Utilities::Tabulate;
use strict;
use warnings;
use Website::Utilities::IdGenerator;

our $VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

  Website::Utilities::Tabulate

=head1 SYNOPSIS

  my $tab = Website::Tabulate->new({
				  'columns'     => 5,
				  'title'       => 'Table Title',
				  'order'       => vertical|horizontal,
                                  'nowrap'      => 1,
                                  'cellspacing' => 1,
                                  'cellpadding' => 1,
                                  'border'  => on|off
				  'data'    => [
						'val1',
						...
					       ]
                                  });
  print $tab->draw();

=cut

sub new {
  my ($class, $refs) = @_;
  my $self = {};
  bless($self, $class);

  for my $f (qw(class
		id
		columns
		title
		titles
		order
		data
		width
		map
		data
		nowrap
		cellspacing
		cellpadding
		align
		border
		tdalign
		close)) {
    $self->{$f} = $refs->{$f} if(defined $refs->{$f});
  }

  return $self;
}

sub draw {
  my ($self)      = @_;
  my $columns     = $self->{'columns'}     || 1;
  my $title       = $self->{'title'}       || '';
  my $width       = $self->{'width'}       || 400,
  my $order       = $self->{'order'}       || 'vertical';
  my $nowrap      = $self->{'nowrap'}?'nowrap':'';
  my $cellspacing = $self->{'cellspacing'} || 0;
  my $cellpadding = $self->{'cellpadding'} || 0;
  my $border      = $self->{'border'}      || 'on';
  my $align       = $self->{'align'}       || 'center';
  my $topright    = $self->{'close'}?{
				      'image' => '/gfx/box/close.gif',
				      'link'  => $self->{'close'},
				      'alt'   => 'Close',
				     }:undef;
  my $tdalign     = ($self->{'tdalign'})?qq(align="$self->{'tdalign'}"):'';
  my $column      = 1;
  my $tablecols   = ($columns * 2) + 1;
  my $tablecols2  = $tablecols-2;
  my $tablerows   = ((scalar @{$self->{'data'}})/$columns) + ($columns+2);
  my $content     = '';
  $tablerows      = 5 if($tablerows < 5);


  if(int($tablerows) < $tablerows) {
    $tablerows = int($tablerows) + 1;
  } else {
    $tablerows = int($tablerows);
  }

  my $colspan = '';
  $colspan = qq(colspan="$tablecols") if($tablecols != 1);

  my $colspan2 = '';
  $colspan2 = qq(colspan="$tablecols2") if($tablecols2 != 1);

  if($order eq 'horizontal') {
    for my $key (@{$self->{'data'}}) {
      if($column == 1) {
	$content .= qq(  <tr>\n);
      }
      $content .= qq(    <td $tdalign $nowrap>$key</td>\n);

      $column++;
      if($column > $columns) {
	$column   = 1;
	$content .= qq(  </tr>\n);
      }
    }

    $column--;
    if($column <= 0) {
      $column = 3;
    }
    if($column != 3) {
      for(my $i=1; $i <= ($columns - $column); $i++) {
	$content .= qq(    <td>&nbsp;</td>\n);
      }
      $content .= "  </tr>\n";
    }

  } elsif ($order eq 'vertical') {
    my $len = (scalar @{$self->{'data'}});
    if(($len % $columns)!=0) {
      $len = $len + ($columns - ($len % $columns));
    }
    my $mod = $len / $columns;

    for(my $rows=0; $rows<$mod; $rows++) {
      $content .= qq(  <tr>\n);

      for(my $cols=0;$cols<$columns; $cols++) {
	my $entry = $rows + ($cols * $mod);
	my $val   = @{$self->{'data'}}[$entry] || '&nbsp;';
	$content .= qq(    <td $tdalign $nowrap>$val</td>\n);
      }
      $content .= qq(  </tr>\n);
    }
  }

  $content ||= '';
  $width     = ($width =~ /%$/)?$width:$width.'px';
  $width     = $width?qq(style="width:${width};"):'';
  $title     = $title?qq(<div class="legend">$title</div>\n):'';
  my $class  = $self->{'class'} || 'zebra';
  my $id     = $self->{'id'}    || Website::Utilities::IdGenerator->get_unique_id();
  return qq(<div class="fieldset" $width>\n$title<div class="content"><table class="$class" id="$id">$content</table></div></div>\n);
}

# deprecated - stub left in so as not to break too many things
sub flexi_table {
  my ($title, $content, $attr) = @_;
  $content  = $$content if(ref($content));
  return $content;
}

sub basic {
  my ($self, $defs) = @_;
  my $data    = $self->{'data'};

  return unless(defined $data);

  my $titles  = $self->{'titles'};
  my $title   = $self->{'title'};
  my $maps    = $self->{'map'};
  my $id      = $self->{'id'}    || Website::Utilities::IdGenerator->get_unique_id();
  my $class   = $self->{'class'} || 'zebra';
  my $columns = scalar @{$titles};
  my $content = qq(<table border="0" id="$id" class="$class">\n  <thead><tr>);

  if($title) {
    my $colspan = scalar grep { defined } @{$titles};
    $content .= qq(<th class="barial" colspan="$colspan">&nbsp;$title&nbsp;</th></tr></thead>\n  <tbody><tr>);
  }

  map { $content .= qq(<th class="barial">&nbsp;$_&nbsp;</th>) } grep { defined } @{$titles};

  $content .= qq(</tr>\n);

  for my $row (@$data) {
    $content .= qq(  <tr>);

    for (my $i=0; $i<$columns; $i++) {
      my $val = $row->[$i];

      if(exists($maps->{$i})) {
        $val = &{$maps->{$i}}($defs, $val);
      }

      next unless(defined $titles->[$i]);

      my $align = ($val =~ /^[0-9\.\,\-]+$/)?qq(align="center"):'';

      $content .= qq(<td $align>$val</td>);
    }
    $content .= qq(</tr>\n);
  }
  $content .= qq(</tbody></table><br />);
}

1;
