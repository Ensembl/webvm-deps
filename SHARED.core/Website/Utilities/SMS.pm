package Website::Utilities::SMS;
#########
# Author: ssg-spt
# Maintainer: rmp
# Description: SMS Notification Gateway
#
# Note: This is a paid-for service so don't use this too much!
# This also requires internet access (so no notifications if the link goes down!)
#
# Example Usage:
# 
# use lib "/nfs/WWWdev/SANGER_docs/bin-offline";
# use Website::Utilities::SMS;
# $ENV{'PATH'} = "";
# 
# my $sms = Website::Utilities::SMS->new({
#  'to'          => ['webmaster', 'rmp@sanger.ac.uk', qw(ass rmp ab6 jc3)],
#  'cc'          => ['ab6@sanger.ac.uk', 'sanger'], 
#  'subject'     => 'test mail from Website::Utilities::SMS',
#  'message'     => "some test message text from $hostname\n\n",
#});
#
#$sms->send();
#
use LWP::Simple;
use CGI qw(escape);
use strict;                                                                                                                               
use vars qw($DEBUG);
#$DEBUG = 1;

sub new {
  my ($class, $opts) = @_;
  my $self = {
              'to'      => $opts->{'to'},
              'cc'      => $opts->{'cc'},
              'subject' => $opts->{'subject'},
              'message' => $opts->{'message'},
              'from'    => $opts->{'from'} || "w3adm",
	      'groups'  => {
			    'webroot'   => [qw(avc jws rmp)],
			    'webmaster' => [qw(ensembl sanger corebio)],
			    'ensembl'   => [qw(avc jws js5 whs pm2 bg2)],
			    'sanger'    => [qw(avc rmp ab6 raw jc3)],
			    'corebio'   => [qw(avc hrh)],
			   },
	      'numbers' => {
			    'avc' => "07977924225",
			    'hrh' => "07780573436",

			    #########
			    # sanger
			    #
			    'rmp' => "07715740715",
			    'raw' => "07989271807",
			    'jc3' => "07949666631",
			    'ab6' => "",

			    #########
			    # ensembl
			    #
			    'jws' => "07788590342",
			    'js5' => "07803047830",
			    'whs' => "07899654373",
			    'pm2' => "07770526961",
			    'bg2' => "07754199056",
			   },
	      'username' => "wtsisms",
	      'password' => "yDvEBpNG",
	     };

  bless $self, $class;
  
  return $self;
}

sub send {
  my ($self) = @_;
  my $cgi    = CGI->new();
  my @to     = ();

  #########
  # import userlist
  #
  for my $to ((@{$self->{'to'}}, @{$self->{'cc'}})) {
    $to =~ /^([a-z0-9A-Z]+)/;
    $to = lc($1);
    $DEBUG and warn qq(To: $to);

    push @to, $to;
  }

  #########
  # expand groups
  #
  my $seengroups = {};
  my @expanded   = ();
  while (my $to = pop @to) {
    next if($seengroups->{$to});
    if(!$self->{'numbers'}->{$to} && $self->{'groups'}->{$to} && !$seengroups->{$to}) {
      $DEBUG and warn qq(Pushing group $to);
      push @to, @{$self->{'groups'}->{$to}};

    } else {
      $DEBUG and warn qq(Pushing user $to);
      push @expanded, $to;
    }
    $seengroups->{$to}++;
  }

  #########
  # map phone numbers
  #
  my $seenuser = {};
  $DEBUG and warn "@expanded";

  my @phone    = map {
    $self->{'numbers'}->{$_}
  } grep {
    $self->{'numbers'}->{$_} && $self->{'numbers'}->{$_} ne ""
  } grep { !$seenuser->{$_}++ } @expanded;

  my $msg = ($self->{'subject'} || "") . ": " . ($self->{'message'} || "");
  $msg    =~ s/\s+/ /smg;
  
  if(length($msg) > 160) {
    die "Message too long\n";
  }

  #########
  # URL encode all our strings
  #
  $msg     = $cgi->escape($msg);
  my $from = $cgi->escape($self->{'from'});

  die "No numbers\n" unless @phone;

  my $url = qq(http://www.intellisoftware.co.uk/smsgateway/sendmsg.aspx?username=$self->{'username'}&password=$self->{'password'}&to=@{[join(",", @phone)]}&from=$from&text=$msg);

  $DEBUG and warn "Website::Utilities::SMS::send $url\n";
  
  my $response = &get($url);

  if(defined($response)) {
    if($response =~/ERR:(.*)/) {
      warn "Error from SMS service $1\n";
    } elsif($response =~ /ID:(.*)/) {
      return "Message sent with ID $1\n";
    }
  } else {
    warn "Error from LWP\n";
  }
}

1;
