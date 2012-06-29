#########
# Author: rmp
#
package SiteDecor::external;
use strict;
use warnings;
use base qw(SiteDecor);
use Sys::Hostname;

sub init_defaults {
  my $self      = shift;
  my $sangerurl = "http://www.sanger.ac.uk";
  $sangerurl    = "http://wwwdev.sanger.ac.uk" if($self->is_dev());
  my $def       = {
		   "drp"            => qq(<a class="headerinactive" href="$sangerurl/Projects/release-policy.shtml">Data Release Policy</a>),
		   "cou"            => qq(<a class="headerinactive" href="$sangerurl/Projects/use-policy.shtml">Conditions of Use</a>),
		   "phogolink"      => "/",
		   "title"          => "No Title",
		   "icon"           => "helix.gif",
		   "stylesheet"     => "$sangerurl/stylesheets/stylesheet.css",
		   "redirect_delay" => 5,
		   "bannercase"     => 'ucfirst',
		   "author"         => 'webmaster',
		   "decor"          => 'full',
		   'headerimg'      => "/gfx/header/wtsi-phogo-summer.jpg",
		   'headeralt'      => "Wellcome Trust Sanger Institute Home",
		   'navbar1'        => [
					{"Sanger Home"  => "$sangerurl/",},
					{"Acedb"        => "http://www.acedb.org/",},
					{"YourGenome"   => "http://www.yourgenome.org/",},
					{"Ensembl"      => "http://www.ensembl.org/",},
					{"Trace Server" => "http://trace.ensembl.org/",},
					{"Library"      => "http://library.sanger.ac.uk/",},
				       ],
		  };
  
  
  if(defined $ENV{'hinxuser'} && $ENV{'REQUEST_URI'} =~ /^\/campus/) {
    $def->{'navbar2'} = [
			 {"Hinxton Hall" => "http://www.hinxton.wellcome.ac.uk/",},
			 {"EBI"          => "http://www.ebi.ac.uk/",},
			 {"SSC"          => "$sangerurl/campus/ssc/",},
			 {"Sports"       => "$sangerurl/campus/sports/",},
			 {"Travel"       => "$sangerurl/campus/travel/",},
			 {"Safety"       => "$sangerurl/campus/safety/",},
			];
  } else {
    $def->{'navbar2'} = [
			 {"Info"              => "/Info/",},
			 {"Databases"         => "/DataSearch/databases.shtml",},
			 {"Blast"             => "/DataSearch/",},
			 {"Genomics"          => "/genetics/",},
			 {"Infrastructure"    => "/infrastructure/",},
			 {"HGP"               => "/HGP/",},
			 {"CGP"               => "/CGP/",},
			 {"Projects"          => "/Projects/",},
			 {"Software"          => "/Software/",},
			 {"Teams"             => "/Teams/",},
			 {"Search"            => "http://search.sanger.ac.uk/",},
			];
  }

  if(defined $ENV{'HTTP_X_FORWARDED_HOST'} && $ENV{'HTTP_X_FORWARDED_HOST'} =~ /acedb\.org/) {
    $def->{'headerimg'} = "/gfx/header/phogo.gif" 

  } elsif(defined $ENV{'hinxuser'} && $ENV{'REQUEST_URI'} =~ /^\/campus/) {
    $def->{'headerimg'} = "/gfx/header/wtgc.jpg";

  } elsif($self->server_name() =~ /(wwwdev|spider)/) {
    $def->{'headerimg'} = "/gfx/header/wtsi-phogo-dev.jpg";
    $def->{'headeralt'} = "WTSI Development Server Home";

  } else {
    #########
    # fix up header image according to day/month/season
    #
    my $month = (localtime())[4];
    if($month < 3 || $month >= 11) {
      $def->{'headerimg'} = "/gfx/header/wtsi-phogo-winter.jpg";
    }
  }

  #########
  # User-page acceptable-use policy
  # this is covered by the mod-perl User-page handler but might as well go in for 404s etc with the standard header
  #
  my $ru = $ENV{'REQUEST_URI'}||"";
  if($ru =~ /Users/) {
    $def->{'drp'} = "";

    my $aup = "disclaimer-external.shtml";
    if($ENV{'localuser'}) {
      $aup = "disclaimer-internal.shtml";
    }

    $def->{"cou"} = qq(<a class="headerinactive" href="$sangerurl/AUP/$aup">Acceptable Use Policy</a>);
  }

  #########
  # if the visitor is local but not an Altavista indexer
  #
  if($ENV{'localuser'} && $ENV{'HTTP_USER_AGENT'} !~ /AltaVista|AVSearch|linkchimp/i) {
    unshift @{$def->{'navbar1'}}, {"Intranet" => "http://intweb.sanger.ac.uk/"};
    unshift @{$def->{'navbar1'}}, {"Dev Site" => "http://wwwdev.sanger.ac.uk/"};
  }

  return $def;
}

