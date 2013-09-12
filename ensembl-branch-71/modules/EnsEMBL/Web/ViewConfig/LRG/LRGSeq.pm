# $Id: LRGSeq.pm,v 1.3 2012-01-27 14:45:17 sb23 Exp $

package EnsEMBL::Web::ViewConfig::LRG::LRGSeq;

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self = shift;
  
  $self->set_defaults({
    flank5_display => 0,
    flank3_display => 0,
    exon_display   => 'core',
    exon_ori       => 'all',
    snp_display    => 'snp_link',
    line_numbering => 'sequence'
  });

  $self->title = 'Sequence';
  $self->SUPER::init;
}

sub form {
  my $self                   = shift;
  my $dbs                    = $self->species_defs->databases;
  my %gene_markup_options    = EnsEMBL::Web::Constants::GENE_MARKUP_OPTIONS;
  my %general_markup_options = EnsEMBL::Web::Constants::GENERAL_MARKUP_OPTIONS;
  my %other_markup_options   = EnsEMBL::Web::Constants::OTHER_MARKUP_OPTIONS;
  
  push @{$gene_markup_options{'exon_display'}{'values'}}, { value => 'vega', name => 'Vega exons' } if $dbs->{'DATABASE_VEGA'};
  
  $_->{'name'} = 'Core and LRG exons' for grep $_->{'value'} eq 'core', @{$gene_markup_options{'exon_display'}{'values'}};

  push @{$gene_markup_options{'exon_display'}{'values'}}, { value => 'otherfeatures', name => 'EST gene exons' } if $dbs->{'DATABASE_OTHERFEATURES'};
  
  $self->add_form_element($gene_markup_options{'flank5_display'});
  $self->add_form_element($gene_markup_options{'flank3_display'});
  $self->add_form_element($other_markup_options{'display_width'});
  $self->add_form_element($gene_markup_options{'exon_display'});
  $self->add_form_element($general_markup_options{'exon_ori'});
  $self->variation_options if $dbs->{'DATABASE_VARIATION'};
  $self->add_form_element($general_markup_options{'line_numbering'});
}

1;
