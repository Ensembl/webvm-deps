#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2005-09-26
# Last Modified: $Date: 2007/04/13 09:59:49 $ $Author: rmp $
# Id:            $Id: UserConfig.pm,v 1.2 2007/04/13 09:59:49 rmp Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/SSO/UserConfig.pm,v $
# $HeadURL$
#
# per-user configuration for website services incl. at least portlets
#
package Website::SSO::UserConfig;
use strict;
use warnings;
use Website::SSO::Util;
use Storable qw(nfreeze thaw);
use Carp;

our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $DEBUG   = 0;

sub new {
  my ($class, $self) = @_;
  $self ||= {};
  if(!$self->{'username'}) {
    carp qq($class: No username given);
  }
  bless $self, $class;
  return $self;
}

sub util {
  my $self          = shift;
  $self->{'util'} ||= Website::SSO::Util->new();
  return $self->{'util'};
}

sub get {
  my ($self, $id) = @_;
  $self->{'username'} or return;

  my $ref = $self->util->dbh->selectall_arrayref(q(SELECT data
                                                   FROM   userconfig
                                                   WHERE  username=?),
						 {},
						 $self->{'username'});
  if(!$ref->[0] || !$ref->[0]->[0]) {
    $DEBUG and carp q(No data returned from db);
    return;
  }

  my $blob = thaw($ref->[0]->[0]);
  if(!(ref $blob) || (ref $blob ne 'HASH')) {
    $DEBUG and carp q(Data is missing or corrupted);
    return;
  }

  if($id) {
    $DEBUG and carp qq(Returning @{[length ($blob->{$id}||q())]} bytes for $id);
    return $blob->{$id};
  }

  $DEBUG and carp qq(Returning all data in $blob);
  return $blob;
}

sub set {
  my ($self, $id, $value) = @_;
  $self->{'username'} or return;
  my $blob = {};

  if(scalar @_ == 2) {
    #########
    # saving everything
    #
    $blob = $id;

  } else {
    #########
    # saving an individual entry (from a loaded structure)
    #
    $DEBUG and carp qq(Saving for $id);
    $blob        = $self->get() || {};
    $blob->{$id} = $value;
  }

  my $frozen = nfreeze($blob);
  $DEBUG and carp qq(Saving @{[length $frozen]} bytes);
  $self->util->dbh->do(q(REPLACE INTO userconfig(username,data,lastmodified)
                         VALUES(?, ?, now())), {}, $self->{'username'}, $frozen);
  return 1;
}

1;

__END__

=head1 NAME

Website::SSO::UserConfig - Personal preferences for users logged in via the SSO [stored server-side].

=head1 VERSION

$Revision: 1.2 $

=head1 DESCRIPTION

=head1 SYNOPSIS

  my $oUserConfig = Website::SSO::UserConfig->new({'username' => 'xyz'});

  $oUserConfig->set($sPreferenceKey, $sBlob);

  my $sBlob = $oUserConfig->get($sPreferenceKey);


=head1 SUBROUTINES/METHODS

=head2 new : Constructor

  my $oUserConfig = Website::SSO::UserConfig->new({
                                                   'username' => $sUsername,
                                                   'util'     => $oUtil,     # optional
                                                  });

=head2 util : SSO database handle / utility object

  my $oSSOUtil = $oUserConfig->util();

=head2 get : Fetch configuration data for an optional key from the database

  my $sBlobForId = $oUserConfig->get($sId);
  my $sBlobAll   = $oUserConfig->get();

=head2 set : Store configuration data for a key in the database

  $oUserConfig->set($sId, $sBlobForId) or die "Failed to store preferences for $sId";
  $oUserConfig->set($sBlobAll) or die "Failed to store all preferences";

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE AND COPYRIGHT

=cut