sub title {
  my $self = shift;
  return qq(The Sanger Institute: ) . $self->SUPER::title(@_);
}

sub site_menu { ""; }

sub site_headers {
  my $self         = shift;
  my $server_name  = $self->server_name();
  my $site_headers = "";

  if($self->{'decor'} eq "full") {
    #########
    # Phogotext contains the linked left-hand photo + logo
    #
    my $phogotext = qq(<a href="$self->{'phogolink'}"><img src="$self->{'headerimg'}" alt="$self->{'headeralt'}" border="0" vspace="0" /></a>\n);
    
    #########
    # fix up first navigation bar (servers)
    #
    my @navbar1;
    
    foreach my $ref (@{$self->{'navbar1'}}) {
      my $key = (keys %{$ref})[0];
      my $val = $ref->{$key};
      
      my $active = "in";

      if($val =~ /$server_name/i) {
	$active = "";
	$val    = "/";
      }

      push @navbar1, qq(<a class="header${active}active" target="_top" href="$val">$key</a>);
    }
    my $navbar1text = join('&nbsp;|&nbsp;', @navbar1);
    
    #########
    # fix up second navigation bar (TLDs)
    #
    my @navbar2;
    foreach my $ref (@{$self->{'navbar2'}}) {
      my $key = (keys %{$ref})[0];
      my $val = $ref->{$key};
      
      my $active;
      
      if(substr($ENV{'REQUEST_URI'}, 0, length($val)) eq $val) {
	$active = "";
      } else {
	$active = "in";
      }
      if($val) {
	push @navbar2, qq(<a class="header${active}active" target="_top" href="$val">$key</a>);
      } else {
	push @navbar2, $key;
      }
    }
    my $navbar2text = join('&nbsp;|&nbsp;', @navbar2);

    #########
    # do what it says on the tin
    #
    $site_headers .= qq(
    <table border="0" cellpadding="0" cellspacing="0" width="100%" align="center">
      <tr valign="bottom">
        <td align="left"><img src="/gfx/header/helix.gif" width="44" height="44" alt="" /></td>
        <td align="left" nowrap class="headerinactive">
            $navbar1text
        </td>
        <td align="right">$phogotext</td>
      </tr>
      <tr valign="top">
        <td colspan="3" class="headerfooterseparator"><img src="/gfx/blank.gif" height="1" width="640" alt="" /></td>
      </tr>
      <tr valign="top">
        <td colspan="3" class="headerbackground"><img src="/gfx/blank.gif" height="2" width="640" alt="" /></td>
      </tr>
    </table>
    <table border="0" cellpadding="0" cellspacing="0" width="100%" align="center">
      <tr valign="top" class="headerbackground">
        <td align="left" class="headerinactive" nowrap>$navbar2text</td>
        <td align="right" class="headerinactive" nowrap>
          @{[join(" | ", grep { defined $_ && $_ ne "" && $_ ne "undef" } ($self->{'drp'}, $self->{'cou'}))]}&nbsp;
        </td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="headerbackground"><img src="/gfx/blank.gif" height="2" width="640" alt="" /></td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="headerfooterseparator"><img src="/gfx/blank.gif" height="1" width="640" alt="" /></td>
      </tr>
    </table>\n);


    if(!$self->ini_loaded() && $self->{'navigator'}) {
      for my $n (qw(navigator navigator2 navigator3)) {
	next if(!defined $self->{$n});
	for my $line (split(/,/, $self->{$n})) {
	  $line =~ s/^\s+//sig;
	  
	  my ($text, $link) = ($line,"");
	  if($line =~ /\|\|/) {
	    ($text, $link) = split('\|\|', $line);
	  } else {
	    ($text, $link) = $line =~ /^(.*);(.*?)$/s if($line =~ /;/);
	  }
	  
	  if($text =~ /\|/) {
	    my ($envvar, $envok, $inverttest);
	    ($text, $envvar) = split('\|', $text, 2);
	    
	    if(substr($envvar, 0, 1) eq "!") {
	      $envvar     = substr($envvar, 1, length($envvar)-1);
	      $inverttest = 1;
	    }
	    
	    if((!$inverttest && exists($ENV{$envvar})) || ($inverttest && !exists($ENV{$envvar}))) {
	      push @{$self->{'navlist'}->{$n}}, {
						 'text' => $text,
						 'link' => $link,
						};
	    }
	  } else {
	    push @{$self->{'navlist'}->{$n}}, {
					       'text' => $text,
					       'link' => $link,
					      };
	  }
	}
      }
    }
    
    my $req_uri       = $ENV{'REQUEST_URI'};
    my $directory     = $req_uri;
    $directory        =~ s/^(.*)\/.*?$/$1/;

    if((substr($server_name, 0, 6) eq "wwwdev" ||
	substr($server_name, 0, 7) eq "spider2") &&
       !defined($ENV{'GATEWAY_INTERFACE'})) {

      my $header      = $directory . "/header.ini";
      my $filename    = $req_uri;

      if($req_uri eq $directory || $req_uri eq "$directory/") {
	$filename .= "/index.shtml";
      }
      
      $filename =~ s|//|/|g;
      $header   =~ s|//|/|g;
      
      push @{$self->{'navlist'}->{'navigator2'}}, (
						   {
						    'text' => qq(<b>Edit this page</b>),
						    'link' => qq(/edit$filename),
						   },
						   {
						    'text' => qq(<b>Edit sidebar</b>),
						    'link' => qq(/edit$header),
						   },
						  );
    }
    
    my $sidebar_on = undef;
    for my $k (keys %{$self->{'navlist'}}) {
      if(scalar @{$self->{'navlist'}->{$k}} != 0) {
	$sidebar_on = 1;
	last;
      }
    }
    
    if(defined $sidebar_on) {
      my $navhead  = $self->{'navigator_header'} || qq(<img src="/gfx/blank.gif" height="80" width="110" alt="" />);
      
      $site_headers .= qq(
    <table width="100%" cellpadding="0" cellspacing="0" border="0">
      <tr valign="top">
        <td align="left" width="130" class="navigator">
	  <table width="130" border="0" cellpadding="0" cellspacing="0">
	    <tr valign="top" class="navigator">
	      <td><img src="/gfx/blank.gif" width="10" height="22" alt="" /></td>
	      <td>$navhead</td>
	      <td><img src="/gfx/blank.gif" width="10" height="22" alt="" /></td>
	    </tr>
	    <tr valign="top" class="navigator">
	      <td colspan="3" class="navigatorseparator"><img src="/gfx/blank.gif" width="130" height="1" alt="" /></td>
	    </tr>\n);

      for my $nav (sort keys %{$self->{'navlist'}}) {
	my $align = $self->{"${nav}_align"} || "right";

	for my $e ($self->sidebar_entries($nav)) {
	  $site_headers .= qq(
	    <tr valign="middle" class="$nav">
	      <td><img src="/gfx/blank.gif" width="10" height="22" alt="" /></td>
	      <td align="$align" class="nounderline">$e</td>
	      <td><img src="/gfx/blank.gif" width="10" height="22" alt="" /></td>
	    </tr>
	    <tr valign="top" class="navigator">
	      <td colspan="3" class="navigatorseparator"><img src="/gfx/blank.gif" width="130" height="1" alt="" /></td>
	    </tr>\n);
	}
      }
      
      $site_headers .= qq(
	    <tr valign="middle" class="navigator">
	      <td><img src="/gfx/blank.gif" width="10" height="22" alt="" /></td>
	      <td align="right" class="nounderline">&nbsp;</td>
	      <td><img src="/gfx/blank.gif" width="10" height="22" alt="" /></td>
	    </tr>
          </table>
        </td>\n);
#    }    

      #########
      # spaced out page content
      #
      $site_headers .= qq(
    <td><img src="/gfx/blank.gif" width="6" height="6" alt="" /></td>
    <td width="100%">
      <img src="/gfx/blank.gif" width="6" height="6" alt="" />);
    }

    $site_headers .= qq(<br clear="all" />
<!-- end header -->
<!-- page content starts here -->\n);
  }
  
  if(defined $self->{'banner'}) {
    my $banner = "";
    if($self->{'bannercase'} eq "uc") {
      $banner = uc($self->{'banner'});
    } elsif($self->{'bannercase'} eq "ucfirst") {
      $banner = ucfirst($self->{'banner'});
    } else {
      $banner = lc($self->{'banner'});
    }
    $site_headers .= $self->site_banner($banner);
  }

  return $site_headers;
}

