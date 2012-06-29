package Website::Utilities::UserGroup;
#########
# Author: rmp
# Maintainer: rmp
# 
# Originally written for the Fishfat Procurement system.
# Hopefully a fairly generic UserGroup module
#
use strict;
use Website::Utilities::User;

sub new {
  my ($class, $defs) = @_;
  my $self = {};
  bless $self, $class;

  for my $f ('util', $self->fields(), qw(mode)) {
    $self->{$f} = $defs->{$f} if(exists($defs->{$f}));
  }
  return $self;
}

sub fields {
  return qw(groupname description);
}

sub util {
  my $self = shift;
  die qq(No utility object available) unless($self->{'util'});
  return $self->{'util'};
}

sub groupname {
  my ($self, $groupname) = @_;
  $self->{'groupname'}   = $groupname if(defined $groupname);
  return $self->{'groupname'};
}

sub mode {
  my ($self, $mode) = @_;
  $self->{'mode'}   = $mode if(defined $mode);
  return $self->{'mode'};
}

sub description {
  my ($self, $description) = @_;
  $self->{'description'}   = $description if(defined $description);

  if(!defined $self->{'description'}) {
    my $sgroup = $self->util->dbh->quote($self->groupname());
    my $sth    = $self->util->dbh->prepare(qq(SELECT description
					      FROM   usergroup
					      WHERE  groupname=$sgroup));
 
    $sth->execute();
    ($self->{'description'}) = $sth->fetchrow_array();
    $sth->finish();
  }

  return $self->{'description'};
}

sub all_groups {
  my $self   = shift;
  $self      = $self->new() unless(ref($self));
  my @groups = ();
  my $sth    = $self->util->dbh->prepare(qq(SELECT groupname,description
					    FROM   usergroup
					    ORDER BY groupname));
  $sth->execute();
  while(my $ref = $sth->fetchrow_hashref()) {
    $ref->{'util'} = $self->util();
    push @groups, ref($self)->new($ref);
  }
  return @groups;
}

sub update {
  my $self  = shift;
  my $sname = $self->util->dbh->quote($self->groupname());

  eval {
    for my $f ($self->fields()) {
      my $v = $self->$f;
      next if(!defined $v || $v eq ""); 
      my $sv = $self->util->dbh->quote($v);
      $sv    = qq(PASSWORD($sv)) if($f eq "password");
      $self->util->dbh->do(qq(UPDATE usergroup
			      SET    $f=$sv
			      WHERE  groupname=$sname));
    }
  };
  warn $@ if($@);
}

sub add {
  my $self   = shift;
  my $sgroup = $self->util->dbh->quote($self->groupname());
  my $sdesc  = $self->util->dbh->quote($self->description());
  eval {
    $self->util->dbh->do(qq(INSERT INTO usergroup (groupname,description)
			    VALUES($sgroup,$sdesc)));
  };
  warn $@ if($@);
}

sub delete {
  my $self   = shift;
  my $sgroup = $self->util->dbh->quote($self->groupname());
  eval {
    $self->util->dbh->do(qq(DELETE FROM usergroup
			    WHERE groupname=$sgroup));
    $self->util->dbh->do(qq(DELETE FROM project_usergroup
			    WHERE groupname=$sgroup));
    $self->util->dbh->do(qq(DELETE FROM user_usergroup
			    WHERE groupname=$sgroup));

  };
  warn $@ if($@);
}

sub update_members {
  my ($self, $username_ref) = @_;
  my $sgroup = $self->util->dbh->quote($self->groupname());

  eval {
    $self->util->dbh->do(qq(DELETE FROM user_usergroup
			    WHERE groupname=$sgroup));
  };
  warn $@ if($@);

  for my $username (@{$username_ref}) {
    my $sname  = $self->util->dbh->quote($username);
    eval {
      $self->util->dbh->do(qq(INSERT IGNORE INTO user_usergroup (username,groupname)
			      VALUES ($sname,$sgroup)));
    };
    warn $@ if($@);
  }
}

sub members {
  my ($self, $userclass) = @_;
  $userclass ||= "Website::Utilities::User";
  my $sgroup   = $self->util->dbh->quote($self->groupname());
  my @users    = ();
  eval {
    my $sth = $self->util->dbh->prepare(qq(SELECT username
					   FROM   user_usergroup
					   WHERE  groupname=$sgroup
					   ORDER BY username));
    $sth->execute();
    while(my ($un) = $sth->fetchrow_array()) {
      push @users, $userclass->new({
	  'util'     => $self->util(),
	  'username' => $un,
      });
    }
    $sth->finish();
  };
  warn $@ if($@);
  return @users;
}

1;
