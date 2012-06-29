#########
# Author: rmp
#
# Configurable portlet container
#
package Website::portlet::special;
use strict;
use warnings;
use base qw(Website::portlet);
use Website::portlet::getblast;

our $PORTLETS    = {
		    'logins'             => qq(Who\'s logged in?),
#		    'calendar'           => qq(Events this month),
		    'getblast'           => qq(BLAST results),
#		    'news'               => qq(RSS News Feeds),
		    'miniad'             => qq(WTSI Adverts),
		    'ssosignon'          => qq(Single Sign On),
#		    'pdfconvertor'       => qq(PDF Convertor),
#		    'linkclipboard_ajax' => qq(Link Clipboard),
		   };
our $PORTLET_IDS = [sort keys %$PORTLETS];
our $CONFIG_KEY  = 'portlet';

sub fields {
  my $self = shift;
  return ($self->SUPER::fields(), 'skip');
}

sub run {
  my $self    = shift;
  my $content = '';

  #########
  # only allow configuration for logged-in users
  #
  return $content unless($self->{'username'});

  #########
  # load configured portlets from session database & detaint
  #
  my $configured_portlets = $self->{'userconfig'}->get($CONFIG_KEY);

  #########
  # run configured portlets
  #
  for my $portletname (@{$PORTLET_IDS}) {
    #########
    # skip unless it's an approved portlet
    #
    my $portletpkg = "Website::portlet::$portletname";
    eval "require $portletpkg";
    if($@) {
      warn $@;
      next;
    }

    next unless(grep { $_ eq $portletname } @{$configured_portlets});

    next if(grep { $_ eq $portletname } @{$self->{'skip'}}); # skip determines if SiteDecor has already drawn this one (e.g. configured in header.ini)

    eval {
      my $new  = $portletpkg->new($self);
      my $pstr = $new->run() || '';
      $content .= qq(<!--begin configured $portletname for $self->{'username'} -->
$pstr
<!-- end configured $portletname -->\n);
    };
    if($@) {
      warn $@;
      next;
    }
  }

  #########
  # List available portlets
  #
  my $dev   = $ENV{'dev'}||'';
  my $proto = $ENV{'HTTP_X_FORWARDED_PROTOCOL'} || 'http';
  $content .= qq(<div class="portlet">
  <div class="portlethead">Portlet Configuration</div>
  <script type="text/javascript" src="$proto://js$dev.sanger.ac.uk/apps/portlet.js"></script>
  <div class="portletitem" id="portlet_special">
    <ul>
      @{[ 
      map { 
        my $p = $_;
        my $auth = 0;
        eval {
          my $pkg = "Website::portlet::$p";
          $auth = $pkg->new($self)->is_authorised();
        };
        $auth?qq(
        <li>
          @{[ (grep { $p eq $_ } @{$configured_portlets})?
                                qq(<a href="http://www$dev.sanger.ac.uk/cgi-bin/utils/siteconfig?portlet=$p" onclick="portlet_del('$p');return false"><img src="/icons/silk/delete.png" alt="delete" title="delete"/></a>):
                                qq(<a href="http://www$dev.sanger.ac.uk/cgi-bin/utils/siteconfig?portlet=$p" onclick="portlet_add('$p');return false"><img src="/icons/silk/add.png" alt="add" title="add"/></a>) ]}
        $PORTLETS->{$_}</li>):''; 

      } sort { $PORTLETS->{$a} cmp $PORTLETS->{$b} } @{$PORTLET_IDS} ]}
    </ul>  
  </div>
</div>\n);
  return $content;

}
1;

