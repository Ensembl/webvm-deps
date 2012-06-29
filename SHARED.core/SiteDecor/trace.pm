package SiteDecor::trace;
use strict;
use warnings;
use base qw(SiteDecor);
use Sys::Hostname;

sub init_defaults {
  my $self = shift;
  my $def  = {
	      "stylesheet"     => ['/content.css','/ensembl.css'],
	      "redirect_delay" => 5,
	      "bannercase"     => 'ucfirst',
	      "author"         => 'webmaster',
	      "decor"          => 'full',
	     };
  $self->merge($def);
  return;
}


sub site_headers {
  my $self = shift;
  my $site_header = qq(
  <div id="masthead">
   <h1><a href="/"><img src="/img/e-bang.gif" style="width: 46px; height: 40px; vertical-align:bottom; border:0px; padding-bottom:2px" alt="" title="Home" /></a><a href="/" class="home serif">Ensembl</a> <a href="/" class="section">Trace Server</a></h1>
  </div>
  <div id="search">
   <form action="/perl/traceview" method="get" name="traceform" style="font-size: 0.9em">
    <div>Find trace: <input name="traceid" size="24" value="" /><input type="submit" value="Go" class="red-button" /></div>
   </form>
   <p class="right" style="margin-right:1em; font-size: 0.9em">e.g. <a href="/perl/traceview?traceid=ml1B-a1798c05.q1c">ml1B-a1798c05.q1c</a>, <A href="/perl/traceview?traceid=GTMZP1D038*">GTMZP1D038*</a></p>
  </div>
  <div id='page'>
    <div id='i1'>
      <div id='i2'>
        <div class='sptop'>&nbsp;</div>);

  return $site_header;
}

sub site_footers {
  my $self = shift;
  my $title = $self->{'title'}||"Trace Server";   
  return qq(<div class='sp'>&nbsp;</div>
            </div>
           </div>
          </div>
          <div id='release'>&nbsp;</div>                      
          <div id="release-t">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</div>
          <div id="related">
            <div id="related-box">
              <h2>$title</h2>
                <ul>
                  <li class="bullet"><a href="/">Home page</a></li>
                  <li class="bullet"><a href="/perl/traceview?stats=1">View trace statistics</a></li>
                  <li class="bullet"><a href="/cgi-bin/tracesearch">Search trace sequences</a></li>
                  <li class="bullet"><a href="ftp://ftp.ensembl.org/pub/traces">Download traces (FTP)</a></li>
                </ul>
                <br/><br/>
                <h2>Links</h2>
                <ul>
                  <li class="bullet"><a href="http://www.ensembl.org">Ensembl</a></li>
                  <li class="bullet"><a href="http://www.ncbi.nlm.nih.gov/Traces/">NCBI trace archive</a></li>
                </ul>
                <h2 style="padding:4px; margin-top: 2em">
                  <a href="http://www.sanger.ac.uk/"><img style="padding-left:15px" src="/img/wtsi_rev.png" width="98" height="30" alt="The Wellcome Trust Sanger Institute" title="The Wellcome Trust Sanger Institute" /></a><a href="http://www.ebi.ac.uk/"><img style="padding-left:15px" src="/img/ebi.gif" width="45" height="30" alt="The European Bioinformatics Institute" title="The European Bioinformatics Institute" /></a></h2>
              </div>
            </div>
          </body>
        </html>);
}

sub doc_type {
  return q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">);
}

1;
