# $Id: TranscriptSeq.pm,v 1.3 2012-01-20 09:10:54 sb23 Exp $

package EnsEMBL::Web::Component::LRG::TranscriptSeq;

use strict;

use base qw(EnsEMBL::Web::Component::Transcript::TranscriptSeq);

sub _init {
  my $self = shift;
  $self->object($self->get_transcript); # Become like a transcript
  return $self->SUPER::_init;
}

sub object {
  my $self = shift;
  $self->{'object'} = shift if @_;
  return $self->{'object'};
}

sub get_transcript {
	my $self        = shift;
	my $param       = $self->hub->param('lrgt');
	my $transcripts = $self->builder->object->get_all_transcripts;
  return $param ? grep $_->stable_id eq $param, @$transcripts : $transcripts->[0];
}

sub content {
  my $self = shift;
  return sprintf '<h2>Transcript ID: %s</h2>%s', $self->object->stable_id, $self->SUPER::content;
}

1;
