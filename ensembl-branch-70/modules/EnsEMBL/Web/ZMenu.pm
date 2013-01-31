# $Id: ZMenu.pm,v 1.16 2012-10-25 11:07:56 sb23 Exp $

package EnsEMBL::Web::ZMenu;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Root);

sub new {
  my ($class, $hub, $object) = @_;
  
  my $self = {
    hub            => $hub,
    object         => $object,
    entries        => [],
    stored_entries => {},
    order          => 1,
    caption        => ''
  };
  
  bless $self, $class;
  
  $self->content;
  
  # stored_entries keeps all entries of all plugins in a hash, keyed by order
  $self->{'stored_entries'}->{$_->{'order'}} = $_ for @{$self->{'entries'}};
  
  return $self;
}

sub content {}

sub hub { return $_[0]{'hub'}; }

sub object {
  my $self = shift;
  $self->{'object'} = shift if @_;
  return $self->{'object'};
}

sub caption {
  my $self = shift;
  $self->{'caption'} = shift if @_;
  return $self->{'caption'};
}

# When adding an entry you can specify ORDER or POSITION.
# ORDER    is used to set the position of all entries. It is auto generated unless specified,
#          and as such should be set explicitly on ALL entries, or NONE. Any other scenario
#          could result in unexpected behaviour. For these cases use POSITION instead.
# POSITION will insert the entry at that position in the menu. Since it increments all subsequent
#          entries' orders, it should only be used to insert at existing positions.
# It is probably best not to use POSITION and ORDER together, just in case something goes wrong.
sub add_entry {
  my ($self, $entry) = @_;
  
  if ($entry->{'position'}) {
    $_->{'order'}++ for grep $_->{'order'} >= $entry->{'position'}, @{$self->{'entries'}}; # increment order for each entry after the given position
    $entry->{'order'} = $entry->{'position'};
    $self->{'order'}++;
  } else {
    $entry->{'order'} ||= $self->{'order'}++;
  }
  
  push @{$self->{'entries'}}, $entry;
}

sub add_subheader {
  my ($self, $label) = @_;
  
  return unless defined $label;
  
  $self->add_entry({
    type       => 'subheader',
    label_html => $label
  });
}

# Can be used from plugins to remove entries from previous plugins' menu.
# Requires a list of entry positions to remove
sub remove_entries {
  my $self = shift;
  delete $self->{'stored_entries'}->{$_} for @_;
}

# Generic code to grab hold of an existing entry and modify it
sub modify_entry_by {
  my ($self, $type, $entry) = @_;
  for my $i (0..$#{$self->{'entries'}}) {
    if ($self->{'entries'}[$i]{$type} eq $entry->{$type}) {
      $self->{'entries'}[$i]{$_} = $entry->{$_} for keys %$entry;
      last;
    }
  }
}

sub modify_entry_by_type {
  my ($self, $entry) = @_;
  warn "DEPRECATED, use modify_entry_by";
  $self->modify_entry_by($entry->{'type'},$entry);
}

# Delete an entry by its value
sub delete_entry_by_value {
  my ($self, $value) = @_;

  for my $i (0..$#{$self->{'entries'}}) {
    foreach my $key (keys %{$self->{'entries'}[$i]}) {
      if ($self->{'entries'}[$i]{$key} eq $value) {
        $self->{'entries'}[$i] = undef;
        last;
      }
    }
  }
}

# Delete an entry by type
sub delete_entry_by_type {
  my ($self, $type) = @_;
  my $i;
  
  for my $i (0..$#{$self->{'entries'}}) {
    foreach my $key (keys %{$self->{'entries'}[$i]}) {
      if ($self->{'entries'}[$i]{'type'} eq $type) {
        $self->{'entries'}[$i] = undef;
        last;
      }
    }
  }
}

# Build and print the JSON response
sub render {
  my $self = shift;
  
  my @entries;
  
  foreach (sort { $a <=> $b } keys %{$self->{'stored_entries'}}) {
    my $entry = $self->{'stored_entries'}->{$_};
    my $type  = encode_entities($entry->{'type'});
    my $link;
    
    if ($entry->{'link'}) {
      if ($entry->{'extra'}{'abs_url'}) {
        $link = $entry->{'link'};
      } else {
        $link = sprintf(
          '<a href="%s"%s %s>%s%s</a>',
          encode_entities($entry->{'link'}),
          $entry->{'extra'}{'external'} ? ' rel="external"' : '',
          $entry->{'class'} ? qq{ class="$entry->{'class'}"} : '',
          encode_entities($entry->{'label'} . $entry->{'label_html'}),
          $entry->{'extra'}{'update_params'},
        );
      }
    } else {
      $link = encode_entities($entry->{'label'}) . $entry->{'label_html'};
    }


    #quick bug fix:
    $link =~ s/(\?|;)ac=(.+?)"(.*?)>InterPro</$1ac=$2"$3>$2</g if ($type =~ /View InterPro/);
    $link =~ s/&amp;amp;/&amp;/g if ($link =~ /&amp;amp;/);
    push @entries, { link => $link, type => $type };
  }
  
  print $self->jsonify({
    caption => encode_entities($self->{'caption'}),
    entries => \@entries
  });
}

1;
