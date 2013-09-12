#$Id: Phenotype.pm,v 1.6 2013-03-20 12:17:51 wm2 Exp $
package EnsEMBL::Web::Object::Phenotype;

use strict;

use base qw(EnsEMBL::Web::Object::Feature);

sub short_caption {
  my $self = shift;
  my $caption;
  my $name = $self->get_phenotype_desc;
  if (shift eq 'global') {
    $caption = $name ? "Phenotype: $name" : 'Phenotypes';
  }
  else {
    $caption = 'Phenotype-based displays';
  }
  return $caption;
}

sub caption {
  my $self = shift;
  return $self->get_phenotype_desc;
}

sub long_caption {
  my $self = shift;
  $self->has_features ? 'Locations of features associated with '.$self->get_phenotype_desc 
                      : 'No features associated with phenotype '.$self->get_phenotype_desc;
}

sub phenotype_id      { $_[0]->{'data'}{'phenotype_id'} = $_[1] if $_[1]; return $_[0]->{'data'}{'phenotype_id'}; }

sub has_features {
  my $self = shift;
  return $self->Obj->{'Variation'} ? 1 : 0;
}

sub get_phenotype_desc {
  my $self = shift;
  return unless $self->hub->param('ph');
  my $vardb   = $self->hub->database('variation');
  my $pa      = $vardb->get_adaptor('Phenotype');
  my $p       = $pa->fetch_by_dbID($self->hub->param('ph'));
  return $p ? $p->description : undef;
};

sub get_all_phenotypes {
  my $self = shift;
  my $vardb = $self->hub->database('variation');
  my $pa    = $vardb->get_adaptor('Phenotype');
  return $pa->fetch_all();
};

1;
