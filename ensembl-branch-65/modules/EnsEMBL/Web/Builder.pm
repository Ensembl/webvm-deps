# $Id: Builder.pm,v 1.20 2011-12-14 09:48:46 sb23 Exp $

package EnsEMBL::Web::Builder;

### DESCRIPTION:
### Builder is a container for domain objects such as Location, Gene, 
### and User plus a single helper module, Hub (see separate documentation).
### Domain objects are stored as a hash of key-arrayref pairs, since 
### theoretically a page can have more than one domain object of a 
### given type.
### E.g.
### $self->{'_objects'} = {
###   'Location'  => [$x],
###   'Gene'      => [$a, $b, $c],
###   'UserData'  => [$bed, $gff],
### };

use strict;

use base qw(EnsEMBL::Web::Root);

sub new {
  my ($class, $args) = @_;
  
  my $self = { 
    objects => {},
    %$args
  };
   
  bless $self, $class;
  
  return $self; 
}

sub hub             { return $_[0]{'hub'};             }
sub all_objects     { return $_[0]{'objects'};         }
sub object_params   { return $_[0]{'object_params'};   }
sub object_types    { return $_[0]{'object_types'};    }
sub ordered_objects { return $_[0]{'ordered_objects'}; }

sub object {
  ### Getter/setter for data objects - acts on the default data type
  ### for this page if none is specified
  ### Returns the first object in the array of the appropriate type
  
  my ($self, $type, $object) = @_;
  my $hub = $self->hub;
  $type ||= $hub->type;
  
  $self->{'objects'}{$type} = $object if $object;
  
  my $object_type = $self->{'objects'}{$type};
  $object_type  ||= $self->{'objects'}{$hub->factorytype} unless $_[1];
  
  return $object_type;
}

sub api_object {
  ### Returns the underlying API object(s)
  
  my ($self, $type) = @_;
  my $object = $self->object($type);
  return $object->__objecttype eq 'Location' ? $object->slice : $object->Obj if $object;
}

sub create_objects {
  ### Used to generate the objects needed for the top tabs and the rest of the page
  ### The object of type $type is the primary object, used for the page.
  
  my ($self, $type, $request) = @_;
  my $hub     = $self->hub;
  my $url     = $hub->url($hub->multi_params);
  my $species = $hub->species;
  $type     ||= $hub->factorytype;
  
  my ($factory, $new_factory, $data);
  
  if ($request eq 'lazy') {
    $factory = $self->create_factory($type) unless $self->object($type);
    return $self->object($type);
  }
  
  if ($self->object_types->{$type} && $hub->param('r')) {
    $factory = $self->create_factory('Location', undef, 'r');
    $data    = $factory->__data if $factory;
  }
  
  $new_factory = $self->create_factory($type, $data) unless $type eq 'Location' && $factory; # If it's a Location page with an r parameter, don't duplicate the Location factory
  $factory     = $new_factory if $new_factory;
  
  foreach (@{$self->object_params}) {
    last if $hub->get_problem_type('redirect');                  # Don't continue if a redirect has been requested
    next if $_->[0] eq $type;                                    # This factory already exists, so skip it
    next unless $hub->param($_->[1]) && !$self->object($_->[0]); # This parameter doesn't exist in the URL, or the object has already been created, so skip it
    next if $_->[0] eq 'Location' && $species eq 'common';       # Skip the Location factory when a hash change (using the location nav slider) has added a r parameter to a link without a species
    
    $new_factory = $self->create_factory($_->[0], $factory ? $factory->__data : undef, $_->[1]) || undef;
    $factory     = $new_factory if $new_factory;
  }
  
  $hub->clear_problem_type('fatal') if $type eq 'MultipleLocation' && $self->object('Location');
  
  if ($request eq 'page') {
    my ($redirect) = $hub->get_problem_type('redirect');
    my ($new_url, $redirect_url);
    
    if ($redirect) {
      $new_url = $redirect_url = $redirect->name;
    } elsif (!$hub->has_fatal_problem) { # If there's a fatal problem, we want to show it, not redirect
      $hub->set_core_params;
      $new_url      = $hub->url($hub->multi_params);
      $redirect_url = $hub->current_url;
    }
    
    if ($new_url && $new_url ne $url) {
      $hub->redirect($redirect_url);
      return 'redirect';
    }
  }
  
  $hub->core_objects($self->all_objects);
}

sub create_factory {
  ### Creates a Factory object which can then generate one or more 
  ### domain objects
  
  my ($self, $type, $data, $param) = @_;
  
  return unless $type;
  
  my $hub = $self->hub;
  
  $data ||= {
    _hub           => $hub,
    _input         => $hub->input,
    _databases     => $hub->databases,
    _referer       => $hub->referer
  };
  
  my $factory = $self->new_factory($type, $data);
  
  if ($factory) {
    $factory->createObjects;
    
    if ($hub->get_problem_type('fatal')) {
      $hub->delete_param($param);
      $hub->clear_problem_type('fatal') if $type ne $hub->type; # If this isn't the critical factory for the page, ignore the problem. Deleting the parameter will cause a redirect to a working URL.
    } else {
      $self->object($_->__objecttype, $_) for @{$factory->DataObjects};
      
      return $factory;
    }
  }
  
  return undef;
}

sub create_data_object_of_type {
  my ($self, $type, $args) = @_;
  
  my $class = "EnsEMBL::Web::Data::$type";
  my $object;
  
  if ($self->dynamic_use($class)) {
    $object = $class->new($self->hub, $args);
    $self->object($object->type, $object) if $object;
  }
}

1;
