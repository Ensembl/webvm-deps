# $Id: TranscriptSeq.pm,v 1.6 2012-07-30 11:41:41 sb23 Exp $

package EnsEMBL::Web::ViewConfig::Transcript::TranscriptSeq;

use strict;

use base qw(EnsEMBL::Web::ViewConfig::TextSequence);

sub init {
  my $self = shift;
  
  $self->set_defaults({
    exons          => 'yes',
    codons         => 'yes',
    utr            => 'yes',
    coding_seq     => 'yes',
    translation    => 'yes',
    rna            => 'no',
    snp_display    => 'yes',
    line_numbering => 'sequence',
  });
  
  $self->title = 'cDNA sequence';
  $self->SUPER::init;
}

sub form {
  my $self = shift;

  $self->add_form_element({ type => 'YesNo', name => 'exons',       select => 'select', label => 'Show exons'            });
  $self->add_form_element({ type => 'YesNo', name => 'codons',      select => 'select', label => 'Show codons'           });
  $self->add_form_element({ type => 'YesNo', name => 'utr',         select => 'select', label => 'Show UTR'              });
  $self->add_form_element({ type => 'YesNo', name => 'coding_seq',  select => 'select', label => 'Show coding sequence'  });
  $self->add_form_element({ type => 'YesNo', name => 'translation', select => 'select', label => 'Show protein sequence' });
  $self->add_form_element({ type => 'YesNo', name => 'rna',         select => 'select', label => 'Show RNA features'     });
  $self->variation_options({ populations => [ 'fetch_all_HapMap_Populations', 'fetch_all_1KG_Populations' ], snp_link => 'no' }) if $self->species_defs->databases->{'DATABASE_VARIATION'};
  $self->add_form_element({
    type   => 'DropDown', 
    select => 'select',
    name   => 'line_numbering',
    label  => 'Line numbering',
    values => [
      { value => 'sequence', name => 'Yes' },
      { value => 'off',      name => 'No'  },
    ]
  });
}

1;
