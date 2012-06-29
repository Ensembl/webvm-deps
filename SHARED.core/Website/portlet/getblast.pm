#########
# Author: rmp
#
package Website::portlet::getblast;
use strict;
use warnings;
use base qw(Website::portlet);
use Website::Blast::Util qw($USERCONFIG_ID);
use Website::Blast::Ticket;

sub run {
  my $self    = shift;
  my $joblist = '';

  if($self->{'username'}) {
    my $userconfig = $self->{'userconfig'};
    my $data       = $userconfig->get($USERCONFIG_ID) || [];

    #########
    # build list of submitted ids
    #
    if(scalar @{$data}) {
      $joblist .= qq(  <div class="portletitem">
    <ul><li>Your recent tickets</li>@{[ map {
      my $ticket = Website::Blast::Ticket->new({
					        'id' => $_,
					       });
      my $status = (($ticket && $ticket->queuestub())?$ticket->queuestub->status():'') || 'UNKN';
      qq(      <li>$status: <a href="/cgi-bin/blast/getblast?id=$_">$_</a></li>\n);
      } sort @{$data}]}
    </ul>
</div>\n);
    }
  }

  #########
  # return content
  #
  return qq(<div class="portlet">
  <div class="portlethead">Retrieve BLAST result</div>
  <div class="portletitem">
    <form method="get" action="/cgi-bin/blast/getblast">
      <input type="entry" name="id" size="10" />
      <input type="submit" value="retrieve" />
    </form>
  </div>
$joblist
</div>\n);
}

1;
