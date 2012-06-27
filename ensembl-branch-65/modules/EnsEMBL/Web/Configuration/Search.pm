# $Id: Search.pm,v 1.14 2011-05-19 12:12:27 ap5 Exp $

package EnsEMBL::Web::Configuration::Search;

use strict;

use base qw(EnsEMBL::Web::Configuration);

sub query_string   { return ''; }

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'New';
}

sub populate_tree {
  my $self = shift;

  $self->create_node('New', 'New Search',
    [qw(new EnsEMBL::Web::Component::Search::New)],
    { availability => 1 }
  );

  $self->create_node('Results', 'Results Summary',
    [qw(results EnsEMBL::Web::Component::Search::Results)],
    { no_menu_entry => 1 }
  );
}

1;
