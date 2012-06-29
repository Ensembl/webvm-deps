package Website::Feedback::ErrorHandler;

use strict;
use warnings;
use base qw(Website::Feedback);

sub user_expired {
  my ($self) = @_;
  my $output = qq(
<p>
  This user page no longer exists.
  Please try searching on one of the following search engines:
</p>
<ul>
   <li><a href="http://search.sanger.ac.uk/">http://search.sanger.ac.uk/</a></li>
   <li><a href="http://www.google.com/">http://www.google.com/</a></li>
   <li><a href="http://www.altavista.com/">http://www.altavista.com/</a></li>
</ul>
  );
  return $output;
}

sub fixblast {   
  my ($self) = @_;
  if($ENV{'REQUEST_URI'} =~ m|^/Projects/(.*?)(/Toolkit2?)?/(adv)?blast_server\.shtml$|) {
    my $project = lc($1);
    my $toolkit = $2||"";
    my $omni    = ($toolkit eq "/Toolkit")?"/omni":"";

    print qq(Status: 301 Moved Permanantly\nLocation: http://$ENV{'HTTP_X_FORWARDED_HOST'}/cgi-bin/blast/submitblast/$project$omni\n\n);
    warn "Fixing blast request (redirecting to): http://$ENV{'HTTP_X_FORWARDED_HOST'}/cgi-bin/blast/submitblast/$project$omni\n"; 
    return 1;
  }
}

sub errstr {
  my ($self,$errno) = @_;   
  return {
          '201' => 'Created',
          '202' => 'Accepted',
          '203' => 'Non-Authoritative',
          '204' => 'No Content',
          '205' => 'Reset Content',
          '206' => 'Partial Content',
          '300' => 'Multiple Choices',
          '301' => 'Moved Permanently',
          '302' => 'Moved Temporarily',
          '303' => 'See Other',
          '304' => 'Not Modified',
          '305' => 'Use Proxy',
          '400' => 'Bad Request',
          '401' => 'Unauthorized',
          '402' => 'Payment Required',
          '403' => 'Forbidden',
          '404' => 'Not Found',
          '405' => 'Method Not Allowed',
          '406' => 'Not Acceptable',
          '407' => 'Proxy Authentication Required',
          '408' => 'Request Time-out',
          '409' => 'Conflict',
          '410' => 'Gone',
          '411' => 'Length Required',
          '412' => 'Precondition Failed',
          '413' => 'Request Entity Too Large',
          '414' => 'Request URI Too Long',
          '415' => 'Unsupported Media Type',
          '500' => 'Internal Server Error',
          '501' => 'Not Implemented',
          '502' => 'Bad Gateway',
          '503' => 'Service Unavailable',
          '504' => 'Gateway Time-out',
          '505' => 'HTTP Version not supported',
         }->{$errno};
}

sub form {
  my ($self) = @_;
  my $output = qq(
<br />

<table width="90%" cellspacing="0" cellpadding="5" align="center">
  <tr  valign="top">
    <td>
      <p>The Sanger Institute website provides a site search service. If
	you cannot find the page you are looking for please try a site
	search below. It would help us if you would inform us when you
	find a "404 error: file not found" by completing the lower
	form so that we can correct the problem. Also please submit
	your name and email address so that we can email you the
	correct / updated URL you are seeking.</p>
      <p>Finally please remember that URLs are case sensitive.  Ensure
        you have typed in the URL exactly as written.</p>
      <p>(i.e. http://www.sanger.ac.uk/Software/<span class="red1">P</span>fam
	<i>will return a page whilst</i>
	http://www.sanger.ac.uk/Software/<span
	class="red1">p</span>fam will not.)</p>
    </td>
  </tr>
</table>
<br />\n);
  $output .= $self->search_form();
  $output .= qq(<div id="feedbackform">
    <fieldset>
      <legend>User Feedback</legend>);
  $output .= $self->SUPER::form();
  $output .= q(</fieldset></div>); 
  return $output;
}

sub search_form {
  my ($self) = @_;
  return qq(
<div id="searchform">
 <fieldset>
  <legend>Search</legend>
  <form action="http://search.sanger.ac.uk/cgi-bin/exasearch" name="sitesearch" method="get">
   <a href="http://search.sanger.ac.uk/cgi-bin/exasearch">
    <img src="http://www.sanger.ac.uk/gfx/wtsi-logo.png" alt="Wellcome Trust Sanger Institute"/>
   </a>
   <input type="text"   name="_q" value="" size="18" maxlength="100" id="q" />
   <input type="hidden" name="_l" value="en" />
   <input type="hidden" name="_options" value="0" />
   <button type="submit">Search</button>
  </form>
 </fieldset>
</div>
<br/>);
}

sub mail_subject {
  my ($self) = @_;
  my $cgi = $self->{'cgi'};
  my $problem = $cgi->param('problem') || "Error";
  my $subject = "SANGER website - $problem";
  return $subject;
}

sub thank_you {
  my ($self) = @_;
  my $response = qq(<center>
  <p>The form was submitted successfully.</p>
  <p>We will get back to you as soon as possible.</p>
  <p>The Sanger Institute Web Team</p>
  </center>);
  $response .= $self->search_form();
  return $response;
}

1;
