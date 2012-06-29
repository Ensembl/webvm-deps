#########
# Author:        rmp
# Maintainer:    rmp
# Last Modified: 10-Nov-2008
#
# decoration for (www|dev).eucomm.org
#
package SiteDecor::eucomm;
use strict;
use warnings;
use Sys::Hostname;
use YAML;
use base qw(SiteDecor);

our $VERSION = do { my @r = ( q$Revision: 6.19 $ =~ /\d+/gmx ); sprintf '%d.' . '%03d' x $#r, @r };

sub init_defaults {
  my $self = shift;
  my $def  = {
    "stylesheet"     => [ "http://$ENV{'HTTP_X_FORWARDED_HOST'}/css/eucomm.css", "http://$ENV{'HTTP_X_FORWARDED_HOST'}/css/eucomm-print.css" ],
    "redirect_delay" => 5,
    "bannercase"     => 'ucfirst',
    "author"         => 'webmaster',
    "decor"          => 'full',
    "title"          => 'European Conditional Mouse Mutagenesis Program',
    "jsfile"         => ['http://js.sanger.ac.uk/urchin.js'],
  };
  $self->merge($def);
}

sub create_menu {
  my ( $self, $entry ) = @_;
  my $output = '';

  while ( ( my $key, my $value ) = each %{$entry} ) {

    if ( ref $value eq 'HASH' ) {

      if   ( $value->{'class'} ) { $output .= qq(<li class="$value->{'class'}">); }
      else                       { $output .= qq(<li>); }

      if   ( $value->{'link'} ) { $output .= qq(<a href="$value->{'link'}">$key</a>); }
      else                      { $output .= qq(<span>$key</span>); }

      if ( $value->{'sub'} ) {
        $output .= qq(\n<ul>\n);
        for my $sub ( @{ $value->{'sub'} } ) { $output .= $self->create_menu($sub); }
        $output .= qq(</ul>\n);
      }

      $output .= qq(</li>\n);
    }
    else {
      $output .= qq(<li><a href="$value">$key</a></li>\n);
    }
  }
  return $output;
}

sub html_headers {
  my $self   = shift;
  my $title  = $self->title();
  my $jsfile = $self->jsfile() || undef;

  my ($hostname) = ( hostname() ) =~ /^([^\.]+)/mx;

  my $html_headers = qq[
    <!-- version: $VERSION -->
    <!-- host: $hostname -->
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>$title &bull; EUCOMM</title>
          <meta http-equiv="content-type" content="text/html; charset=utf-8" />
          <meta name="author" content="Wellcome Trust Sanger Institute" />
          <meta name="description" content="The EUCOMM integrated project is funded by the European Union Framework 6 programme. The goal of EUCOMM is to generate collection of up to 20,000 mutated genes in mouse embryonic stem (ES) cells using conditional gene trapping and gene targeting approaches." />
          <meta name="keywords" content="EUCOMM,mouse mutants,gene trap,ES cells,EURExpress,EMAGE,PRIME,FunGenEs,EUMORPHIA,EMMA" />
          
          <link rel="icon" href="http://www.eucomm.org/favicon.ico" type="image/x-icon" />
          <link rel="shortcut icon" href="http://www.eucomm.org/favicon.ico" type="image/x-icon" />
  ];

  $html_headers .= q[
          <!-- CSS: Base Stylesheet -->
          <link rel="stylesheet" href="/css/yui-reset-fonts-base.css" type="text/css" media="all" charset="utf-8" />
          
          <!-- CSS: Screen Stylesheets -->
          <link rel="stylesheet" href="/htgt/static/css/common.css" type="text/css" media="screen, projector" charset="utf-8" />
          <link rel="stylesheet" href="/css/eucomm.css" type="text/css" media="screen, projector" charset="utf-8" />
          <link rel="stylesheet" href="/css/jquery.treeview.css" type="text/css" media="screen, projector" charset="utf-8" />
          <!--[if IE]>
            <link rel="stylesheet" href="/css/eucomm-ie.css" type="text/css" media="screen, projector" charset="utf-8" />
          <![endif]-->
          
          <!-- CSS: Print Stylesheet -->
          <link rel="stylesheet" href="/css/eucomm-print.css" type="text/css" media="print" charset="utf-8" />
          
          <!-- JS: Prototype -->
          <script src="/htgt/static/javascript/prototype.js" type="text/javascript" charset="utf-8"></script>
          <script src="/htgt/static/javascript/scriptaculous.js?load=effects" type="text/javascript" charset="utf-8"></script>
          <script src="/htgt/static/javascript/tablekit.js" type="text/javascript" charset="utf-8"></script>
          <script src="/htgt/static/javascript/validation.js" type="text/javascript" charset="utf-8"></script>
          <script src="/htgt/static/javascript/htgt.js" type="text/javascript" charset="utf-8"></script>
          
          <!-- JS: jQuery -->
          <script src="/javascript/jquery-1.2.6.min.js" type="text/javascript" charset="utf-8"></script>
          <script type="text/javascript" charset="utf-8">
            //<![CDATA[
              jQuery.noConflict();
            //]]>
          </script>
          <script src="/javascript/jquery.treeview.min.js" type="text/javascript" charset="utf-8"></script>
  ];

  if (@$jsfile) {
    $html_headers .= join( "\n", map { qq[<script type="text/javascript" charset="utf-8" src="$_" ></script>\n] } @$jsfile );
  }

  $html_headers .= qq[
        </head>
        <body>
          <div id="doc3" class="yui-t2">
            <div id="hd">
              <div id="nav-search" class="yui-g">
                <div class="yui-u first">
                  <ul id="header-navigation">
  ];

  eval {
    my $nav_conf = YAML::LoadFile( $ENV{'DOCUMENT_ROOT'} . '/header_footer_menu.yml' );
    for my $entry ( @{$nav_conf} ) { $html_headers .= $self->create_menu($entry); }
  };
  if ($@) {
    warn "Header Nav Problems : $@";
  }

  $html_headers .= qq[
                  </ul>
                </div>
                <div class="yui-u">
                  <fieldset>
                    <form id="gene_search" method="get" action="http://www.knockoutmouse.org/search_results">
                      <p>
                        <input class="default-value" type="text" id="gene_name" name="criteria" value="Search for a gene or product" />
                      </p>
                    </form>
                  </fieldset>
                </div>
              </div>
              <h1><a href='/'><img src="/images/header.png" alt="European Conditional Mouse Mutagenesis Program" /></a></h1>
            </div>
            <div id="bd">
              <div id="side-navigation-div">
                <ul id="side-navigation" class="treeview">
  ];

  eval {
    my $sidebar_conf = YAML::LoadFile( $ENV{'DOCUMENT_ROOT'} . '/sidebar_menu.yml' );
    for my $entry ( @{$sidebar_conf} ) { $html_headers .= $self->create_menu($entry); }
  };
  if ($@) {
    warn "Sidebar Problems : $@";
  }

  $html_headers .= qq[
                </ul>
              </div>
              <div id="yui-main">
                <div id="content" class="yui-b">
                  <div class="yui-g">
                    <div id="site_wide_search_results"></div>
                    <div id="naked_content">
  ];

  return $html_headers;
}

sub site_footers {
  my $self    = shift;
  my $lastmod = "";
  my $req_uri = $ENV{'REQUEST_URI'} || "";

  if ( $ENV{'LAST_MODIFIED'} ) {
    $lastmod = qq(Last Modified $ENV{'LAST_MODIFIED'});
  }
  else {
    #########
    # Look for the request_uri document
    #
    my ($fn) = "$ENV{'DOCUMENT_ROOT'}/$req_uri" =~ m|([a-z\d\./_]+)|i;

    #########
    # If that doesn't exist try the script_filename
    #
    if ( $fn && !-e $fn ) {
      ($fn) = $ENV{'SCRIPT_FILENAME'} || "" =~ m|([a-z\d\./_]+)|i;
    }

    if ( $fn && -e $fn ) {
      my ($mtime) = ( stat($fn) )[9];
      my $scriptstamp = localtime($mtime);
      $lastmod = qq(Last Modified $scriptstamp) if ( defined $scriptstamp );
    }
  }

  my $footer = qq[
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div id="ft">
              <span id="last-modified">$lastmod</span>
              <ul id="footer-navigation">
  ];

  eval {
    my $nav_conf = YAML::LoadFile( $ENV{'DOCUMENT_ROOT'} . '/header_footer_menu.yml' );
    for my $entry ( @{$nav_conf} ) { $footer .= $self->create_menu($entry); }
  };
  if ($@) {
    warn "Footer Nav Problems : $@";
  }

  $footer .= qq[
              </ul>
              <span id="copyright">&copy; 2008, EUCOMM Project</span>
            </div>
          </div>
          <script src="/javascript/eucomm.js" type="text/javascript" charset="utf-8"></script>
          <script type="text/javascript">
            _userv=0;
            urchinTracker();
          </script>  
        </body>
      </html>
  ];

  return $footer;

}

1;
