package Website::Utilities::User;
#########
# Author:     rmp
# Maintainer: rmp
# Id:         $Id: User.pm,v 1.2 2007/03/01 09:22:12 rmp Exp $
# Source:     $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/Utilities/User.pm,v $
# $HeadURL$
#
# Originally written for the Fishfat Procurement system.
# Hopefully a fairly generic User module
#
use strict;
use warnings;
use Website::Utilities::BasicUser;
use Website::SSO::User;
use Website::SSO::Util;
use base qw(Exporter Website::Utilities::BasicUser);
use English qw(-no_match_vars);
use Carp;

our $VERSION        = do { my @r = (q$Revision: 1.2 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our @EXPORT         = qw(@ACCESS_TYPES $ACCESS_DEFAULT);
our @ACCESS_TYPES   = qw(ADMIN NORMAL);
our $ACCESS_DEFAULT = 'NORMAL';
our $DEBUG          = 0;

sub fields {
  my $self = shift;
  return $self->SUPER::fields(), qw(accesslevel);
}

sub accesslevel {
  my ($self, $accesslevel) = @_;

  if(defined $accesslevel) {
    $self->{'accesslevel'} = $accesslevel;
  }

  if(!defined $self->{'accesslevel'}) {
    #########
    # load system accesslevel from database
    #
    my $sth   = $self->util->dbh->prepare(q(SELECT accesslevel
                                            FROM   user
                                            WHERE  username=?));
    $sth->execute($self->{'username'});
    ($self->{'accesslevel'}) = $sth->fetchrow_array();
    $sth->finish();
  }

  if(!defined $self->{'accesslevel'}) {
    $self->{'accesslevel'} = $ACCESS_DEFAULT;
  }
  return $self->{'accesslevel'};
}

sub update {
  my $self = shift;
  eval {
    $self->util->dbh->do(qq(REPLACE INTO user (@{[join(',', $self->fields())]})
                            VALUES(@{[
                                      join(',', map {
                                        $self->util->dbh->quote($self->$_());
                                      } $self->fields)]})));
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return;
  }
  return 1;
}

sub add {
  my $self = shift;
  return $self->update(@_);
}

sub delete {
  my $self = shift;

  #########
  # remove user entry
  #
  eval {
    $self->util->dbh->do(q(DELETE FROM user
                           WHERE username=?), {}, $self->username());
  };

  $EVAL_ERROR and carp $EVAL_ERROR;

  #########
  # remove group associations
  #
  eval {
    $self->util->dbh->do(q(DELETE FROM user_usergroup
                           WHERE username=?), {}, $self->username());
  };
  $EVAL_ERROR and carp $EVAL_ERROR;
  return;
}

sub update_usergroups {
  my ($self, $group_ref) = @_;
  my @groupnames = ();

  if($group_ref) {
    @groupnames = @{$group_ref};

  } else {
    @groupnames = map { $_->groupname() } $self->usergroups();
  }

  eval {
    #########
    # easiest to delete all associated groups and re-add
    #
    $self->util->dbh->do(q(DELETE FROM user_usergroup
                           WHERE username=?), {}, $self->username());

    for my $groupname (@groupnames) {
      $self->util->dbh->do(q(INSERT IGNORE INTO user_usergroup (username,groupname)
                             VALUES(?,?)), {}, $self->username(), $groupname);
    }
  };

  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return;
  }
  return 1;
}

sub usergroups {
  my $self   = shift;
  my @groups = ();
  eval {
    my $sth  = $self->util->dbh->prepare(q(SELECT groupname
                                           FROM   user_usergroup
                                           WHERE  username=?
                                           ORDER BY groupname));
    $sth->execute($self->username());
    while(my ($gn) = $sth->fetchrow_array()) {
      push @groups, Website::Utilities::UserGroup->new({
							'util'      => $self->util(),
							'groupname' => $gn,
						       });
    }
    $sth->finish();
  };

  $EVAL_ERROR and carp $EVAL_ERROR;
  return @groups;
}

sub log {
  my $self   = shift;
  my $uname  = $self->username()   || q();
  my $uri    = $ENV{'REQUEST_URI'} || q();
  my $addr   = $self->ipaddr()     || $ENV{'HTTP_X_FORWARDED_FOR'} || $ENV{'REMOTE_ADDR'} || q();
  $SIG{ALRM} = sub { croak 'timeout'; };
  alarm 5;
  eval {
    $self->util->dbh->do(q(INSERT IGNORE INTO log (username,date,uri,ipaddr)
                           VALUES (?, now(), ?, ?)), {}, $self->username(), $uri, $addr);
  };
  alarm 0;
  $EVAL_ERROR and carp $EVAL_ERROR;
  return;
}

sub sso {
  my $self  = shift;
  my $uname = $self->username();

  if($uname) {
    $self->{'ssoutil'} ||= Website::SSO::Util->new();
    my $sso = Website::SSO::User->new({
                                       'username' => $uname,
                                       'util'     => $self->{'ssoutil'}||undef,
				      });
    #########
    # we'll hang on to the single-sign-on dbh for next time, thanks...
    #
    #$self->{'ssoutil'} ||= $sso->util();
    return $sso;
  }
  return;
}

sub realname {
  my $self = shift;
  return $self->sso()?$self->sso->realname():q();
}

sub all_users {
  my $self  = shift;
  #########
  # Make sure we have a util to replicate around, *before* we create a heouge list of users
  #
  $self->{'ssoutil'} ||= Website::SSO::Util->new();
  my $sso   = Website::SSO::User->new({
				       'util' => $self->{'ssoutil'}||undef,
				      });
  my @users = map {
    $_->{'ssoutil'} = $self->{'ssoutil'};
    $_;
  } $sso->all_users('Website::Utilities::User');

  return @users;
}

1;
