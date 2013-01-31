package EnsEMBL::Web::Component::Transcript::PepStats;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Transcript);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  1 );
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $tl = $object->Obj->translation;
  return '' unless $tl;
  return '<p>Pepstats currently disabled for Prediction Transcripts</p>' unless $tl->stable_id;

  my $db_group = $object->Obj->adaptor->db->group;
  return '<p>Pepstats currently disabled for transcripts of this type</p>' unless $db_group=~/core|vega/;

  my $db_type = ($object->db_type eq 'Ensembl') ? 'core' : lc($object->db_type); #thought there was a better way to do this!
  my $attributeAdaptor = $object->database($db_type)->get_AttributeAdaptor();
  my $attributes = $attributeAdaptor->fetch_all_by_Translation($tl);
  my $stats_to_show = '';
  my @attributes_pepstats = grep {$_->description =~ /Pepstats/} @{$attributes};
  foreach my $stat (sort {$a->name cmp $b->name} @attributes_pepstats) {
    my $stat_string = $object->thousandify($stat->value);
    if ($stat->name =~ /weight/) {
      $stat_string .= ' g/mol';
    }
    elsif ($stat->name =~ /residues/) {
      $stat_string .= ' aa';
    }
    $stats_to_show .= sprintf("<p>%s: %s</p>", $stat->name, $stat_string);
  }
  return $stats_to_show ? $self->new_twocol(['Statistics', $stats_to_show])->render : '';
}

1;