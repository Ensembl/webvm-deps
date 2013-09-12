# $Id: Blast.pm,v 1.9 2010-09-28 10:10:54 sb23 Exp $

package EnsEMBL::Web::Configuration::Blast;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Search';
}

sub populate_tree {
  my $self = shift;

  $self->create_node( 'Search', "New Search",
    [qw(
      search    EnsEMBL::Web::Component::Blast::Search
    )],
    { 'availability' => 1}
  );

  $self->create_node( 'Retrieve', "Retrieve Ticket",
    [qw(
      retrieve    EnsEMBL::Web::Component::Blast::Retrieve
    )],
    { 'availability' => 1}
  );

  ## Add "invisible" nodes used by interface but not displayed in navigation
  $self->create_node( 'Submit', '',
    [qw(sent EnsEMBL::Web::Component::Blast::Submit
        )],
      { 'no_menu_entry' => 1 }
  );
  $self->create_node( 'Ticket', '',
    [qw(ticket EnsEMBL::Web::Component::Blast::Ticket
        )],
      { 'no_menu_entry' => 1 }
  );
  $self->create_node( 'Raw', '',
    [qw(raw EnsEMBL::Web::Component::Blast::Raw
        )],
      { 'no_menu_entry' => 1 }
  );
  $self->create_node( 'View', '',
    [qw(view EnsEMBL::Web::Component::Blast::View
        )],
      { 'no_menu_entry' => 1 }
  );
  $self->create_node( 'Alignment', '',
    [qw(align EnsEMBL::Web::Component::Blast::Alignment
        )],
      { 'no_menu_entry' => 1 }
  );
  $self->create_node( 'QuerySequence', '',
    [qw(query EnsEMBL::Web::Component::Blast::QuerySequence
        )],
      { 'no_menu_entry' => 1 }
  );
  $self->create_node( 'GenomicSequence', '',
    [qw(genomic EnsEMBL::Web::Component::Blast::GenomicSequence
        )],
      { 'no_menu_entry' => 1 }
  );
}

1;
