# $Id: ListVegaMappings.pm,v 1.8 2011-01-20 17:10:39 sb23 Exp $

package EnsEMBL::Web::Component::Help::ListVegaMappings;

use strict;

use base qw(EnsEMBL::Web::Component::Help);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(0);
  $self->configurable(0);
}

sub content {
  my $self           = shift;
  my $hub            = $self->hub;
  my $species        = $hub->species;
  my $location       = $self->builder->object('Location');
  my $chromosome     = $location->seq_region_name;
  my $ensembl_start  = $location->seq_region_start;
  my $alt_assemblies = $hub->species_defs->ALTERNATIVE_ASSEMBLIES;
  my $referer        = $hub->referer;
  
  # get coordinates of other assemblies (Vega)  
  if ($alt_assemblies) {
    my $table = $self->new_table([], [], { data_table => 1, sorting => [ 'ensemblcoordinates asc' ] });

    $table->add_columns(
      { key => 'ensemblcoordinates', title => 'Ensembl coordinates',               align => 'left', sort => 'position'      },
      { key => 'length',             title => 'Length',                            align => 'left', sort => 'numeric'       },
      { key => 'targetcoordinates',  title => "$alt_assemblies->[0] coordinates",  align => 'left', sort => 'position_html' }
    );
    
    my $reg        = 'Bio::EnsEMBL::Registry';
    my $orig_group = $reg->get_DNAAdaptor($species, 'vega')->group;
    
    $reg->add_DNAAdaptor($species, 'vega', $species, 'vega');
    
    my $start       = $location->seq_region_start;
    my $end         = $location->seq_region_end;         
    my $vega_slices = $hub->get_adaptor('get_SliceAdaptor', 'vega')->fetch_by_region('chromosome', $chromosome, $start, $end, 1, 'GRCh37')->project('chromosome', $alt_assemblies->[0]);
    my $base_url    = $hub->ExtURL->get_url('VEGA') . "$species/$referer->{'ENSEMBL_TYPE'}/$referer->{'ENSEMBL_ACTION'}";
    
    foreach my $segment (@$vega_slices) {
      my $s          = $segment->from_start + $ensembl_start - 1;
      my $slice      = $segment->to_Slice;
      my $mapped_url = "$base_url?r=" . $slice->seq_region_name. ':' . $slice->start. '-'.  $slice->end;
	    my $match_txt  = $slice->seq_region_name . ':' . $hub->thousandify($slice->start) . '-' . $hub->thousandify($slice->end);
      
	    $table->add_row({
        ensemblcoordinates => "$chromosome:$s-" . ($slice->length + $s - 1),
		    length             => $slice->length, 
		    targetcoordinates  => qq{<a href="$mapped_url" rel="external">$match_txt</a>}
      });
    }
    
    $reg->add_DNAAdaptor($species, 'vega', $species, $orig_group); # set dnadb back to the original group
    
    return sprintf '<input type="hidden" class="panel_type" value="Content" /><h2>Vega mappings</h2>%s', $table->render;  	
  }
}

1;
