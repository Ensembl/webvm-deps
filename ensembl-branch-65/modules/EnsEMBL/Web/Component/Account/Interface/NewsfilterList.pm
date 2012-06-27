# $Id: NewsfilterList.pm,v 1.6.12.1 2012-01-23 13:25:42 ds23 Exp $

package EnsEMBL::Web::Component::Account::Interface::NewsfilterList;

### Module to create user news filter list - duh!

use strict;

use base qw(EnsEMBL::Web::Component::Account);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $user = $object->user;
  my $sitename = $self->site_name;
  my @filters = $user->newsfilters;
  my $has_filters = 0;
  my $html;

  if ($#filters > -1) {

    $html .= qq(<h3>Your news filters</h3>
    <p>N.B. Currently we only offer the option to filter news by species.</p>);
    ## Sort user filters by name if required

    ## Display user filters
    my $table = $self->new_table([], [], { margin => '1em 0px' });

    $table->add_columns(
        { 'key' => 'type',    'title' => 'Type',    'width' => '20%', 'align' => 'left' },
        { 'key' => 'opts', 'title' => 'Options', 'width' => '40%', 'align' => 'left' },
        { 'key' => 'edit',    'title' => '',        'width' => '20%', 'align' => 'left' },
        { 'key' => 'delete',  'title' => '',        'width' => '20%', 'align' => 'left' },
    );

    foreach my $filter (@filters) {
      my $row = {};
      my @species;
      if (ref($filter->species) eq 'ARRAY') {
        foreach my $sp (@{$filter->species}) {
          push @species, $object->species_defs->get_config($sp, 'SPECIES_COMMON_NAME');
        }
      }
      else {
        @species = ($object->species_defs->get_config($filter->species, 'SPECIES_COMMON_NAME'));
      }
      $row->{'type'} = 'Species';
      $row->{'opts'} = join(', ', sort(@species));

      $row->{'edit'} = $self->edit_link('Newsfilter', $filter->id);
      $row->{'delete'} = $self->delete_link('Newsfilter', $filter->id);
      $table->add_row($row);
      $has_filters = 1;
    }
    $html .= $table->render;
  }


  if (!$has_filters) {
    $html .= qq(<p class="center">You do not have any filters set, so you will see general headlines.</p>
<p><a href="/Account/Newsfilter/Add" class="modal_link">Add a news filter &rarr;</a></p>);
  }

  return $html;
}

1;
