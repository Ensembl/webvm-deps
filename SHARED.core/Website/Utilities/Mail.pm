#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2001
# Last Modified: $Date: 2009/01/20 17:06:17 $ $Author: jc3 $
# Source:        $Source $
#
package Website::Utilities::Mail;
use strict;
use warnings;
use Website::Utilities::MIME;
use MIME::Lite;
use English qw(-no_match_vars);
use Carp;

our $VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $DOMAIN  = '@sanger.ac.uk';

sub new {
  my ($class, $ref) = @_;
  $ref            ||= {};
  $ref->{'from'}  ||= "w3adm$DOMAIN";

  bless $ref, $class;
  return $ref;
}

sub send {
  my ($self)          = @_;
  my $headers         = {};
  my $from            = ($self->{'from'} =~ /\@/mx)?$self->{'from'}:"$self->{'from'}$DOMAIN";
  $ENV{'MAILADDRESS'} = $self->{'from'};

  for my $header (qw(to cc bcc attachments)) {
    if(ref($self->{$header}) eq 'ARRAY') {
      push @{$headers->{$header}}, @{$self->{$header}};

    } elsif(defined $self->{$header} && !ref($self->{$header}) && $self->{$header}) {
      push @{$headers->{$header}}, $self->{$header};
    }
  }

  #########
  # mpack attachments
  #
  my $mime     = Website::Utilities::MIME->new();
  my $path     = $ENV{'PATH'};
  $ENV{'PATH'} = '/bin:/usr/bin:/usr/sbin:/usr/lib';
  MIME::Lite->send('smtp', 'localhost', Timeout=>30);

  #########
  # append domainname if not present
  #
  for my $header (qw(to cc bcc)) {
    $headers->{$header} = [map { ($_ =~ /\@/mx)?$_:"$_$DOMAIN"; } @{$headers->{$header}}];
  }

  $self->{'mailer'} = MIME::Lite->new(
				      From     => $from,
				      To       => (join ', ', @{$headers->{'to'}}),
				      Cc       => (join ', ', @{$headers->{'cc'}}),
				      Bcc      => (join ', ', @{$headers->{'bcc'}}),
				      Subject  => $self->{'subject'},
				      Type     => 'multipart/mixed',
				      Encoding => 'binary',
				     );
  $self->{'mailer'}->attach(
			    Type => 'TEXT',
			    Data => $self->{'message'},
			   );

  if ($self->{'html_message'}) {
    $self->{'mailer'}->attach(
                              Type => 'text/html',
			      Data => $self->{'html_message'},
			     );
  }

  if ($self->{'HTML_message'}) {
    $self->{'mailer'}->attach(
            Type => 'text/html',
            Data => $self->{'HTML_message'},
           );
  }

  my $totalsize = 0;

  for my $fn (@{$headers->{'attachments'}}) {
    my $fsize   = -s $fn;
    $totalsize += $fsize;

    if($totalsize < 4_000_000) {
      $self->{'mailer'}->attach(
				Type        => $mime->by_suffix($fn),
				Path        => $fn,
				Disposition => 'attachment',
			       );
    } else {
      carp qq(Attachment $fn too large (greater than 4Mb));
      $totalsize -= $fsize;
    }
  }

  eval {
    $self->{'mailer'}->send();
  };
  if($EVAL_ERROR) {
    print {*STDERR} qq(MIME::Lite failed to send message:\n), $self->{'mailer'}->as_string;
    croak $EVAL_ERROR;
  }
  $ENV{'PATH'} = $path||q();

  return 1;
}

sub as_string {
  my $self = shift;
  if($self->{'mailer'}) {
    return $self->{'mailer'}->as_string();
  }

  warn q(as_string is only available after 'send');
  return q();
}

1;

=pod

=head1 NAME

Website::Utilities::Mail

=head1 VERSION

This document describes version $Revision: 1.7 $ released on $Date: 2009/01/20 17:06:17 $.

=head1 SYNOPSIS
 
 use Website::Utilities::Mail
 my $mail = Website::Utilities::Mail->new({
                                           'to'      => 'user@example.com',
                                           'from'    => 'another@foo.com',
                                           'subject' => "Example Mail",
                                           'message' => q(My really long message goes here.),
                                          });

 $mail->send();                                          


=head1 DESCRIPTION

Website::Utilities::Mail is used to send MIME mail messages. It performs 
some error checking and convience functions not ususaly found in the standard
MIME modules.

=head1 METHODS

=over 4

=item new() - Returns a Website::Utilities::Mail object initalised with the given parameters   

Args: 'to'           = email address the message is sent to
      'from'         = email address of the sender 
      'subject'      = text that will appear in the subject line of the message
      'message'      = the text that will appear in the body of the email
      'html_message' = html email message that can be attached

 my $mail = Website::Utilities::Mail->new();      


=item send() - Sends the message to the recipient(s).

 $mail->send();

=item as_string() - Returns the message as a string for use elsewhere.

This method will only work if called after the send method has been called

 my $message = $mail->as_string

=back

=head1 DEPENDENCIES

=over 4

=item Website::Utilities::MIME

=item MIME::Lite

=item English 

=item Carp

=back

=head1 AUTHOR

Roger Pettett (rmp@sanger.ac.uk)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008 Wellcome Trust Sanger Institute. All rights reserved.
 
 This module is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself. See L<perlartistic>.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

=cut
