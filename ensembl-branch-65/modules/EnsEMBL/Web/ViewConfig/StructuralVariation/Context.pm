# $Id: Context.pm,v 1.4 2011-11-16 13:13:10 sb23 Exp $

package EnsEMBL::Web::ViewConfig::StructuralVariation::Context;

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self     = shift;
  my %options  = EnsEMBL::Web::Constants::VARIATION_OPTIONS;
  my $defaults = { context => 20000 };

  foreach (keys %options) {
    my %hash = %{$options{$_}};
    $defaults->{lc $_} = $hash{$_}[0] for keys %hash;
  }
	
  $self->set_defaults($defaults);
  $self->add_image_config('structural_variation', 'nodas');
  $self->title = 'Genomic context';
}

sub form {
  my $self = shift;
  
  $self->add_form_element({
    type   => 'DropDown',
    select => 'select',
    name   => 'context',
    label  => 'Context',
    values => [
      { value => '1000',  name => '1kb'  },
      { value => '5000',  name => '5kb'  },
      { value => '10000', name => '10kb' },
      { value => '20000', name => '20kb' },
      { value => '30000', name => '30kb' }
    ]
  });
}

1;
