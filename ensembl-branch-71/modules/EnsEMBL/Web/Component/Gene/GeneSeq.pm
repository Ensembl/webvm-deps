# $Id: GeneSeq.pm,v 1.37.6.1 2013-05-07 15:23:34 ds23 Exp $

package EnsEMBL::Web::Component::Gene::GeneSeq;

use strict;

use base qw(EnsEMBL::Web::Component::TextSequence EnsEMBL::Web::Component::Gene);

sub _init { $_[0]->SUPER::_init(5000); }

sub initialize {
  my ($self, $slice, $start, $end) = @_;
  my $hub    = $self->hub;
  my $object = $self->object;
  
  my $config = {
    display_width   => $hub->param('display_width') || 60,
    site_type       => ucfirst(lc $hub->species_defs->ENSEMBL_SITETYPE) || 'Ensembl',
    gene_name       => $object->Obj->can('external_name') ? $object->Obj->external_name : $object->stable_id,
    species         => $hub->species,
    sub_slice_start => $start,
    sub_slice_end   => $end,
    ambiguity       => 1,
  };

  for (qw(exon_display exon_ori snp_display line_numbering title_display)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }
  
  $config->{'exon_features'} = $object->Obj->get_all_Exons;
  $config->{'slices'}        = [{ slice => $slice, name => $config->{'species'} }];
  $config->{'end_number'}    = $config->{'number'} = 1 if $config->{'line_numbering'};

  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);

  $self->markup_exons($sequence, $markup, $config)     if $config->{'exon_display'};
  $self->markup_variation($sequence, $markup, $config) if $config->{'snp_display'};
  $self->markup_line_numbers($sequence, $config)       if $config->{'line_numbering'};
  
  return ($sequence, $config);
}

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $slice     = $self->object->slice;
  my $length    = $slice->length;
  my $species   = $hub->species;
  my $type      = $hub->type;
  my $site_type = ucfirst(lc $hub->species_defs->ENSEMBL_SITETYPE) || 'Ensembl';
  my $html      = $self->tool_buttons(uc $slice->seq(1), $species);
  
  if ($length >= $self->{'subslice_length'}) {
    $html .= '<div class="sequence_key"></div>' . $self->chunked_content($length, $self->{'subslice_length'}, { length => $length, name => $slice->name });
  } else {
    $html .= $self->content_sub_slice($slice); # Direct call if the sequence length is short enough
  }
  
  $html .= $self->_info('Sequence markup', qq{
    <p>
      $site_type has a number of sequence markup pages on the site. You can view the exon/intron structure
      of individual transcripts by selecting the transcript name in the table above, then clicking
      Exons in the left hand menu. Alternatively you can see the sequence of the transcript along with its
      protein translation and variation features by selecting the transcript followed by Sequence &gt; cDNA.
    </p>
    <p>
      This view and the transcript based sequence views are configurable by clicking on the "Configure this page"
      link in the left hand menu
    </p>
  });
  
  return $html;
}

sub content_sub_slice {
  my ($self, $slice) = @_;
  my $hub    = $self->hub;
  my $start  = $hub->param('subslice_start');
  my $end    = $hub->param('subslice_end');
  my $length = $hub->param('length');
  
  $slice ||= $self->object->slice;
  $slice   = $slice->sub_Slice($start, $end) if $start && $end;
  
  my ($sequence, $config) = $self->initialize($slice, $start, $end);
  
  if ($end && $end == $length) {
    $config->{'html_template'} = '<pre class="text_sequence">%s</pre>';
  } elsif ($start && $end) {
    $config->{'html_template'} = sprintf '<pre class="text_sequence" style="margin:0">%s%%s</pre>', $start == 1 ? '&gt;' . $hub->param('name') . "\n" : '';
  } else {
    $config->{'html_template'} = sprintf('<div class="sequence_key">%s</div>', $self->get_key($config)) . '<pre class="text_sequence">&gt;' . $slice->name . "\n%s</pre>";
  }
  
  $config->{'html_template'} .= '<p class="invisible">.</p>';
  $self->id(''); 
  return $self->build_sequence($sequence, $config);
}

sub content_rtf {
  my $self = shift;
  my ($sequence, $config) = $self->initialize($self->object->slice);
  return $self->export_sequence($sequence, $config, "Gene-Sequence-$config->{'species'}-$config->{'gene_name'}");
}

sub get_key {
  my ($self, $config) = @_;
  
  my $exon_type;
     $exon_type = $config->{'exon_display'} unless $config->{'exon_display'} eq 'selected';
     $exon_type = 'All' if $exon_type eq 'core' || !$exon_type;
     $exon_type = ucfirst $exon_type;
  
  my $key = {
    exons => {
      gene    => { class => 'eg', text => "$config->{'gene_name'} $config->{'gene_exon_type'}" },
      other   => { class => 'eo', text => "$exon_type exons in this region" },
      compara => { class => 'e2', text => "$exon_type exons in this region" }
    }
  };
  
  return $self->SUPER::get_key($config, $key);
}

1;