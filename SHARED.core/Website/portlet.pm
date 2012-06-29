#########
# Author: rmp
#
package Website::portlet;
use strict;
use warnings;

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};
  bless $ref, $class;
  return $ref;
}

sub fields { qw(cgi username userconfig); };

sub prologue {
  '';
}

sub run {
  my $self = shift;
  return $self->is_authorised()?$self->authorised_run():'';
}

sub authorised_users { []; }

sub requires_authorisation { 0; }

sub is_authorised {
  my $self = shift;
  #########
  # we're authorised if this portlet doesn't require authorisation
  #
  return 1 unless($self->requires_authorisation());

  #########
  # we're authorised if logged-in via the SSO and the user is in our list
  #
  return 1 if($self->{'username'} && grep { $_ eq $self->{'username'} } @{$self->authorised_users()});

  #########
  # otherwise we're not authorised to see this portlet
  #
  return 0;
}

sub authorised_run { ''; }

1;
