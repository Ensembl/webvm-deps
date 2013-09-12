# $Id: SimilarityMatches.pm,v 1.3 2012-04-05 12:50:37 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Gene::SimilarityMatches;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;
  $self->set_defaults({ map { $_->{'name'} => $_->{'priority'} > 100 ? 'yes' : 'off' } $self->get_xref_types });
  $self->title = 'External references';
}

sub form {
  my $self = shift;
  foreach (sort { $b->{'priority'} <=> $a->{'priority'} || $a->{'name'} cmp $b->{'name'}} $self->get_xref_types) {
    $self->add_form_element({
      type   => 'CheckBox',
      select => 'select',
      name   => $_->{'name'},
      label  => $_->{'name'},
      value  => 'yes'
    });
  }
}

sub get_xref_types {
  my $self = shift;
  my @xref_types;
  my $no_vega_trans = 1 if ($self->hub->get_db eq 'vega' || $self->species_defs->ENSEMBL_SITETYPE eq 'Vega');
  foreach (split /,/, $self->species_defs->XREF_TYPES) {
    my @type_priorities = split /=/;
    next if ($no_vega_trans && $type_priorities[0] =~ /Vega/);
    push @xref_types, {
      name     => $type_priorities[0],
      priority => $type_priorities[1]
    };
  }
  return @xref_types;
}

1;
