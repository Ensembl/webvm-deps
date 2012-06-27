# $Id: AnnotationList.pm,v 1.7 2011-01-05 16:10:21 sb23 Exp $

package EnsEMBL::Web::Component::Account::Interface::AnnotationList;

### Module to create user gene annotation list

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
  my $html;

  my $user = $object->user;
  my $sitename = $self->site_name;

  ## Control panel fixes
  my $dir = $object->species_path;
  $dir = '' if $dir !~ /_/;

  my @notes = $user->annotations;
  my $has_notes = 0;

  my @groups = $user->find_administratable_groups;
  my $has_groups = $#groups > -1 ? 1 : 0;
  my $no_species = 0;

  if ($#notes > -1) {

    $html .= qq(<h3>Your annotations</h3>);
    ## Sort user notes by name if required

    ## Display user notes
    my $table = $self->new_table([], [], { margin => '0px' });

    $table->add_columns(
        { 'key' => 'type',  'title' => 'Type',      'width' => '10%', 'align' => 'left' },
        { 'key' => 'id',    'title' => 'Stable ID', 'width' => '20%', 'align' => 'left' },
        { 'key' => 'title', 'title' => 'Title',     'width' => '40%', 'align' => 'left' },
        { 'key' => 'edit',  'title' => '',          'width' => '10%', 'align' => 'left' },
    );
    if ($has_groups) {
      $table->add_columns(
        { 'key' => 'share', 'title' => '',  'width' => '10%', 'align' => 'left' },
      );
    }
    $table->add_columns(
        { 'key' => 'delete', 'title' => '', 'width' => '10%', 'align' => 'left' },
    );

    foreach my $note (@notes) {
      my $row = {};
      my $type = $note->ftype || 'Gene';
      $row->{'type'} = $type;

      if ($note->species) {
        $row->{'id'} = sprintf(qq(<a href="/%s/Gene/UserAnnotation?g=%s">%s</a>),
                        $note->species, $note->stable_id, $note->stable_id);
      }
      else {
        $no_species = 1;
        $row->{'id'} = $note->stable_id;
      }

      $row->{'title'}   = $note->title;
      $row->{'edit'}    = $self->edit_link('Annotation', $note->id);
      if ($has_groups) {
        $row->{'share'}   = $self->share_link('annotation', $note->id);
      }
      $row->{'delete'}  = $self->delete_link('Annotation', $note->id);
      $table->add_row($row);
      $has_notes = 1;
    }
    $html .= $table->render;
  }

 ## Get all note records for this user's subscribed groups
  my %group_notes = ();
  foreach my $group ($user->groups) {
    foreach my $note ($group->annotations) {
      next if $note->created_by == $user->id;
      if ($group_notes{$note->id}) {
        push @{$group_notes{$note->id}{'groups'}}, $group;
      }
      else {
        $group_notes{$note->id}{'note'} = $note;
        $group_notes{$note->id}{'groups'} = [$group];
        $has_notes = 1;
      }
    }
  }

  if (scalar values %group_notes > 0) {
    $html .= qq(<h3>Group notes</h3>);
    ## Sort group notes by name if required

    ## Display group notes
    my $table = $self->new_table([], [], { margin => '0px' });

    $table->add_columns(
        { 'key' => 'name',  'title' => 'Name',     'width' => '20%', 'align' => 'left' },
        { 'key' => 'title', 'title' => 'Title',    'width' => '40%', 'align' => 'left' },
        { 'key' => 'group', 'title' => 'Group(s)', 'width' => '40%', 'align' => 'left' },
    );

    foreach my $note_id (keys %group_notes) {
      my $row = {};
      my $note = $group_notes{$note_id}{'note'};

      $row->{'name'} = sprintf(qq(<a href="/Gene/Summary?g=%s" class="cp-external">%s</a>),
                        $note->stable_id, $note->stable_id);

      $row->{'title'} = $note->title || '&nbsp;';

      my @group_links;
      foreach my $group (@{$group_notes{$note_id}{'groups'}}) {
        push @group_links, sprintf qq(<a href="%s/Account/MemberGroups?id=%s" class="modal_link">%s</a>), $dir, $group->id, $group->name;
      }
      $row->{'group'} = join(', ', @group_links);
      $table->add_row($row);
    }
    $html .= $table->render;
  }

  if (!$has_notes) {
    $html .= sprintf '<p class="center"><img src="%s/img/help/note_example.gif" alt="Sample screenshot" title="SAMPLE" /></p>', $self->static_server;
  }

  if ($no_species) {
    $html .= '<br />'.$self->_info('Old Annotations', 'Some of your annotations were saved before we changed our web code in 2008, so we cannot linked directly to the gene from here. You can still edit the annotation and see it displayed on the corresponding gene page.', '100%');
  }

  return $html;
}

1;
