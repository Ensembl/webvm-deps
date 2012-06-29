#########
# Author:        jc3
# Maintainer:    $Author: jc3 $
# Created:       2006-10-10
# Last Modified: $Date: 2009-04-09 10:38:31 $
#
package Website::Feedback;

use strict;
use warnings;
use SangerPaths qw(core);
use Website::Utilities::Mail;
use Website::Utilities::TimeSpan;
use Website::StopWords qw($STOPWORDS);
use Website::StopIPs;
use Website::SSO::User;
use SangerWeb;

our $VERSION          = do { my @r = (q$Revision: 1.36 $ =~ /\d+/g); sprintf '%d.'.'%03d' x $#r, @r };
our $EMAIL_CONF_ERROR = 'Your email addresses do not match. Please try again.';
our $EMAIL_BLANK_ERROR = 'Your email address is missing. Please try again.';
our $STOP_WORDS_ERROR = 'Your submission contained black-listed words. Please try again.';
our $STOP_IPS_ERROR   = 'Your submission is from a black-listed host. Please email webmaster@sanger.ac.uk directly.';

sub new {
  my ($class,$cgi) = @_;
  die 'CGI object required, see POD' if (ref $cgi ne 'CGI');
  my $self = {
	      'cgi' => $cgi,
	     };
  bless $self, $class;
  return $self;
}

sub form {
  my ($self) = @_;
  my $cgi    = $self->{'cgi'};
  my $dev    = $ENV{'dev'} || '';
  my $sw     = SangerWeb->new();  
  my $email  = $cgi->escapeHTML($cgi->param('mail')) || q{};
  my $e_conf = $cgi->escapeHTML($cgi->param('e_conf')) || q{}; 
  if($email eq '' && $sw->username()) {
      $email = Website::SSO::User->new({'username'=>$sw->username()})->email();
      $e_conf = $email      
  }
    
  my $output = qq(
        <script type="text/javascript" src="http://js$dev.sanger.ac.uk/forms.js" ></script>
        <style type="text/css">
         <!--
          .clear {
            display:none;
           }
         -->  
        </style>
	<form action="$ENV{'SCRIPT_NAME'}" method="POST" onsubmit="return compare('mail','e_conf','$EMAIL_CONF_ERROR');">
    <input type="hidden" name="referrer" value="@{[$cgi->escapeHTML($cgi->param('referrer')||$ENV{'HTTP_REFERER'}||'')]}" />
    <div id="warning"></div>
    <table align="center" border="0" cellpadding="0" cellspacing="0" class="violet1">
     <tr valign="top">
       <td class="barial">Your Name</td>
       <td><input type="entry" name="name" size="40" value="@{[$cgi->escapeHTML($cgi->param('name')||'')]}" /></td>
     </tr>
     <tr valign="top">
       <td class="barial">Your Email</td>
       <td><input type="entry" id="mail" name="mail" size="40" value="$email" /></td>
     </tr>
     <tr valign="top">
       <td class="barial">Confirm Email</td>
       <td><input type="entry" id="e_conf" name="e_conf" size="40" value="$e_conf" /></td>
     </tr>
      <tr valign="top">
        <td class="barial">Problem / Query</td>
        <td>
	 <select name="problem" size="1">);
  my @problem_options = ('Select problem type (if appropriate)',
	                 'Broken database',
	                 'Broken link',
	                 'Broken script',
	                 'ftp problem',
	                 'Problematic URL',
	                 'Typographical / content error',
	                 'Other');
  for my $option (@problem_options) {
    my $problem = $cgi->escapeHTML($cgi->param('problem')) || '';
    my $selected = ($option eq $problem)?'selected="selected"':'';
    $output .= qq(<option $selected>$option</option>);
  }
  $output .= qq(</select>
        </td>			
      </tr>
      <tr valign="top">
        <td class="barial">Details / Comments<br />
	  <font color="#000080"><i>Please cut and paste<br />
	  any diagnostic report,<br />
	  which may have<br />
	  been generated<br />
	  automatically, into<br />
	  this field</i></font></td>
        <td><textarea name="comments" cols="40" rows="10">@{[$cgi->escapeHTML($cgi->param('comments')||"Type information here")]}</textarea></td>
      </tr>
      <tr>
       <td><label name="email" class="clear">Please leave this field blank</label></td>
       <td><input type="entry" class="clear" id="email" name="email" size="40" value="@{[$cgi->escapeHTML($cgi->param('email')||'')]}" /></td>
      </tr>
      <tr valign="top">
        <td colspan="2" align="center">
	  <button type="submit" >Submit</button>
	  <button type="reset" >Clear</button>
        </td>
      </tr>
    </table>
    <input type="hidden" name="action"  value="mail" />
    <input type="hidden" name="subject" value="@{[$cgi->escapeHTML($cgi->param('subject')||$ENV{'feedback_subject'}||'')]}" />
    <input type="hidden" name="return"  value="@{[$cgi->escapeHTML($cgi->param('return')||$ENV{'feedback_return'}||'')]}" />
    <input type="hidden" name="to" value="@{[$cgi->escapeHTML($cgi->param('to')||$ENV{'feedback_to'}||'')]}" />
    <input type="hidden" name="status" value="@{[$cgi->escapeHTML($cgi->param('status')||$ENV{'REDIRECT_STATUS'}||'')]}" />
    <input type="hidden" name="request_uri" value="@{[$cgi->escapeHTML($cgi->param('request_uri')||$ENV{'REQUEST_URI'}||'')]}" />
  </form>);
  return $output; 
}


sub mail {
  my ($self) = @_;
  my $cgi         = $self->{'cgi'};
  my $date        = Website::Utilities::TimeSpan->new->seed();
  my $stopips     = Website::StopIPs->new();
  my $name        = $cgi->param('name')        || '';
  my $email       = $cgi->param('mail')        || '';
  my $conf_email  = $cgi->param('e_conf')      || '';
  my $referrer    = $cgi->param('referrer')    || '';
  my $status      = $cgi->param('status')      || '';
  my $problem     = $cgi->param('problem')     || '';
  my $comments    = $cgi->param('comments')    || '';
  my $spam        = $cgi->param('email')       || undef;
  my $subject     = $self->mail_subject();
  my $ua          = $ENV{'HTTP_USER_AGENT'}    || 'unknown user agent';
  my $request_uri = $cgi->param('request_uri') || 'unknown request uri';
  my $remoteaddr  = (defined $ENV{'HTTP_X_FORWARDED_FOR'} && $ENV{'HTTP_X_FORWARDED_FOR'} eq 'unknown')?($ENV{'REMOTE_ADDR'} || 'unknown'):($ENV{'HTTP_X_FORWARDED_FOR'} || '');

  my $host = $ENV{'HTTP_HOST'} || "unknown";
  my $uri  = $ENV{'REQUEST_URI'} || $ENV{'DOCUMENT_URI'} || "/unknown";
  
  my $localaddress = "${host}${uri}";
  
  if ($email ne $conf_email) {
     return ['ERROR',qq($EMAIL_CONF_ERROR\n)];
  }

  if ($email eq '') {
    return ['ERROR',qq($EMAIL_BLANK_ERROR\n)];
  }

  my $stopwords = join('|', @$STOPWORDS);
  if($subject =~ /$stopwords/smi ||
      $comments =~ /$stopwords/smi) {
    return ['ERROR', qq($STOP_WORDS_ERROR\n)];
  }

  if($stopips->blacklisted($remoteaddr)){
    return ['ERROR', qq($STOP_IPS_ERROR\n)];
  }

  if ($spam) {
    $subject = qq([SPAM]).$subject;
  }

  my $redirect = $cgi->param('return');
  my $mailto   = $self->mailto();
  my $message  = qq(Date:            $date
Name:            $name
Email:           $email
Referrer:        $referrer
Status code:     $status
Problem:         $problem
User_agent:      $ua
Request URI:     $host$request_uri
Remote Address:  $remoteaddr
Submitted From:  $localaddress
Comments:
$comments
);

  my $mail = new Website::Utilities::Mail({
					   'to'      => $mailto,
					   'from'    => (defined $email && $email =~ /\@/)?$email:undef,
					   'subject' => $subject,
					   'message' => $message,
					  });

  eval {
   $mail->send();
  };

  if($@) {
    return ['ERROR','<p>There was a problem submitting your feedback.<br /> Please email <a href="mailto:webmaster@sanger.ac.uk">webmaster@sanger.ac.uk</a></p>'];
  }

  #########
  # if we don't have a 'return' variable set, then process the 
  # HTTP_REFERRER to kick us back to the previous page.
  #
  if (!defined $redirect || $redirect eq '') {
    $redirect = $ENV{'HTTP_REFERER'};
  }
  return ['REDIRECT',$redirect];
}

sub mailto {
  my ($self) = @_;
  my $cgi    = $self->{'cgi'};
  my $mailto = $ENV{'SERVER_ADMIN'};
  $mailto    = $cgi->param('to') if ($cgi->param('to') ne '');

  return $mailto;
}

sub mail_subject {
  my ($self)  = @_;
  my $cgi     = $self->{'cgi'};
  my $subject = $cgi->param('subject') || 'Default Subject';
  return $subject;
}


1;

=pod

=head1 NAME

Website::Feedback

=head1 VERSION

This document describes version $Revision: 1.36 $ released on $Date: 2009-04-09 10:38:31 $.

=head1 SYNOPSIS

use Website::Feedback;

my $feedback = Website::Feedback->new($cgi);

# print a form for input
print $feedback->form();

# or send an e-mail from the input
my $result = $feedback->mail();


=head1 DESCRIPTION

This module is used to create a common form and mailer for the various locations where feedback is required. It can be included in any cgi script which needs to send feedback to sanger.

=head1 METHODS

=over 4

=item new()

 Function: feedback object Constructor 

 Args: requires a CGI object

 Returns: feedback object

 Example: my $feedback = Website::Feedback->new($cgi);

=item form()

 Function: Creates and returns an html feedback form to 
           allow a user to submit their problem.

 Args: none

 Returns: scalar containing the feedback html.

 Example: print $feedback->form();

=item mail()

 Function: Sends an e-mail to the appropriate recipient and provides
           a redirect. If there is a failure an error message is returned

 Args: none

 Returns: [STATUS_CODE,STRING]

  STATUS_CODE can be either ERROR || REDIRECT
  STRING will be an error message if STATUS_CODE is ERROR and a redirect url if STATUS_CODE is REDIRECT.
 
 Example: my $result = $feedback->mail();

=back

=head1 DEPENDENCIES

requires the javascript found at http://js.sanger.ac.uk/forms.js for the in browser form validation to work.

=over 4

=item strict

=item warnings

=item Website::Utilities::Mail

=item Website::Utilities::TimeSpan

=item Website::StopWords 

=back

=head1 AUTHOR

Jody Clements (jc3@sanger.ac.uk)

=head1 MAINTAINER

$Author: jc3 $

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006 Wellcome Trust Sanger Institute. All rights reserved.
 
 This module is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself. See L<perlartistic>.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

=cut
