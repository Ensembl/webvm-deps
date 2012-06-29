#########
# Author: rmp
#
# Irritating animated pal for your desktop
#
package Website::portlet::animatedpal;
use strict;
use warnings;
use base qw(Website::portlet);

our $ANIMS = [qw(
	       http://www.millan.net/anims/giffar/giffar2/gdance2.gif
	       http://www.millan.net/anims/giffar/camel.gif
	       http://www.millan.net/anims/giffar/welefant.gif
	       http://www.millan.net/anims/giffar/bushcat.gif
		)];

sub run {
  my $self     = shift;
  my $username = $self->{'username'} || "";
  my $rand     = $ANIMS->[int(rand(scalar @$ANIMS))];

  return qq(<div class="portlet">
  <div class="portlethead">Animated Pal</div>
  <div class="portletitem"><img src="$rand" /></div>
</div>\n);
}

1;
