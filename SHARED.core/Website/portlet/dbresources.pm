#########
# Author: rmp
#
# Pretty stupid file-cat-to-portlet. Need to make this more generic and useful
#
package Website::portlet::dbresources;
use strict;
use warnings;
use base qw(Website::portlet);
use SangerWeb;

sub run {
  my $self    = shift;
  my $content = '';

  eval {
    my $fh;
    open($fh, "/WWW/SANGER_docs/data/dbresources.htx") or die $!;
    local $/ = undef;
    $content = <$fh>;
    close($fh);
  };
  return '' unless($content);

  return qq(<div class="portlet">
  <div class="portlethead" style="cursor:pointer" onclick="document.location='/DataSearch/';">Database Resources</div>
  <div class="portletitem">$content</div>
</div>\n);
}

1;
