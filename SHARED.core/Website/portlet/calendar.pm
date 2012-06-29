#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2005-04
# Last Modified: $Date: 2007/01/26 11:04:04 $
#
package Website::portlet::calendar;
use strict;
use warnings;
use base qw(Website::portlet);
use Website::Utilities::Calendar;
use iCal::Parser;
use DateTime;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf '%d.'.'%03d' x $#r, @r };

sub fields {
  my $self = shift;
  return ($self->SUPER::fields(), 'ical');
}

sub run {
  my $self       = shift;
  my ($CAL_ROOT) = sprintf('%s/../../INTWEB_docs/dav/projects', $ENV{'DOCUMENT_ROOT'}||'') =~ m|([a-z0-9_/\.]+)|i;
  my $month      = $self->{'portlet_month'} || $ENV{'portlet_month'} || (localtime)[4] + 1;
  my $year       = $self->{'portlet_year'}  || $ENV{'portlet_year'}  || ((localtime)[5] + 1900);
  my $ical_in    = $self->{'ical'}          || $ENV{'ical'}          || '';
  my $ical       = [];

  return '<!-- no calendar configured -->' if(!$ical_in);

  #########
  # see if we have any ical files configured
  #
  if(ref($ical_in) eq 'ARRAY' && scalar @$ical_in) {
    $ical = $ical_in;

  } else {
    push @{$ical}, split(/[\s,]+/, $ical_in);
  }

  #########
  # Filter for sensible names only
  #
  @{$ical} = grep { /^[a-z0-9_]+$/i } @{$ical};

  #########
  # W::U::Calendar really draws the table
  #
  my $cal = Website::Utilities::Calendar->new({
					       'month' => $month,
					       'year'  => $year,
					      });

  #########
  # load, process and generally deal with any icals we need
  #
  if(@{$ical}) {
    $self->{'dt_start'} = DateTime->new(
					'year'  => $year,
					'month' => $month,
					'day'   => 1,
				       );
    $self->{'start'}    = $self->{'dt_start'}->ymd();
    $self->{'dt_end'}   = DateTime->new(
					'year'  => $year,
					'month' => $month,
					'day'   => DateTime->last_day_of_month(
									       'year'  => $year,
									       'month' => $month,
									      )->day()
				       );
    $self->{'end'}      = $self->{'dt_end'}->ymd();
    my $parser          = iCal::Parser->new(
					    '-start' => $self->{'dt_start'},
					    '-end'   => $self->{'dt_end'},
					   );

    for my $ics (@{$ical}) {
      ($ics) =~ m|([a-z0-9_\-:/]+)|i;
      $ics  .= '.ics' unless(substr($ics, -4, 4) eq '.ics');
      $parser->parse("$CAL_ROOT/$ics");
    }

    #########
    # Add user-specific calendar for onsite, logged-in users
    #
#    if($self->{'username'}) {
#      my $fn = "$CAL_ROOT/../people/$self->{'username'}.ics";
#      if(-f $fn) {
#	$parser->parse($fn);
#      }
#    }

    my $allev  = $parser->calendar->{'events'};
    my $events = {};
    for my $y (keys %$allev) {
      for my $m (keys %{$allev->{$y}}) {
	for my $d (keys %{$allev->{$y}->{$m}}) {
	  for my $eid (keys %{$allev->{$y}->{$m}->{$d}}) {
	    my $details = $allev->{$y}->{$m}->{$d}->{$eid};
	    next if($details->{'DTSTART'}->ymd() gt $self->{'end'} ||
		    $details->{'DTEND'}->ymd() lt $self->{'start'});

	    $events->{$d} ||= '';
	    my $str         = $details->{'SUMMARY'} || '';
	    my $url         = $details->{'URL'} || '';
	    $str            = qq(<a href='$url'>$str</a>) if($url);
	    $str            =~ s/'/\\'/g; # escape all quotes
	    $events->{$d}  .= qq(<li>$str</li>);
	  }
	}
      }
    }

    while(my ($d, $e) = each %$events) {
      my $nicedate = sprintf('%4d-%02d-%02d', $year, $month, $d);
      $cal->highlight($d, {
			   'cb' => sub {
			     qq(<a href="javascript:portlet_showevent('$nicedate','<ul>$e</ul>');">$d</a>);
			   }
			  });
    }
  }

  #########
  # highlight today
  #
  my @time = localtime();
  if($year == (1900+$time[5]) && $month == $time[4]+1) {
    $cal->highlight($time[3], {
                               'html' => qq(align="right" style="background-color:#a00000;color:#ffffff;font-weight:bold;"),
                              });
  }


  #########
  # return the calendar content wrapped in the portlet styling
  #
  my $content = qq(<script type="text/javascript">
function portlet_showevent(date, desc) {
  if (document.getElementById) {
    e           = document.getElementById("portlet_event");
    e.innerHTML = '';
  } else if (document.all) {
    e           = document.all[id];
  }
  e.innerHTML   = '<div class="portlethead">'+
                     '<a style="color:#ffffff;" href="javascript:portlet_hideevent();">X<\\/a>'+
                       date+
                  '<\\/div>'+
                  '<div class="portletitem">'+
                    desc+
                  '<\\/div>';
  e.style.visibility = "visible";
}

function portlet_hideevent() {
  if (document.getElementById) {
    e           = document.getElementById("portlet_event");
    e.innerHTML = '';
  } else if (document.all) {
    e           = document.all[id];
  }
  e.style.visibility = "hidden";
}

</script>
<div class="portlet">
  <div class="portlethead">Events this Month</div>
  <div class="portletitem" id="portlet_calendar">@{[
    $cal->calendar('html')
  ]}</div>
</div>
<div id="portlet_event" class="portlet" style="visibility:hidden;"></div>\n);
  return $content;
}

1;
