#########
# Author:        rmp
# Maintainer:    rmp
# Last Modified: 2006-09-18
#
# decoration for (www|dev).genes2cognition.org
#
package SiteDecor::g2c;
use strict;
use warnings;
use base qw(SiteDecor);
use YAML;
our $VERSION = do { my @r = (q$Revision: 6.28 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub init_defaults {
  my $self = shift;
  my $def  = {
	      'stylesheet'     => ['/css/g2c.css'],
	      'jsfile'         => [
                                    'http://js.sanger.ac.uk/jquery-1.3.2.min.js', 
                                    '/js/g2c.js',
			            'http://js.sanger.ac.uk/urchin.js'
				  ],
	      'redirect_delay' => 5,
	      'bannercase'     => 'ucfirst',
	      'author'         => 'webmaster',
	      'decor'          => 'full',
	      'title'          => 'Genes2Cognition Neuroscience Research Programme',
	      'description'    => 'Genes2Cognition Neuroscience Research Programme',
              "flash_var"      => 0, 
	     };
  $self->merge($def);
}

sub create_menu {
  my ($self,$entry) = @_;
  my $output = q{};
  while ((my $key, my $value) = each %$entry) {
    if (ref $value eq 'HASH') {
      $output .=  qq(<li><a href="$value->{'link'}" id="$value->{'id'}">$key</a></li>);

      if ($value->{'match'}) {
        $output .= qq( <li @{[(defined $self->{'show_menu'} && $self->{'show_menu'} =~ /$value->{'match'}/)?q():q(style="display:none")]}>);
      }
      else {
        $output .= qq( <li @{[(defined $self->{'show_menu'} && $self->{'show_menu'} eq $value->{'id'})?q():q(style="display:none")]}>);
      }

      $output .= qq(<ul>\n);
      for my $sub (@{$value->{'sub'}}) {
        $output .= $self->create_menu($sub);
      }
      $output .= qq(  </ul>
</li>\n);         
    }
    else {
      $output.= qq(<li><a href="$value">$key</a></li>\n);
    }
  }
  return $output;
}

sub html_headers {
  my $self   = shift;
  my $flash_var = $self->flash_var() || 0;

  my $html_headers = $self->SUPER::html_headers();
  my $dev        = $ENV{'dev'} || q();

  $html_headers .= qq(
     <table id="container" cellpadding="0" cellspacing="0" border="0" align="center" width="1000">
      <tr> 
        <td width="170px" valign="top"> 
           <div id="left_menu">
             <a class="homelink" href="/" title="home"><img src="/gfx/logo.png" alt="home"></a>
             <p>Search G2Cdb:</p>
             <form method="get" action="/cgi-bin/SearchView">
               <input type="text" name="text" />
               <input type="hidden" name="species" value="All"/>
               <button type="submit" name="submit" value="submit">Go</button>
             </form>
             <ul>);
  eval {
    my $config_path = $ENV{'DOCUMENT_ROOT'}.'/../data/g2c_menu.yml';
    my $config = YAML::LoadFile($config_path);

    for my $entry (@$config) {
      $html_headers .= $self->create_menu($entry);
    }
  };
  if ($@) {
    warn "Problems : $@";
  }

  $html_headers .= qq(<li>@{[$self->username() ? q(<a href="/sso/logout">Logout) : q(<a href="/sso/login">Login)]}</a></li>
               @{[$self->is_local ? qq(<li><a href="http://intweb$dev.sanger.ac.uk/g2c/">Intranet</a></li>): q()]}
             </ul>
           </div>
         </td>
         <td valign="top" id="centerpanel">
<!-- begin main_content -->\n);

  return $html_headers;
}

sub is_local {
  my $self = shift;
  if ($ENV{'localuser'}) {
    return 1;
  }
  return;
}

sub site_footers {
  my $self = shift;
  return qq(</td>
          </tr>
          <tr> 
            <td id="footer" colspan="2"> 
             &copy; G2C 2008 Selected graphics supplied by and used with permission of The Wellcome Trust Medical Library and Dolan DNA Learning Center. 
           </td>
         </tr>
       </table>
       <script type="text/javascript">
         _userv=0;
         urchinTracker();
       </script>
     </body>
</html>\n);
}


1;
