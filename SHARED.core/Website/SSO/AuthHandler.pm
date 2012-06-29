package Website::SSO::AuthHandler;
########
# Author:        rmp
# Created:       2004-10-27
# Last Modified: $Date: 2009-04-01 08:30:54 $ $Author: jc3 $
# Id:            $Id: AuthHandler.pm,v 1.36 2009-04-01 08:30:54 jc3 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/SSO/AuthHandler.pm,v $
# $HeadURL$
#
# Subclass Apache::AuthCookie to provide Sanger Site Single Sign On (SSSSO !)
#
use strict;
use warnings;
use Website::SSO::User qw($AUTH_OK $AUTH_FAIL $AUTH_SHADOW $AUTH_EXPIRED $AUTH_SERVERERR);
use Website::SSO::Util;
use base qw(Apache2::AuthCookie);
use Apache2::Const qw(REDIRECT OK FORBIDDEN);
use English qw(-no_match_vars);
use Carp;
use Data::Dumper;

our $VERSION = do { my @r = (q$Revision: 1.36 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $DEBUG   = 0;

sub authen_cred {
  my ($self, $r, $username, $password) = @_;
  $username            ||= q();
  $password            ||= q();
  $username              =~ s/\@sanger.ac.uk//mx;
  $DEBUG and $r->log_error(qq(username=$username, password=@{['*'x(length($password))]}));
  my $user               = Website::SSO::User->new({
						    'util'     => (ref $self)?$self->{'_userutil'}:undef,
						    'username' => $username,
						    'password' => $password,
						   });
  if(ref $self) {
    $self->{'_userutil'} ||= $user->util();
  }
  my $auth_state         = $user->authenticate();
  my $authenticated      = ($auth_state == $AUTH_OK);
  if($ENV{'HTTP_X_FORWARDED_FOR'}) {
    $user->ipaddr($ENV{'HTTP_X_FORWARDED_FOR'});
  }

  if(!$authenticated) {
    return q[];
  }

  return $user->util->encode_token("$username:@{[$user->sesskey()]}");
}

sub authen_ses_key {
  my ($self, $r, $session) = @_;
  $session               ||= q();
  my ($username, $sesskey);

  eval {
    my $decoded = Website::SSO::Util->decode_token($session);
    ($username, $sesskey) = split /:/mx, $decoded, 2;
  };

  if(!$username || !$sesskey) {
    $DEBUG and $r->warn(q[SSO::AuthHandler::authen_ses_key: Failed to decrypt session token]);
    return (q[], 1);
  }

  my $user = Website::SSO::User->new({
				      'util'     => (ref $self)?$self->{'_userutil'}:undef,
				      'sesskey'  => $sesskey  || q(),
				      'username' => $username || q(),
				     });
  if(ref $self) {
    $self->{'_userutil'} ||= $user->util();
  }
  my $auth_state           = $user->authenticate();
  my $authenticated        = ($auth_state == $AUTH_OK);

  if($authenticated) {
    $DEBUG and $r->warn(q(SSO::AuthHandler::authen_ses_key: ), $r->uri(), qq(: session $session re-authenticated));
    return $username || q();

  }

  $DEBUG and $r->warn(q(SSO::AuthHandler::authen_ses_key: failed re-authentication));
  return (q(), 1); # custom error 1 (logout!)
}

sub custom_errors {
  my ($self, $r, $code) = @_;
  $DEBUG and $r->warn(qq(SSO::AuthHandler::custom_errors for $code));
  return $self->logout($r);
}

sub post_logout {
  my ($self, $r) = @_;
  my $user = $r->notes->get('username');
  if ($r->headers_in->get('X-Requested-With') && 
                     $r->headers_in->get('X-Requested-With') =~ /XMLHttpRequest/) {
    $r->content_type('text/xml');
    $r->headers_out->unset('Location');
    $r->print(qq(<?xml version="1.0" encoding="utf-8"?>
<ssologout user="$user" status="1"/>));
    return OK;
  }
  my $uri = $r->headers_in->{'Referer'} || $ENV{'HTTP_REFERER'} || q(/);
  $r->headers_out->set(Location => $uri);
  return REDIRECT;
}

sub logout {
  my ($self, $r)              = @_;
  my ($auth_type, $auth_name) = ($r->auth_type(), $r->auth_name());
	my $cookie_name = $self->cookie_name($r);
  my ($cookie)                = $r->headers_in->{'Cookie'} =~ /${cookie_name}=([^;]+)/mx;
  $cookie                   ||= q();

  $DEBUG and $r->warn(qq(SSO::AuthHandler: logout cookie=$cookie));

  my ($username, $sesskey)    = $self->authen_ses_key($r, $cookie);

  #########
  # invalidate cookie
  #
  $self->SUPER::logout($r);

  $DEBUG and $r->warn(qq(SSO::AuthHandler::logout username=@{[$username||q()]}, sesskey=@{[$sesskey||q()]}));
    
  if($username) {
    #########
    # invalidate db session key
    #
    $r->notes->set('username' => $username);
    my $user = Website::SSO::User->new({
					'util'     => (ref $self)?$self->{'_userutil'}:undef,
					'username' => $username,
					'sesskey'  => $sesskey,
				       });
    if(ref $self) {
      $self->{'_userutil'} ||= $user->util();
    }
    $DEBUG and $r->warn(q(SSO::AuthHandler::logout: Nuking session key and expiry date));
    $user->sesskey(1, 'nuke');
  }

  return OK;
}

sub login {
    my ($self, $r) = @_;
    # need to return xml here if requested via ajax
    if ($r->headers_in->get('X-Requested-With') && 
	    $r->headers_in->get('X-Requested-With') =~ /XMLHttpRequest/) {
      return $self->ajax_login($r);
    }
    else {
      return $self->SUPER::login($r);
    }
}

sub ajax_login {
  my ($self, $r) = @_;
  my $debug = $r->dir_config("AuthCookieDebug") || 0;
  my $authenticated = 0;

  my $auth_type = $r->auth_type;
  my $auth_name = $r->auth_name;

  my %args = $self->_get_form_data($r);

  if ($r->method eq 'POST') {
      $self->_convert_to_get($r, \%args);
  }

  $r->content_type('text/xml');

  # Get the credentials from the data posted by the client
  my @credentials;
  for (my $i = 0; exists $args{"credential_$i"}; $i++) {
    my $key = "credential_$i";
    push @credentials, $args{$key};
  }

  # Exchange the credentials for a session key.
  my $ses_key = $self->authen_cred($r, @credentials);

  my $user = Website::SSO::User->new({
				      'util'     => (ref $self)?$self->{'_userutil'}:undef,
			              'username' => $credentials[0],
                		      'password' => $credentials[1],
                 		     });

  my $locked = ($user->is_locked)?1:0;

  if ($ses_key) {
    $authenticated = 1; 
    $self->send_cookie($r, $ses_key);
  }
  else {
    $r->server->log_error("Bad credentials") if $debug >= 2;
    $r->print(qq(<?xml version="1.0" encoding="utf-8"?>
<ssologin user="@{[$credentials[0]]}" authenticated="$authenticated" locked="$locked"/>));
    return FORBIDDEN;
  }

  $self->handle_cache($r);

  $r->print(qq(<?xml version="1.0" encoding="utf-8"?>
<ssologin user="@{[$credentials[0]]}" authenticated="$authenticated" locked="$locked"/>));
  return OK;
}

1;
__END__

=head1 NAME

Website::SSO::AuthHandler - Inherits and extends Apache2::AuthCookie

=head1 VERSION

$Revision: 1.36 $

=head1 SYNOPSIS

  Apache mod_perl handler for authenticating username+password and
  username+sessiontoken for the Sanger Single Sign On

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 authen_cred : Authenticate with Username and Password

  my $bIsAuthenticated = Website::SSO::AuthHandler->authen_cred($r, $sUsername, $sPassword);
  my $bIsAuthenticated = $oAuthHandler->authen_cred($r, $sUsername, $sPassword);

=head2 authen_ses_key : Authenticate with existing session key (username:key)

  my $bIsAuthenticated = Website::SSO::AuthHandler->authen_cred($r, $sSessionToken);
  my $bIsAuthenticated = $oAuthHandler->authen_cred($r, $sSessionToken);

=head2 crypter : A Crypt::CBC configured with the site private key

=head2 custom_errors : Called in the event of a session_key being invalid or expiring in the database

  my $bIsAuthenticated = Website::SSO::AuthHandler->authen_cred($r, $sSessionToken);
  my $bIsAuthenticated = $oAuthHandler->authen_cred($r, $sSessionToken);

=head2 logout : Logout / invalidate session

  my $ApacheConst = Website::SSO::AuthHandler->logout($r);
  my $ApacheConst = $oAuthHandler->logout($r);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE AND COPYRIGHT

=cut
