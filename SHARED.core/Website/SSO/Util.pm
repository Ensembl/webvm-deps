#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2004-10-28
# Last Modified: $Date: 2012-08-31 09:19:08 $ $Author: mw6 $
# Id:            $Id: Util.pm,v 1.14 2012-08-31 09:19:08 mw6 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/SSO/Util.pm,v $
# $HeadURL$
#
package Website::SSO::Util;
use strict;
use warnings;
use base qw(Exporter);
use DBI;
use Website::Utilities::IdGenerator;
use Website::SSO::User;
use Sys::Hostname;
use Time::Local;
use English qw(-no_match_vars);
use Carp;
use Crypt::CBC;
use MIME::Base64;
use CGI;

our $AUTH_EXPIRY          = '+2d';
our $VERSION              = do { my @r = (q$Revision: 1.14 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $DEFAULT_AUTHTYPE_EXT = 1;
our $SESSION_CRYPT_KEY    = q[R7iu1NK+5o/CSiw7/oB9BIDD9UvPD/21Zw+Yu6oJMIZK/KdEn7aW2ReP];
our @EXPORT_OK            = qw($DEFAULT_AUTHTYPE_EXT);

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  return $self;
}

sub crypter {
  return Crypt::CBC->new(-key    => $SESSION_CRYPT_KEY,
                         -literal_key => 1,
                         -cipher => 'Blowfish',
                         -header => 'randomiv',
                         -padding => 'space',
                        );
}

sub encode_token {
  my ($self, $token) = @_;
  my $encrypted = $self->crypter->encrypt("<<<<$token");
  my $encoded   = encode_base64($encrypted,q{});
  my $escaped   = CGI->escape($encoded);
  return $escaped;
}

sub decode_token {
  my ($self, $cookie) = @_;
  if(!$cookie) {
    return;
  }

  my $unescaped = CGI->unescape($cookie);
  if(!$unescaped) {
    return;
  }

  #########
  # CGI double-unescapes '%2B' => '+' => ' ' so we have to revert the last step
  #
  $unescaped =~ s/\ /+/mxg;

  my $decoded = decode_base64($unescaped);
  if(!$decoded) {
    return;
  }

  my $decrypted = $self->crypter->decrypt($decoded);
  return (split(/<<<</, $decrypted ,2))[1];
}

sub dbh {
  my $self = shift;
  my $n = (eval (eval $self->decode_token('UmFuZG9tSVZSUMfq/Got5YFYyVe3bQKuQPOgZC1eT9I60PzRS/KXsWrc+En6YuDfXWUj0bezTHY=')))<<3;

  if(!$self->{dbh} &&
     !$self->{_failed}) {
    $SIG{ALRM} = sub { croak 'timeout'; };
    alarm 5;
    eval {
      $self->{dbh} = DBI->connect('DBI:mysql:database=sso;web-wwwdb-02;port=3358', 'ssorw', 'supersecret' . $n , {RaiseError => 1});
    };
    alarm 0;

    if($EVAL_ERROR) {
      carp qq(Website::SSO::Util::dbh: Error connecting to SSO database: $! / $EVAL_ERROR\n);
      $self->{_failed} = 1;
    }
  }

  return $self->{dbh};
}

sub quote {
  my ($self, $str) = @_;
  return $self->dbh->quote($str);
}

sub DESTROY {
  my $self = shift;
  if(defined $self->{dbh}) {
    $self->{dbh}->disconnect();
  }
  return;
}

sub AUTH_EXPIRY {
  return $AUTH_EXPIRY;
}

sub now {
  my ($self, $additions) = @_;

  my @gmtime = gmtime;
  if(defined $additions) {
    my $timegm = timegm @gmtime;
    $timegm   += ($additions->{'sec'}  || 0);
    $timegm   += ($additions->{'min'}  || 0)*60;
    $timegm   += ($additions->{'hour'} || 0)*60*60;
    $timegm   += ($additions->{'day'}  || 0)*24*60*60;
    $timegm   += ($additions->{'week'} || 0)*7*24*60*60;
    @gmtime    = gmtime $timegm;
  }

  my ($sec, $min, $hour, $day, $month, $year) = @gmtime;
  $year   += 1900;
  $month  += 1;
  return sprintf q(%4d-%02d-%02d %02d:%02d:%02d), $year, $month, $day, $hour, $min, $sec;
}

sub get_unique_id {
  my $self = shift;
  $self->{idgen} ||= Website::Utilities::IdGenerator->new();
  return $self->{idgen}->get_unique_id(@_);
}

sub all_authtypes {
  my $self = shift;

  if(!$self->{'authtypes'}) {
    my $ref = $self->dbh->selectall_arrayref(q(SELECT id,type,note
                                               FROM   authtype));
    for my $r (@{$ref}) {
      $self->{'authtypes'}->{$r->[0]} = {
					 id   => $r->[0],
					 type => $r->[1],
					 note => $r->[2],
					};
    }
  }
  return $self->{'authtypes'};
}

sub authtype_description {
  my ($self, $id) = @_;
  if(!$id) {
    return {};
  }
  return $self->all_authtypes->{$id} || {};
}

sub user_by_reset_token {
  my ($self, $token) = @_;
  my $username;
  eval {
    my $ref = $self->dbh->selectall_arrayref(q(SELECT username FROM reset WHERE token = ?), {}, $token);

    $username = $ref->[0]->[0];
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return;
  }
  return Website::SSO::User->new({
				  'username' => $username,
				  'util'     => $self,
				 });
}

sub delete_reset_token {
  my ($self, $token) = @_;
  my $username;
  eval {
    my $ref = $self->dbh->do(q(DELETE FROM reset WHERE token = ?), {}, $token);
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return;
  }
  return 1;
}

sub user_by_unverified_token {
  my ($self, $token) = @_;
  my $username;
  eval {
    my $ref   = $self->dbh->selectall_arrayref(q(SELECT username FROM unverified WHERE token = ?), {}, $token);
    $username = $ref->[0]->[0];
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return;
  }
  return Website::SSO::User->new({
				  'username' => $username,
				  'util'     => $self,
				 });
}

1;

__END__

=head1 NAME

Website::SSO::Util -SSO database handle and helper functions

=head1 VERSION

$Revision: 1.14 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new : Constructor


=head2 dbh : SSO database handle

  my $oDBH = $oUtil->dbh();

=head2 quote : Shortcut for dbh->quote($sString)

  my $sQuoted = $oUtil->quote($sUnQuoted);

=head2 DESTROY : Destructor

=head2 AUTH_EXPIRY : cookie expiry time limit

=head2 now : ISO-format timestamp for now or now plus a given delta

  my $sDateTime = $oUtil->now();

  my $sDateTime = $oUtil->now({
                               'sec'  => $iSecs,  # Seconds to add
                               'min'  => $iMins,  # Minutes to add
                               'hour' => $iHours, # Hours to add
                               'day'  => $iDays,  # Days to add
                               'week' => $iWeeks, # Weeks
                              });

=head2 get_unique_id : Call-out to Website::Utilities::IdGenerator->get_unique_id

  my $sUniqueId = $oUtil->get_unique_id();

=head2 all_authtypes : Hashref of authtypes by id

  my $hrAllAuthTypes = $oUtil->all_authtypes();

 # $hrAllAuthTypes = {
 #                    1 => {
 #                          'id'   => $iId,
 #                          'type' => $sType,
 #                          'note' => $sNote,
 #                         },
 #                   }

=head2 authtype_description : Details for a given authtype id

  my $hrDescription = $oUtil->authtype_description();

=head2 user_by_reset_token

  my $oUser = $oUtil->user_by_reset_token($sToken);

  Fetch a Website::SSO::User object given a previously generated reset token.
  Returns undef if an invalid token was given.

=head2 user_bu_unverified_token

  my $oUser = $oUtil->user_by_unverified_token($sToken);

  Fetch a Website::SSO::User object given a previously generated verification token.
  Returns undef if an invalid token was given.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE AND COPYRIGHT

=cut
