# $Id: Genome.pm,v 1.7 2010-11-24 09:36:26 sb23 Exp $

package EnsEMBL::Web::ZMenu::Genome;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self         = shift;

  my $hub          = $self->hub;
  my $id           = $hub->param('id');
  my $db           = $hub->param('db') || 'core'; 
  my $object_type  = $hub->param('ftype');
  my $db_adaptor   = $hub->database(lc($db));
  my $adaptor_name = "get_${object_type}Adaptor";
  my $feat_adap    = $db_adaptor->$adaptor_name;
  
  my $features = $feat_adap->can('fetch_all_by_hit_name') ? $feat_adap->fetch_all_by_hit_name($id) : 
          $feat_adap->can('fetch_all_by_probeset') ? $feat_adap->fetch_all_by_probeset($id) : [];
  
  my $external_db_id = $features->[0] && $features->[0]->can('external_db_id') ? $features->[0]->external_db_id : '';
  my $extdbs         = $external_db_id ? $hub->species_defs->databases->{'DATABASE_CORE'}{'tables'}{'external_db'}{'entries'} : {};
  my $hit_db_name    = $extdbs->{$external_db_id}->{'db_name'} || 'External Feature';
  
  
  
  my $logic_name     = $features->[0] ? $features->[0]->analysis->logic_name : undef;
  
  $hit_db_name = 'TRACE' if $logic_name =~ /sheep_bac_ends|BACends/; # hack to link sheep bac ends to trace archive;

  $self->caption("$id ($hit_db_name)");

  my (@seq, $desc);
  eval {
    @seq  = $hit_db_name =~ /CCDS/ ? () : split "\n", $hub->get_ext_seq($id, $hit_db_name)->[0]; # don't show EMBL desc for CCDS
    $desc = $seq[0];
  };
  if ($desc) {
    $desc =~ s/^\s//;
    if ($desc =~ s/^>//) {
      $self->add_entry({
        label => $desc
      });
    }
  }

  $self->add_entry({
    label => $hit_db_name eq 'TRACE' ? 'View Trace archive' : $id,
    link  => encode_entities($hub->get_ExtURL($hit_db_name, $id))
  });

  if ($logic_name and my $ext_url = $hub->get_ExtURL($logic_name, $id)) {
    $self->add_entry({
      label => "View in external database",
      link  => encode_entities($ext_url)
    }); 
  } 
 
  $self->add_entry({ 
    label => 'View all hits',
    link  => $hub->url({
      type    => 'Location',
      action  => 'Genome',
      ftype   => $object_type,
      id      => $id,
      db      => $db,
      __clear => 1
    })
  });
  
}

1;