sub site_banner {
  my ($self, $heading) = @_;

  return qq(
<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
  <tr><td class="h2bg"><img src="/gfx/blank.gif" height="4" alt="" /></td></tr>
  <tr valign="middle">
    <td class="h2bg" width="100%" align="center">
      <span class="bannertext">$heading</span>
    </td>
  </tr>
  <tr><td class="h2bg"><img src="/gfx/blank.gif" height="4" alt="" /></td></tr>
</table>);
}

sub site_footers {
  my $self      = shift;
  my $content   = "";
  my $sangerurl = "http://www.sanger.ac.uk";
  $sangerurl    = "http://wwwdev.sanger.ac.uk" if($self->is_dev());

  if($self->{'decor'} eq "full") {
    #########
    # short back and sidebars please
    #
    if(defined $self->{'navigator'}) {
      $content .= qq(
        <br /></td>
        <td><img src="/gfx/blank.gif" width="6" height="6" alt="" /></td>
      </tr>
    </table>\n);
    } else {
#      $content .= qq(
#          <br /></td>
#        </tr>
#      </table>
#    </center>\n);
    }

    my $lastmod   = "";
    my ($hostnum) = &hostname() =~ /([^\.]+)/;
    $hostnum      = substr($hostnum, -4, 4) || "";
    if(defined $ENV{'LAST_MODIFIED'}) {
      $lastmod = qq(last modified $ENV{'LAST_MODIFIED'});

    } elsif(defined $ENV{'SCRIPT_FILENAME'}) {
      $ENV{'SCRIPT_FILENAME'} =~ /^(.*)$/;
      my $filename    = $1;
      my ($mtime)     = (stat($filename))[9];
      if($mtime) {
	my $scriptstamp = localtime($mtime);
	$lastmod        = qq(script last modified $scriptstamp) if(defined $scriptstamp);
      }
    }
    $lastmod .= qq( ($hostnum));

    my $mail = $self->{'author'};
    if($ENV{'HTTP_X_FORWARDED_HOST'} && $ENV{'HTTP_X_FORWARDED_HOST'} =~ /helpdesk/) {
      $mail ||= 'syshelp@sanger.ac.uk';
    } else {
      $mail ||= 'webmaster@sanger.ac.uk';
    }

    if($mail !~ /\@/) {
      $mail .= qq(\@sanger.ac.uk);
    }

    $content .= qq(
<!-- page content ends here -->
    <table border="0" cellpadding="0" cellspacing="0" width="100%" align="center">
      <tr valign="top">
        <td colspan="2" class="headerfooterseparator"><img src="/gfx/blank.gif" height="1" width="640" alt="" /></td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="footerbackground"><img src="/gfx/blank.gif" height="2" width="640" alt="" /></td>
      </tr>
      <tr valign="top" class="footerbackground">
        <td align="left"  class="headerinactive" nowrap>&nbsp;$lastmod</td>
        <td align="right" class="headerinactive"><a href="$sangerurl/feedback/">$mail</a>&nbsp;</td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="footerbackground"><img src="/gfx/blank.gif" height="2" width="640" alt="" /></td>
      </tr>
      <tr valign="top">
        <td colspan="2" class="headerfooterseparator"><img src="/gfx/blank.gif" height="1" width="640" alt=""></td>
      </tr>
    </table>
  </body>
</html>\n);
  }
  return $content;
}

sub portlets { ""; }

1;
