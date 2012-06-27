# $Id: LRGDiff.pm,v 1.5 2011-09-02 15:48:10 lg10 Exp $

package EnsEMBL::Web::Component::LRG::LRGDiff;

### NAME: EnsEMBL::Web::Component::LRG::LRGDiff;
### Generates a table of differences between the LRG and the reference sequence

### STATUS: Under development

### DESCRIPTION:
### Because the LRG page is a composite of different domain object views, 
### the contents of this component vary depending on the object generated
### by the factory

use strict;

use base qw(EnsEMBL::Web::Component::LRG);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $lrg  = $self->object->Obj;
  my $html;
  
  my $columns = [
    { key => 'location', sort => 'position_html', title => 'Location'           },
    { key => 'type',     sort => 'string',        title => 'Type'               },
    { key => 'lrg' ,     sort => 'string',        title => 'LRG sequence'       },
    { key => 'ref',      sort => 'string',        title => 'Reference sequence' },
  ];
  
  my @rows;
  
  foreach my $diff (@{$lrg->get_all_differences}) {
		
		my $align_link .= '#'.$diff->{start};
		my $align_page = qq{<a href="$align_link">[Show in alignment]</a>};
		
    push @rows, {
      location => $lrg->seq_region_name . ":$diff->{'start'}" . ($diff->{'end'} == $diff->{'start'} ? '' : "-$diff->{'end'}") . "  $align_page",
      type     => $diff->{'type'},
      lrg      => $diff->{'seq'},
      ref      => $diff->{'ref'},
    };
  }
  
  if (@rows) {
    $html .= $self->new_table($columns, \@rows, { data_table => 1, sorting => [ 'location asc' ] })->render;
  } else {
    # find the name of the reference assembly
    my $csa = $self->hub->get_adaptor('get_CoordSystemAdaptor');
    my $assembly = $csa->fetch_all->[0]->version;
      
    $html .= "<h3>No differences found - the LRG reference sequence is identical to the $assembly reference assembly sequence</h3>";
  }
  
  return $html;
}

1;
