package Website::SSO::User;
#########
# Author:        rmp
# Maintainer:    $Author: mw6 $
# Last Modified: $Date: 2012-08-30 10:19:45 $
# Id:            $Id: User.pm,v 1.22 2012-08-30 10:19:45 mw6 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/SSO/User.pm,v $
#
use strict;
use warnings;
use Website::SSO::Util;
use Website::SSO::UserConfig;
use Website::Utilities::IdGenerator;
#use Website::Utilities::Mail;
use base qw(Website::Utilities::BasicUser Exporter);
use English qw(-no_match_vars);
use Carp;
use URI::Escape;

our $VERSION             = do { my @r = (q$Revision: 1.22 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our @EXPORT_OK           = qw($AUTH_OK $AUTH_FAIL $AUTH_SHADOW $AUTH_EXPIRED $AUTH_SERVERERR $AUTH_LOCKED);
our $AUTH_OK             = 1;
our $AUTH_FAIL           = 2;
our $AUTH_SHADOW         = 3;
our $AUTH_EXPIRED        = 4;
our $AUTH_SERVERERR      = 5;
our $AUTH_LOCKED         = 6;
our $DEBUG               = 0;
our $DEFAULT_AUTHTYPE    = 'LDAP';
our $LOCK_AFTER_FAILURES = 3;
our $LOCK_DURATION       = 1; # in hours
our $FROM                = q(WTSI Single Sign On <webmaster@sanger.ac.uk>);
our $SALT_LENGTH         = 16; # 16 random octets
our $MAX_PASSWORD        = 32; # (stored password occupies 16 + '/' + 32 characters)
our $MAX_PASSWORD_512    = $SALT_LENGTH + 128 + 1;
our $SOURCE              = (join '','A'..'Z','a'..'z','0'..'9',q( !"#$%&'()*+,-.:;<=>?@)); # avoid '/'

sub new {
  my ($class, $defs) = @_;
  my $self = {};
  bless $self, $class;

  $self->{'pw_encrypted'} = ($defs->{'password'})?'no':'yes';

  for my $f ('util', $self->fields()) {
    if(defined $defs->{$f}) {
      $self->{$f} = $defs->{$f};
    }
  }

  return $self;
}

sub fields {
  my $self = shift;
  return Website::Utilities::BasicUser->fields(), qw(ipaddr sessexpiry realname authtype password sesskey created modified addedby note email);
}

sub util {
  my $self = shift;
  $self->{'util'} ||= Website::SSO::Util->new();
  return $self->{'util'};
}

sub userconfig {
  my $self = shift;
  return Website::SSO::UserConfig->new({
					'util'     => $self->util(),
					'username' => $self->username(),
				       });
}

sub quickload {
  my $self   = shift;

  if($self->{'quickloaded'} || !$self->username()) {
    return;
  }

  my @fields = qw(addedby note created modified password realname email);
  my $ref    = $self->util->dbh->selectall_arrayref(qq(SELECT @{[join(',', @fields)]}
                                                       FROM   user
                                                       WHERE  username = ?),
						    {},
						    $self->username());
  my @args   = @{$ref->[0]||[]};

  if(!$self->{'password'}) {
    # going to load it from the database, so it'll be encrypted
    $self->{'pw_encrypted'} = 'yes';
  }

  for my $f (@fields) {
    my $v = shift @args;
    $self->{$f} ||= $v;
  }
  $self->{'quickloaded'} = 1;

  return;
}

sub addedby {
  my ($self, $addedby) = @_;
  if(defined $addedby) {
    $self->{'addedby'} = $addedby;
  }
  $self->quickload();
  return $self->{'addedby'};
}

sub note {
  my ($self, $note) = @_;
  if(defined $note) {
    $self->{'note'} = $note;
  }
  $self->quickload();
  return $self->{'note'};
}

sub created {
  my ($self, $created) = @_;
  if(defined $created) {
    $self->{'created'} = $created;
  }
  $self->quickload();
  return $self->{'created'};
}

sub email {
  my ($self, $email) = @_;
  if(defined $email) {
    $self->{'email'} = $email;
  }
  $self->quickload();
  return $self->{'email'};
}

sub realname {
  my ($self, $realname) = @_;
  if(defined $realname) {
    $self->{'realname'} = $realname;
  }
  $self->quickload();
  return $self->{'realname'} || $self->realname_LDAP() || $self->{'username'};
}

sub modified {
  my ($self, $modified) = @_;
  if(defined $modified) {
    $self->{'modified'} = $modified;
  }
  return $self->{'modified'};
}

sub password {
  my ($self, $password) = @_;
  if(defined $password) {
    $self->log_error(qq(password: Setting password [@{[length($password)]}\n));
    $self->{'password'}     = $password;
    $self->{'pw_encrypted'} = 'no';
  }
  $self->quickload();
  return $self->{'password'};
}

sub pw_encrypted {
  my $self = shift;
  return $self->{'pw_encrypted'};
}

sub authtype {
  my ($self, $authtype) = @_;
  if(defined $authtype) {
    $self->{'authtype'} = $authtype;

  } elsif(!defined $self->{'authtype'} && defined $self->{'username'}) {
    #########
    # load authentication method from database
    #
    my $sth = $self->util->dbh->prepare(q(SELECT authtype
                                          FROM   user
                                          WHERE  username=?));
    $sth->execute($self->{'username'});
    ($self->{'authtype'}) = $sth->fetchrow_array();
    $sth->finish();
  }

  return $self->{'authtype'};
}

sub ipaddr {
  my ($self, $ipaddr) = @_;

  if(defined $ipaddr) {
    $self->{'ipaddr'} = $ipaddr;
    eval {
      $self->util->dbh->do(q(UPDATE user
                             SET    ipaddr   = ?
                             WHERE  username = ?), {}, $ipaddr, $self->{'username'});
    };
    carp $EVAL_ERROR if($EVAL_ERROR);

  } else {
    eval {
      my $sth = $self->util->dbh->prepare(q(SELECT ipaddr
                                            FROM   user
                                            WHERE  username = ?));
      $sth->execute($self->{'username'});
      ($self->{'ipaddr'}) = $sth->fetchrow_array();
      $sth->finish();
    };
    carp $EVAL_ERROR if($EVAL_ERROR);
  }
  return $self->{'ipaddr'};
}

sub authenticate {
  my ($self) = @_;

#  $self->log();
  if($self->password() && $self->{'pw_encrypted'} ne 'yes') {
    #########
    # password authentication
    #
    my $authtype = $self->authtype_description() || $DEFAULT_AUTHTYPE;
    my $method   = "authenticate_$authtype";

    if($self->is_locked()) {
      return $AUTH_LOCKED;
    }

    if($authtype && $self->can($method)) {
      my $status = $self->$method();

      if($status == $AUTH_OK) {
	$self->log_error(q(authenticate: AUTH_OK. Going to assign a new key));
	$self->sesskey(1);
	$self->unlock();

      } else {
	$self->log_error(qq(authenticate: !AUTH_OK. Authentication failed ($status)));
	$self->failed_attempt();
      }
      return $status;

    } else {
      return $AUTH_FAIL;
    }

  } elsif($self->sesskey()) {
    #########
    # session key (used so passwords aren't kept in cookies)
    #
    my $expiry = $self->sessexpiry();
    my $now    = $self->util->now();

    if($expiry && $expiry lt $now) {
      #########
      # session timed out
      #
      $self->log_error(q(sesskey: Session expired));
      return $AUTH_EXPIRED;
    }

    my $sesskey_db = $self->sesskey_db()||q();
    $self->log_error(qq(sesskey: sesskey=@{[$self->sesskey()]}, sesskey_db=$sesskey_db));
    if($sesskey_db ne $self->sesskey()) {
      $self->log_error(q(sesskey: Session key mismatch));
      return $AUTH_FAIL;
    }

    #########
    # update timestamp
    # (or update sessionkey if we want to be really strict)
    #
    $self->sessexpiry('update');
    return $AUTH_OK; # non-checked session-id
  }

  $self->log_error(q(sesskey: dropping through (AUTH_FAIL)));
  return $AUTH_FAIL;
}

sub create_salt {
  my $salt = q();
  $salt .= ( substr $SOURCE,rand( length $SOURCE),1 ) foreach (1..$SALT_LENGTH);
  return $salt;
}

sub fetch_salt {
  my $self = shift;
  my $sth  = $self->util->dbh->prepare(q(SELECT password
                 FROM   user
                 WHERE  username = ?));
  $sth->execute( $self->username() );
  my ($dbpass) = $sth->fetchrow_array();
  return (q(),q()) unless defined $dbpass;
  my ($salt,$pass) = split q(/),$dbpass;
  return $salt,$pass;
}

sub get_string {
  my ($self,$salt) = @_;
  my $username = $self->username();
if ($self->pw_encrypted() eq 'yes') {
  warn "password is already encrypted..?! == ".$self->password();
}
  $username =~ tr{\@\. \;}{}d; # avoid guaranteed letters like @ and . (com might be one as well)
  my $sth    = $self->util->dbh->prepare('select left( sha1( concat( ?,          ?,  reverse( lower( ?           ))) ) , ?)');
  $sth->execute(                                              $self->password(), $salt,              $self->username(), $MAX_PASSWORD );
  my ($encoded_pass) = $sth->fetchrow_array();
  return $salt.'/'.$encoded_pass;
}

# use mysql native functions to build salt+/+sha512 encoded form of (password+salt+username),
# ready to store or compare
sub get_string_512 {
  my ($self,$salt) = @_;
  my $username = $self->username();
  $username =~ tr{\@\. \;}{}d; # avoid guaranteed letters like @ and . (com might be one as well)
# sha2(x,512) returns 128 hexadecimal characters / hence the left(,$MAX_PASSWORD)
  my $sth    = $self->util->dbh->prepare('SELECT LEFT( SHA2( CONCAT(
                                                                    ?, ?, REVERSE(
                                                                                  LOWER( ? )
                                                                                 )
                                                                   ), 512 ), ?)');
  $sth->execute(
                                                                    $self->password(), $salt,
                                                                                         $self->username(),
                                                                             $MAX_PASSWORD_512 );
  my ($encoded_pass) = $sth->fetchrow_array();
  return $salt.'/'.$encoded_pass;
}

sub authenticate_DB {
  my ($self) = @_;
#  $self->log_error(qq(authenticate_DB: name=$sname, pass=$spass));
  my $query  = q(SELECT password
                 FROM   user
                 WHERE  username = ?
                  AND   password = SHA1(?));
# retire obsolete password forms 2012 June 11
#                         password = PASSWORD(?) OR
#                         password = OLD_PASSWORD(?)));
# plain sha1 passwords were removed from database 2012 Aug 24

  my $sth    = $self->util->dbh->prepare($query);
  $sth->execute($self->username(),
		$self->password());
  my ($dbpass) = $sth->fetchrow_array();
  $sth->finish();

  if (defined $dbpass) {
    warn "Login via original sha (obsolete)";

### Update database:
    my $newpass = $self->get_string($self->create_salt());
    eval {
      $self->util->dbh->do(q(UPDATE user
                             SET    password=?, modified=now()
                             WHERE  username = ?), {}, $newpass, $self->username());
    };
    carp $EVAL_ERROR if($EVAL_ERROR);
    return $AUTH_OK;
  } elsif ($AUTH_OK eq $self->is_sha1()) {
    # Update database to salted SHA512

    my $newpass = $self->get_string_512($self->create_salt());
    eval {
      $self->util->dbh->do(q(UPDATE user
                             SET    password=?, modified=now()
                             WHERE  username = ?), {}, $newpass, $self->username());
    };
    carp $EVAL_ERROR if($EVAL_ERROR);
    # warn "Password updated from salted SHA1 to salted SHA512";
    return $AUTH_OK;
  }

  return $self->is_sha512(); # If you can't pass this, you have failed.
# return $AUTH_FAIL;
}

sub is_sha1 {
  my $self = shift;
  my ($salt, $db_password) = $self->fetch_salt();
  my $string = $self->get_string($salt);
  return ($salt && $string && ($string eq ($salt . q(/) . $db_password)))?$AUTH_OK:$AUTH_FAIL;
}

sub is_sha512 {
  my $self = shift;
  my ($salt, $db_password) = $self->fetch_salt();
  my $string = $self->get_string_512($salt);
  return ($salt && $string && ($string eq ($salt . q(/) . $db_password)))?$AUTH_OK:$AUTH_FAIL;
}

sub authenticate_NIS {
  my ($self)       = @_;
  my $password     = $self->password();
  my ($t, $passwd) = getpwnam $self->username();

  if(!defined $passwd || $passwd eq q()) {
    return $AUTH_FAIL;
  }
  if($passwd eq 'x') {
    return $AUTH_SHADOW;
  }

  my $salt = substr $passwd, 0, 2;
  if(crypt($password, $salt) eq $passwd) {
    return $AUTH_OK;
  }
  return $AUTH_FAIL;
}

sub authenticate_LDAP {
  my ($self)   = @_;

  eval {
    require Net::LDAP;
  };
  $EVAL_ERROR and return $AUTH_SERVERERR;

  my $password = $self->password();
  my $username = $self->username();
  my $msg      = $self->_ldap->bind(
				    "uid=$username,ou=people,dc=sanger,dc=ac,dc=uk",
				    'password' => $password,
				   );
  if($msg->code==0) {
    return $AUTH_OK;
  }

  return $AUTH_FAIL
}

sub _ldap {
  my $self = shift;
  return Net::LDAP->new('ldap.internal.sanger.ac.uk');
}

sub realname_LDAP {
  my $self = shift;
  warn "checking realname from LDAP";
  if(!$self->{'realname'}) {
    my $username = $self->{'username'};
    $self->log_error(qq(realname_LDAP: attempting to find realname for $username));
    #########
    # if no realname is present, we can fetch it from LDAP
    #
    eval {
      require Net::LDAP;
    };
    $EVAL_ERROR and return q();
    my $tmp = $self->_ldap->search(
				   'base'   => 'ou=people,dc=sanger,dc=ac,dc=uk',
				   'filter' => "uid=$username",
				  );
    if($tmp) {
      my @e = $tmp->entries();
      if(@e) {
	my $rn = (sprintf '%s %s', $e[0]->get_value('givenName'), $e[0]->get_value('sn')) || q();
	$self->log_error(qq(authenticate_LDAP: set realname '$rn' for $username));
	$self->{'realname'} = $rn;
	return $rn;
      }
    }
  }
  return $self->{'realname'}||q();
}

sub authenticate_TRIU {
  my ($self) = @_;
  eval {
    require LWP::UserAgent;
  };

  $EVAL_ERROR and return $AUTH_SERVERERR;

  my $password   = $self->password();
  my $username   = $self->username();
  my $credential = q();
  my $url        = q(https://bloodomics.mytrium.com/intranet/checkAuth.do?username=%s&password=%s&credential=%s);
  my $browser    = LWP::UserAgent->new();
  my $response   = $browser->get(sprintf $url, $username, $password, $credential);

  $response->is_success() or return $AUTH_SERVERERR;

  if ($response->content =~ /AuthFail/mx) {
    return $AUTH_FAIL;

  } elsif ($response->content =~ /AuthOk/mx) {
    return $AUTH_OK;
  }

  return $AUTH_FAIL;
}

sub authtype_description {
  my ($self, $authtype) = @_;
  return $self->util->authtype_description($authtype||$self->authtype())->{'type'};
}

sub sesskey {
  my ($self, $sesskey, $nukeexpiry) = @_;
  $nukeexpiry ||= q();
  my $username = $self->{'username'};

  if(!$username) {
    $self->log_error(q(sesskey: no username defined));
    return;
  }

  if(defined $sesskey) {
    my $newsesskey    = $self->util->get_unique_id(); #$sesskey;
    my $rows_affected = 0;

    eval {
      #########
      # Update the session key if either:
      # a) we've been instructed to do so
      # or
      # b) it's expired
      #
      my $query = qq(UPDATE user
                     SET    sesskey    = ?
                     WHERE  username   = ?
                     @{[($nukeexpiry ne 'nuke')?'AND sessexpiry < now()':q()]});
      $query =~ s/\s+/ /smgx;
      $self->log_error(qq(sesskey: updating session key: $query));
      $rows_affected = $self->util->dbh->do($query, {}, $newsesskey, $username);
    };
    $EVAL_ERROR and carp $EVAL_ERROR;

    if($rows_affected == 0) {
      my $ref;
      eval {
	$ref = $self->util->dbh->selectall_arrayref(q(SELECT username
                                                      FROM   user
                                                      WHERE  username=?), {}, $username);
      };
      carp $EVAL_ERROR if($EVAL_ERROR);

      if($ref->[0] && $ref->[0]->[0]) {
	$self->log_error(q(sesskey: Move along. Nothing to see here.));
	#########
	# username exists and didn't update - everything's ok. Ignore
	#

      } else {
	$self->log_error(qq(sesskey: auto-inserting user placeholder for $username));
	#########
	# username doesn't exist - auto insert the necessary
	#
	eval {
	  $ref = $self->util->dbh->selectall_arrayref(q(SELECT id
                                                        FROM   authtype
                                                        WHERE  type = ?), {}, $DEFAULT_AUTHTYPE);
	};
	carp $EVAL_ERROR if($EVAL_ERROR);

	my ($authtype_id) = $ref->[0]->[0];
	my $rn_method     = "realname_$DEFAULT_AUTHTYPE";
	my $realname      = ($self->can($rn_method))?$self->$rn_method():q();
	my $query         = q(REPLACE INTO user (username,realname,created,modified,sesskey,authtype,addedby)
                              VALUES(?,?,now(),now(),?,?,'auto'));
	eval {
	  $rows_affected  = $self->util->dbh->do($query, {}, $username, $realname, $newsesskey, $authtype_id);
	};
	carp $EVAL_ERROR if($EVAL_ERROR);
      }
    }

    if($rows_affected!=0) {
      #########
      # If we updated then set our session key to the new value
      #
      $self->log_error(qq(sesskey: username=$username, rows_affected = $rows_affected));
      $self->{'sesskey'} = $newsesskey;

    } else {
      #########
      # otherwise fetch the current valid key from the database
      #
      $self->log_error(qq(sesskey: username=$username, fetching current valid sesskey));
      $self->{'sesskey'} = $self->sesskey_db();
    }

    $self->sessexpiry($nukeexpiry?'nuke':'update');
  }
  $self->log_error(qq(sesskey: my in-memory sesskey = @{[$self->{'sesskey'}||q()]}));
  return $self->{'sesskey'} || 'thunk';
}

sub sesskey_db {
  my ($self) = @_;
  my $sth    = $self->util->dbh->prepare(q(SELECT sesskey
                                           FROM   user
                                           WHERE  username=?));
  $sth->execute($self->{'username'});
  my ($sesskey) = $sth->fetchrow_array();
  $sth->finish();
  return $sesskey;
}

sub sessexpiry {
  my ($self, $update)  = @_;

  if($update) {
    my $ref            = {};
    my $authex         = $self->util->can('AUTH_EXPIRY')?$self->util->AUTH_EXPIRY():undef;

    if($authex) {
      my ($val, $unit) = $authex =~ /^[\+\-]?(\d+)([a-z]+)$/mx;
      if($unit eq 'd') {
	$ref->{'day'}    = $val;
      } elsif($unit eq 'h') {
	$ref->{'hour'}   = $val;
      }

    } else {
      $ref->{'hour'}   = 1;
    }

    my $splusone       = ($update eq 'nuke')?'0000-00-00 00:00:00':$self->util->now($ref);

    $self->log_error(qq(sessexpiry: update=$update:  Setting expiry date ($authex) to $splusone (was @{[$self->sessexpiry()]})));

    eval {
      $self->util->dbh->do(q(UPDATE user
                             SET    sessexpiry = ?
                             WHERE  username   = ?), {}, $splusone, $self->{'username'});
    };
  }

  my $sth = $self->util->dbh->prepare(q(SELECT sessexpiry
                                        FROM   user
                                        WHERE  username=?));
  $sth->execute($self->{'username'});
  my ($sessexpiry) = $sth->fetchrow_array();
  $sth->finish();
# Users who haven't been created yet dont have sessexpiry, but do need a default value
  return $sessexpiry || '0000-00-00 00:00:00';
}

sub all_users {
  my ($self, $userclass, $filter) = @_;

  if(ref $userclass && !$filter) {
    $filter    = $userclass;
    $userclass = undef;
  }

  $filter    ||= {};
  $userclass ||= 'Website::SSO::User';

  if(!ref $self) {
    $self      = $self->new();
  }

  my (@users, @restrictions, @bound);

  #########
  # build filters
  #
  for my $f (keys %{$filter}) {
    push @restrictions, qq($f LIKE ? );
    push @bound, $filter->{$f}.q(%);
  }
  my $restrictions = (scalar @restrictions)?qq(WHERE @{[join ' AND ', @restrictions]}):q();
  my $sth          = $self->util->dbh->prepare(qq(SELECT username,realname,authtype
                                                  FROM   user $restrictions
                                                  ORDER BY realname,username));
  $sth->execute(@bound);
  while(my $ref = $sth->fetchrow_hashref()) {
    $ref->{'util'} = $self->util();
    push @users, $userclass->new($ref);
  }
  return @users;
}

sub logins {
  my ($self, $userclass) = @_;
  $userclass ||= 'Website::SSO::User';
  if(!ref $self) {
    $self      = $self->new();
  }
  my @users    = ();
  my $query    = (q(SELECT username,realname,authtype,sesskey,sessexpiry,addedby,note
                    FROM   user
                    WHERE  sessexpiry > now()
                    ORDER BY username));
  my $sth      = $self->util->dbh->prepare($query);
  $sth->execute();

  while(my $ref = $sth->fetchrow_hashref()) {
    $ref->{'util'} = $self->util();
    push @users, $userclass->new($ref);
  }

  return @users;
}

sub update {
  my $self            = shift;
  $self->{'modified'} = $self->util->now();

  eval {
    for my $f ($self->fields()) {
      my $v =  ($f ne 'sesskey' && $self->can($f))?$self->$f:q();
      next if(!defined $v || $v eq q());
      if ($f eq 'password' && ($self->pw_encrypted() ne 'yes')) {
        warn "updating password";
        $v = $self->get_string($self->create_salt);
      } elsif ($f eq 'password') { # password is encrypted so this should cause no harm
        # warn "re-setting password as [$v]";
      }

      my $query = qq(UPDATE user SET $f=? WHERE username=?);

      $self->util->dbh->do($query, {}, $v, $self->username());
    }
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return 0;
  }
  return 1;
}

sub send_update_password_message {
  my $self = shift;
  my $mailer = Website::Utilities::Mail->new({
					      'to'      => (sprintf '%s <%s>', $self->realname(), $self->email()),
					      'from'    => $FROM,
					      'subject' => 'Password Reset',
					      'message' => qq(
Your WTSI website password has been reset:
Username:  @{[$self->username()]}
Email:     @{[$self->email()]}
Real Name: @{[$self->realname()]}

To login, go to the WTSI website:
http://www.sanger.ac.uk/

and click on the key icon near the top-left.\n),
					     });
  $mailer->send();
  return;
}

sub add {
  my $self            = shift;
  $self->{'modified'} = $self->util->now();
  $self->{'created'}  = $self->{'modified'};

  #########
  # If username is an email address and email wasn't given
  # then email == username
  #
  if(!$self->email() && $self->username() =~ /\@/mx) {
    $self->email($self->username());
  }

  if(!$self->authtype()) {
    my $all_authtypes = $self->util->all_authtypes();
    my ($id)          = map { $_->{'id'} } grep { $_->{'type'} eq $DEFAULT_AUTHTYPE } values %{$all_authtypes};
    $self->authtype($id);
  }

  my $query = q(REPLACE INTO user (username,realname,authtype,password,created,modified,addedby,note,ipaddr,sesskey,sessexpiry,email)
                VALUES(?,?,?,?,now(),now(),?,?,?,?,?,?));
  # Replace like for like if password came from database
  my $password = ($self->pw_encrypted() eq 'yes')?$self->password():$self->get_string($self->create_salt());

  eval {
    print {*STDERR} qq($query\n);
    $self->util->dbh->do($query, {},
			 $self->username(),
			 $self->realname(),
			 $self->authtype(),
			 $password,
			 $self->addedby(),
			 $self->note(),
			 $self->ipaddr()     || q(),
			 $self->sesskey()    || q(),
			 $self->sessexpiry(),
			 $self->email());
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return 0;

  } else {
    #########
    # Auto-send mail
    #
    my $mailer = Website::Utilities::Mail->new({
						'to'      => (sprintf '%s <%s>', $self->realname(), $self->email()),
						'from'    => $FROM,
						'subject' => 'Account Created',
						'message' => qq(
Your account on the WTSI website has been created:
Username:  @{[$self->username()]}
Email:     @{[$self->email()]}
Real Name: @{[$self->realname()]}

To login, go to the WTSI website:
http://www.sanger.ac.uk/my_login.shtml

and click on the key icon near the top-left.\n),
					       });
    $mailer->send();

    return 1;
  }
  return;
}

sub delete {
  my $self = shift;

  #########
  # remove user entry
  #
  eval {
    $self->util->dbh->do(q(DELETE FROM user
                           WHERE username = ?), {}, $self->username());
  };
  $EVAL_ERROR and carp $EVAL_ERROR;
  return;
}

sub log_error {
  my ($self, @args) = @_;
  $DEBUG or return;

  if(!$self->{'_ap_req'}) {
    eval {
      require Apache;
      $self->{'_ap_req'} ||= Apache->request();
    };
  }

  if($self->{'_ap_req'}) {
    $self->{'_ap_req'}->warn('SSO::User:' . join q(), @args);
  } else {
    print {*STDERR} 'SSO::User: ', @args, "\n";
  }

  return;
}

sub request_reset {
  my $self     = shift;
  my $atdesc   = $self->authtype_description();
  my $username = $self->username();
  if($atdesc ne 'DB') {
    carp qq(Website::SSO::User cannot reset password for $username with authtype '$atdesc');
    return 0;
  }

  my $id = Website::Utilities::IdGenerator->get_hashed_id();
  eval {
    $self->util->dbh->do(q(REPLACE INTO reset (username,token,timestamp) VALUES(?,?,NOW())),
			 {},
			 $username,
			 $id);
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return 0;
  }

  my $enc_id = uri_escape($id);

  #########
  # Auto-send mail
  #
  my $mailer = Website::Utilities::Mail->new({
					      'to'      => (sprintf '%s <%s>', $self->realname(), $self->email()),
					      'from'    => $FROM,
					      'subject' => 'Password Reset Request',
					      'message' => qq(
Someone has requested a password reset on your WTSI website account:
Username @{[$self->username()]}

Use this URL to reset your password:

http://www.sanger.ac.uk/perl/ssomanager?action=reset&token=$enc_id

If you did not make this request then this email is safe to ignore.\n),
					     });
  $mailer->send();

  return 1;
}

sub enforced_reset {
  my $self = shift;
  my $username = $self->username();
  $self->lock(0,500_000);
  my $atdesc   = $self->authtype_description();
  if($atdesc ne 'DB') {
     carp qq(Website::SSO::User cannot reset password for $username with authtype '$atdesc');
     return 0;
  }

  my $id = Website::Utilities::IdGenerator->get_unique_id();
  eval {
    $self->util->dbh->do(q(REPLACE INTO reset (username,token,timestamp) VALUES(?,?,NOW())),
			 {},
			 $username,
			 $id);
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return 0;
  }

  #########
  # Auto-send mail
  #

  my $message = qq(The password for the user @{[$self->username()]} has been found to be insecure. The account has been locked, as a precautionary measure. Please use the following URL to reset your password and unlock your account:

http://www.sanger.ac.uk/perl/ssomanager?action=reset;token=$id

It is important to make sure that the password you choose is not easily guessed. We have included a 'password effectiveness' tool on the reset page, which will turn green when your password is sufficiently secure.\n);

  my $mailer = Website::Utilities::Mail->new({
					      'to'      => (sprintf '%s <%s>', $self->realname(), $self->email()),
					      'from'    => $FROM,
					      'subject' => 'Password Reset',
					      'message' => $message,
					     });
  $mailer->send();

  return 1;


}

sub request_create {
  my ($self,$message) = @_;
  my $username = $self->username() || q();
  my $email    = $self->email()    || q();

  if($email =~ /sanger.ac.uk/mx) {
    $message .= qq(\nSingle Sign On accounts cannot be created with .sanger.ac.uk email addresses.);
  }

  my $id = Website::Utilities::IdGenerator->get_unique_id();
  eval {
    $self->util->dbh->do(q(REPLACE INTO unverified (username,token,timestamp) VALUES(?,?,NOW())),
			 {},
			 $username,
			 $id);
  };
  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return 0;
  }

  $message ||= qq(

Use this URL to create your account:

http://www.sanger.ac.uk/perl/ssomanager?action=vrfy;token=$id

);


  my $fullmessage = qq(
Someone has requested a new WTSI website account with this email address:

@{[$self->username()]}

$message

If you did not make this request then this email is safe to ignore.\n);

  #########
  # Auto-send mail
  #
  my $mailer = Website::Utilities::Mail->new({
					      'to'      => (sprintf 'Unverified User <%s>', $email),
					      'from'    => $FROM,
					      'subject' => 'Account Creation Request',
					      'message' => $fullmessage,
					     });
  $mailer->send();

  return 1;
}

sub is_locked {
  my $self  = shift;
  my $query = q(SELECT timediff(locked_until,now()) FROM lockout WHERE username=? AND locked_until > now());
  my $ref   = [];

  eval {
    $ref = $self->util->dbh->selectall_arrayref($query, {}, $self->username());
  };
  $EVAL_ERROR and carp $EVAL_ERROR;

  return (scalar @{$ref})?$ref->[0]->[0]:undef;
}

sub failed_attempt {
  my $self     = shift;
  my $dbh      = $self->util->dbh();
  my $username = $self->username();
  my $query    = q(SELECT attempts FROM lockout WHERE username=?);
  my $ref      = $self->util->dbh->selectall_arrayref($query, {}, $username);
  my $count    = (scalar @{$ref})?$ref->[0]->[0]:0;
  $count++;

  if($count >= $LOCK_AFTER_FAILURES) {
    $self->lock($count);

  } else {
    eval {
      $dbh->do(q(REPLACE INTO lockout (username,attempts,locked_on) VALUES(?, ?, NOW())), {}, $username, $count);
    };
    $EVAL_ERROR and carp $EVAL_ERROR;
  }
  return;
}

sub lock {
  my ($self, $count, $duration) = @_;
  $count     ||= '0';
  $duration  ||= $LOCK_DURATION;
  my $query          = q(REPLACE INTO lockout (username,attempts,locked_until,locked_on) VALUES(?,?,DATE_ADD(NOW(), INTERVAL ? HOUR),NOW()));
  eval {
    $self->util->dbh->do($query, {}, $self->username(), $count, $duration);
  };
  $EVAL_ERROR and carp $EVAL_ERROR;

  return;
}

sub unlock {
  my $self = shift;
  eval {
    $self->util->dbh->do(q(DELETE FROM lockout WHERE username=?), {}, $self->username());
  };
  $EVAL_ERROR and carp $EVAL_ERROR;
  return;
}

1;

__END__

=head1 NAME

Website::SSO::User - Inherits and extends Website::Utilities::BasicUser

=head1 VERSION

$Revision: 1.22 $

=head1 DESCRIPTION

 Originally written for the Fishfat Procurement system, this is now an
 interface onto the 'user' table inside the website single-sign-on
 (SSO) system.

=head1 EXPORTS

  $AUTH_OK
  $AUTH_FAIL
  $AUTH_SHADOW
  $AUTH_EXPIRED
  $AUTH_SERVERERR

=head1 SYNOPSIS

  use SangerPaths qw(core);
  use Website::SSO::User;

  my $oUser = Website::SSO::User->new({'username' => 'xyz'});
  $, = "\n";
  print map { $oUser->$_() } qw(realname email created modified addedby note);

  my $oUserPreferences = $oUser->userconfig();

  #########
  # Authenticate with a SSO password
  #
  my $oUser1 = Website::SSO::User->new({
                                        'username' => 'xyz',
                                        'password' => 'UnencryptedPasswordString',
                                       });
  my $sState = $oUser1->authenticate();


  #########
  # Authenticate with a SSO session token
  #
  my $oUser2 = Website::SSO::User->new({
                                        'username' => 'xyz',
                                        'sesskey'  => 'SessionTokenString',
                                       });
  my $sState = $oUser2->authenticate();

=head1 SUBROUTINES/METHODS

=head2 new : Constructor

  my $oUser = Website::SSO::User->new({
                                       'util'         => Website::SSO::Util->new(),
                                       'username'     => $sUsername,
                                       'ipaddr'       => $sIPAddress,
                                       'sessexpiry'   => $sSessionExpiryDate,
                                       'realname'     => $sRealName,
                                       'authtype'     => $iAuthenticationType,
                                       'password'     => $sPassword,
                                       'sesskey'      => $sSessionToken,
                                       'created'      => $sCreationDate,
                                       'modified'     => $sModificationDate,
                                       'addedby'      => $sAddedByUsername,
                                       'note'         => $sPurposeNote,
                                       'email'        => $sEmailAddress,
                                       'pw_encrypted' => $sYesNoPasswordIsEncrypted,
                                      });

=head2 fields : Array of attributes for this user

  my @aFields = $oUser->fields();

=head2 util : Database handle for the sso database

  my $oUtil = $oUser->util();

=head2 userconfig : Personal configuration data (Website::SSO::UserConfig) for this user

  my $oConfig = $oUser->userconfig();

=head2 quickload : Internal load method

  $self->quickload() is invoked when an unpopulated attribute is requested from $oUser.

=head2 addedby : Administrator username or application responsible for adding this user

  $oUser->addedby('xyz');
  my $sAddedBy = $oUser->addedby();

=head2 note : Note about why this user was added

  $oUser->note('For use of application abc');
  my $sNote = $oUser->note();

=head2 created : Creation date for this user (MySQL/ISO format)

  my $sCreated = $oUser->created();

=head2 email : Email address for this user

  $oUser->email('xyz@example.com');
  my $sEmail = $oUser->email();

=head2 realname : Real name for this user

  $oUser->realname('First Last');
  my $sRealName = $oUser->realname();

=head2 modified : Last modification date for this user

  my $sModificationDate = $oUser->modified();

=head2 password : Password for this user

  $oUser->password('UnencryptedString');
  my $sPassword = $oUser->password();

=head2 pw_encrypted : Is the password in this user object encrypted?

  my $sYesNo = $oUser->pw_encrypted();

=head2 authtype : Numeric authentication method for this user

  my $iAuthType = $oUser->authtype();

=head2 ipaddr : Last known IP address for this user

  my $sIPAddr = $oUser->ipaddr();

=head2 authenticate : Authenticate user via password or session token

  my $iAuthState = $oUser->authenticate();
  print {
          $AUTH_OK        => 'ok',
          $AUTH_FAIL      => 'failure',
          $AUTH_SHADOW    => 'failure: shadow passwords in use',
          $AUTH_EXPIRED   => 'failure: session expired',
          $AUTH_SERVERERR => 'failure: server error',
        }->{$iAuthState};

=head2 authenticate_DB : Internal authentication implementation for MySQL

  my $iState = $oUser->authenticate_DB();

=head2 authenticate_NIS : Internal authentication implementation for NIS/YP

  my $iState = $oUser->authenticate_NIS();

=head2 authenticate_LDAP : Internal authentication implementation for LDAP

  my $iState = $oUser->authenticate_LDAP();

=head2 _ldap : Cached Net::LDAP instance

  my $oNetLDAP = $oUser->_ldap();

=head2 realname_LDAP : LDAP implementation to fetch realnames

  my $sRealName = $oUser->realname_LDAP();

=head2 authenticate_TRIU : Internal authentication implementation for TRIUM

  my $iState = $oUser->authenticate_TRIU();

=head2 authtype_description : English description of authentication type

  my $sAuthTypeDescription = $oUser->authtype_description($iAuthType);
  my $sAuthTypeDescription = $oUser->authtype_description();

=head2 sesskey : New or existing session key for this user

  my $sSessionToken = $oUser->sesskey();

=head2 sesskey_db : Existing session key for this user from the sso database

  my $sExistingSessionToken = $oUser->sesskey_db();

=head2 sessexpiry : Session expiry date for this user

  my $sSessionExpiryDate = $oUser->sessexpiry();

=head2 all_users : Array of all Website::SSO::User in the sso system

  my @aAllUsers = $oUser->all_users();
  my @aAllUsers = $oUser->all_users('My::User::Package');

=head2 logins : Array of all Website::SSO::User currently logged in (session expiry > now)

  my @aLogins = $oUser->logins();
  my @aLogins = $oUser->logins('My::User::Package');

=head2 update : Update a user in the database

  $oUser->update();

=head2 send_update_password_message : Send a "password-reset" email

  $oUser->send_update_password_message();

=head2 add : Add a user to the sso database and send a notification email

  $oUser->add();

=head2 delete : Delete a user from the sso database

  $oUser->delete();

=head2 log_error : Log errors via Apache->request or STDERR

  $oUser->log_error("my message");

=head2 request_reset : Request a password reset and send notification email

  $oUser->request_reset();

=head2 request_create : Request an account creation and send a notification mail

  $oUser->request_create();

=head2 is_locked : Has this account been locked

  Returns true if the account has been locked for any reason -
  e.g. multiple authentication failures; administrative prejudice

  my $bState = $oUser->is_locked();

=head2 failed_attempt : Log a failed authentication attempt

  The account is locked if the number of failed attempts
  is greater than $LOCK_AFTER_FAILURES

  $oUser->failed_attempt();

=head2 lock : Lock this user account temporarily (1 hour)

  $oUser->lock();
  $oUser->lock($count);

=head2 unlock : Unlock this user account

  $oUser->unlock();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE AND COPYRIGHT

=cut
