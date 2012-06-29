#########
# date utility for converting ISSO format dates to english ones
# Author: rmp, 2001
#
package Website::Utilities::Date;

use strict;
use Time::Local;

#########
# nice formatting for dates
#
sub nicedate {
    my ($date, $opts) = @_;

    if($date eq "0000-00-00 00:00:00" || $date eq "") {
        return "";
    }

    my ($y, $m, $d, $hr, $mn, $sc) = $date =~ /(....)-(..)-(..) (..):(..):(..)/;
    my ($d1, $d2) = split('', $d);
    my $d3;

  SWITCH: {
      $m = "Jan",  last SWITCH if ($m == 1);
      $m = "Feb",  last SWITCH if ($m == 2);
      $m = "Mar",  last SWITCH if ($m == 3);
      $m = "Apr",  last SWITCH if ($m == 4);
      $m = "May",  last SWITCH if ($m == 5);
      $m = "Jun",  last SWITCH if ($m == 6);
      $m = "Jul",  last SWITCH if ($m == 7);
      $m = "Aug",  last SWITCH if ($m == 8);
      $m = "Sep",  last SWITCH if ($m == 9);
      $m = "Oct",  last SWITCH if ($m == 10);
      $m = "Nov",  last SWITCH if ($m == 11);
      $m = "Dec",  last SWITCH if ($m == 12);
  }

  SWITCH: {
      $d3 = "st", last SWITCH if ($d2 == 1 && $d1 != 1); # not 11st
      $d3 = "nd", last SWITCH if ($d2 == 2 && $d1 != 1); # not 12nd
      $d3 = "rd", last SWITCH if ($d2 == 3 && $d1 != 1); # not 13rd
      $d3 = "th", last SWITCH;
  }
    if($d1 eq "0") {
        $d1 = "";
    }

    my $ret = qq($d1$d2$d3 $m $y);
    $ret .= qq( $hr$mn) unless(defined $opts->{'notime'});

    return  $ret;
}

########
# returns a date time string in epoch seconds 
#
sub epochdate {
  my ($date) = @_;
  my ($y, $m, $d, $hr, $mn, $sc) = $date =~ /(....)-(..)-(..) (..):(..):(..)/;
  my $epoch = timelocal($sc,$mn,$hr,$d,$m - 1, $y - 1900);
  return $epoch;
}

1;
