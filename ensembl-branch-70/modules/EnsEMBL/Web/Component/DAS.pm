# $Id: DAS.pm,v 1.11 2010-09-28 10:13:57 sb23 Exp $

package EnsEMBL::Web::Component::DAS;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Component);

sub types {
  my $self     = shift;
  my $object   = $self->object;
  my $features = $object->Types;
  my $url      = $object->species_defs->ENSEMBL_BASE_URL . encode_entities($ENV{'REQUEST_URI'});
  my $template = qq{<TYPE id="%s"%s%s>%s</TYPE>\n};
  my $xml      = qq{<GFF href="$url" version="1.0">};

  foreach my $segment (@{$features || []}) {
    if ($segment->{'TYPE'} && $segment->{'TYPE'} eq 'ERROR') {
      if ($segment->{'START'} && $segment->{'END'}) {
        $xml .= qq{\n<ERRORSEGMENT id="$segment->{'REGION'}" start="$segment->{'START'}" stop="$segment->{'STOP'}" />};
      } else {
        $xml .= qq{\n<ERRORSEGMENT id="$segment->{'REGION'}" />};
      }
      
      next;
    }
    
    if ($segment->{'TYPE'} && $segment->{'TYPE'} eq 'UNKNOWN') {
      if ($segment->{'START'} && $segment->{'END'}) {
        $xml .= qq{\n<UNKNOWNSEGMENT id="$segment->{'REGION'}" start="$segment->{'START'}" stop="$segment->{'STOP'}" />};
      } else {
        $xml .= qq{\n<UNKNOWNSEGMENT id="$segment->{'REGION'}" />};
      }
      
      next;
    }
    
    if ($segment->{'REGION'}) { 
      $xml .= sprintf qq{\n<SEGMENT id="$segment->{'REGION'}" start="$segment->{'START'}" stop="$segment->{'STOP'}"%s>}, $segment->{'TYPE'} ? qq{ type="$segment->{'TYPE'}"} : '';
    } else {
      $xml .= "\n<SEGMENT>";
    }
    
    foreach my $feature (@{$segment->{'FEATURES'} || []}) {
      my $extra = '';
      $extra   .= qq{ method="$feature->{'method'}"}     if exists $feature->{'method'};
      $extra   .= qq{ category="$feature->{'category'}"} if exists $feature->{'category'};
      
      $xml .= qq{\n  <TYPE id="$feature->{'id'}"$extra>$feature->{'text'}</TYPE>};
    }
    
    $xml .= "\n</SEGMENT>";
  }
  
  $xml .= "\n</GFF>\n";
  
  return $xml;
}

sub features {
  my $self     = shift;
  my $object   = $self->object;
  my $features = $object->Features;
  my $url      = $object->species_defs->ENSEMBL_BASE_URL . encode_entities($ENV{'REQUEST_URI'});
  my $xml      = qq{<GFF href="$url" version="1.0">};
  
  my $feature_template = qq{
  <FEATURE id="%s"%s>
    <START>%d</START>
    <END>%d</END>
    <TYPE id="%s"%s>%s</TYPE>
    <METHOD id="%s">%s</METHOD>
    <SCORE>%s</SCORE>
    <ORIENTATION>%s</ORIENTATION>%s
  </FEATURE>};
  
  foreach my $segment (@{$features || []}) {
    if ($segment->{'TYPE'} && $segment->{'TYPE'} eq 'ERROR') {
      $xml .= qq{\n<ERRORSEGMENT id="$segment->{'REGION'}" start="$segment->{'START'}" stop="$segment->{'STOP'}" />};
      next;
    }
    
    if ($segment->{'TYPE'} && $segment->{'TYPE'} eq 'UNKNOWN') {
      $xml .= qq{\n<UNKNOWNSEGMENT id="$segment->{'REGION'}" start="$segment->{'START'}" stop="$segment->{'STOP'}" />};
      next;
    }

    $xml .= sprintf qq{\n<SEGMENT id="$segment->{'REGION'}" start="$segment->{'START'}" stop="$segment->{'STOP'}"%s>}, $segment->{'TYPE'} ? qq{ type="$segment->{'TYPE'}"} : '';

    foreach my $feature (@{$segment->{'FEATURES'} || []}) {
      my ($extra_tags, $extra_type);
      
      foreach my $g (@{$feature->{'GROUP'} || []}) {
        $extra_tags .= sprintf qq{\n    <GROUP id="$g->{'ID'}"%s%s>}, $g->{'TYPE'} ? qq{ type="$g->{'TYPE'}"} : '', $g->{'LABEL'} ? qq{ label="$g->{'LABEL'}"}  : '';
        $extra_tags .= sprintf qq{\n      <LINK href="%s">%s</LINK>}, encode_entities($_->{'href'}), encode_entities($_->{'text'} || $_->{'href'}) for @{$g->{'LINK'} || []};
        $extra_tags .= sprintf qq{\n      <NOTE>%s</NOTE>}, encode_entities($_) for @{$g->{'NOTE'} || []};
        $extra_tags .= "\n    </GROUP>";
      }
      
      $extra_tags .= sprintf qq{\n    <LINK href="%s">%s</LINK>}, encode_entities($_->{'href'}), encode_entities($_->{'text'} || $_->{'href'}) for @{$feature->{'LINK'} || []};
      $extra_tags .= sprintf qq{\n    <NOTE>%s</NOTE>}, encode_entities($_) for @{$feature->{'NOTE'} || []};
      $extra_tags .= sprintf qq{\n    <TARGET id="%s" start="$feature->{'TARGET'}{'START'}" stop="$feature->{'TARGET'}{'STOP'}" />}, encode_entities($feature->{'TARGET'}{'ID'}) if exists $feature->{'TARGET'};
      
      $extra_type .= sprintf ' reference="yes" superparts="%s" subparts="%s"', $feature->{'SUPERPARTS'} || 'no', $feature->{'SUBPARTS'} || 'no' if $feature->{'REFERENCE'};
      $extra_type .= qq{ category="$feature->{'CATEGORY'}"} if exists $feature->{'CATEGORY'};
      
      $xml .= sprintf($feature_template,
        $feature->{'ID'}          || '',
        exists $feature->{'LABEL'} ? qq{ label="$feature->{'LABEL'}"} : '',
        $feature->{'START'}       || '',
        $feature->{'END'}         || '',
        $feature->{'TYPE'}        || '',
        $extra_type,
        $feature->{'TYPE'}        || '',
        $feature->{'METHOD'}      || '',
        $feature->{'METHOD'}      || '',
        $feature->{'SCORE'}       || '-',
        $feature->{'ORIENTATION'} || '.',
        $extra_tags
      );
    }
    
    $xml .= "\n</SEGMENT>";
  }
  
  $xml .= "\n</GFF>\n";
  
  return $xml;
}

sub stylesheet { return shift->object->Stylesheet; }

1;