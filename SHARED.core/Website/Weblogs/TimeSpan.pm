package Website::Weblogs::TimeSpan;
#########
# date manipulation
#
# Author: rmp 23-05-2001
#
use strict;
use Time::Local;

sub new {
    my ($class, $hashref) = @_;

    #########
    # take a copy of our hash.
    # may have keys: seed, range
    #
    my $self = {};
    bless($self, $class);
    $self->seed($hashref->{'seed'}   || $self->today());
    $self->range($hashref->{'range'} || "day");
    return $self;
}

#########
# set seed date, ISO format; e.g. 2001-23-04
#
sub seed {
    my ($self, $seed) = @_;

    if(defined $seed) {
	if($seed =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
	    $seed .= qq( 00:00:00);
	} elsif($seed !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/) {
	    #########
	    # date is not correct format!
	    #
	    print STDERR qq(Website::Weblogs::TimeSpan::seed incorrect format\n);
	    return undef;
	}
	$self->{'seed'} = $seed;
    }

    return $self->{'seed'};
}

#########
# set range: day|week|month|year
#
sub range {
    my ($self, $range) = @_;
    $self->{'range'} = $range if(defined $range);
    return $self->{'range'};
}

sub start {
    my ($self) = @_;
    my $method_name = $self->{'range'} . qq(_start_end);
    my ($start, $tmp) = $self->$method_name();
    return $start;
}

sub end {
    my ($self) = @_;
    my $method_name = $self->{'range'} . qq(_start_end);
    my ($tmp, $end) = $self->$method_name();
    return $end;
}

sub today {
    my ($sec, $min, $hour, $day, $month, $year) = gmtime();
    $year  += 1900;
    $month += 1;
    $month = sprintf "%02d", $month;
    $day   = sprintf "%02d", $day;
    $sec   = sprintf "%02d", $sec;
    $min   = sprintf "%02d", $min;
    $hour  = sprintf "%02d", $hour;
    return qq($year-$month-$day $hour:$min:$sec);
}

sub yesterday {
    my ($osec, $omin, $ohour, $oday, $omonth, $oyear) = gmtime();

    my $day_in_seconds = 24 * 60 * 60;
    my $gmtime_before  = timegm($osec, $omin, $ohour, $oday, $omonth, $oyear);
    my $gmtime_after   = $gmtime_before - $day_in_seconds;

    my ($nsec, $nmin, $nhour, $nday, $nmonth, $nyear) = gmtime($gmtime_after);

    $nyear  += 1900;
    $nmonth += 1;
    $nmonth = sprintf "%02d", $nmonth;
    $nday   = sprintf "%02d", $nday;
    $nsec   = sprintf "%02d", $nsec;
    $nmin   = sprintf "%02d", $nmin;
    $nhour  = sprintf "%02d", $nhour;

    my $end   = qq($nyear-$nmonth-$nday $nhour:$nmin:$nsec);
    return $end;
}

sub day_start_end {
    my ($self) = @_;
    my ($oyear, $omonth, $oday, $ohour, $omin, $osec) = $self->{'seed'} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$/;

    #########
    # complete day
    #
    my $day_in_seconds = 24 * 60 * 60;
    my $gmtime_before  = timegm($osec, $omin, $ohour, $oday, ($omonth - 1), $oyear);
    my $gmtime_after   = $gmtime_before + $day_in_seconds;

    my ($nsec, $nmin, $nhour, $nday, $nmonth, $nyear) = gmtime($gmtime_after);
    $nyear  += 1900;
    $nmonth += 1;
    $nmonth = sprintf "%02d", $nmonth;
    $nday   = sprintf "%02d", $nday;
    $nsec   = sprintf "%02d", $nsec;
    $nmin   = sprintf "%02d", $nmin;
    $nhour  = sprintf "%02d", $nhour;

    my $end   = qq($nyear-$nmonth-$nday 00:00:00);
    my $start = qq($oyear-$omonth-$oday 00:00:00);

    return ($start, $end);
}

sub week_start_end {
    my ($self) = @_;
    my ($syear, $smonth, $sday, $shour, $smin, $ssec) = $self->{'seed'} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$/;

    #########
    # week surrounding seed date (as opposed to the last complete week (week_start_end)
    #
    my $gmtime_before  = timegm( $ssec, $smin, $shour, $sday, ($smonth - 1), $syear);
    my ($t1, $t2, $t3, $t4, $t5, $t6, $magic_day_of_week) = gmtime($gmtime_before);

    my $day_in_seconds  = 24 * 60 * 60;
    my $week_in_seconds = 7 * 24 * 60 * 60;

    my $gmtime_sunday_before = $gmtime_before - ($day_in_seconds * $magic_day_of_week);
    my $gmtime_sunday_after  = $gmtime_sunday_before + $week_in_seconds;
    
    my ($osec, $omin, $ohour, $oday, $omonth, $oyear) = gmtime($gmtime_sunday_after);
    my ($nsec, $nmin, $nhour, $nday, $nmonth, $nyear) = gmtime($gmtime_sunday_before);

    $oyear  += 1900;
    $omonth += 1;
    $omonth = sprintf "%02d", $omonth;
    $oday   = sprintf "%02d", $oday;
    $osec   = sprintf "%02d", $osec;
    $omin   = sprintf "%02d", $omin;
    $ohour  = sprintf "%02d", $ohour;

    $nyear  += 1900;
    $nmonth += 1;
    $nmonth = sprintf "%02d", $nmonth;
    $nday   = sprintf "%02d", $nday;
    $nsec   = sprintf "%02d", $nsec;
    $nmin   = sprintf "%02d", $nmin;
    $nhour  = sprintf "%02d", $nhour;

    my $start = qq($nyear-$nmonth-$nday 00:00:00);
    my $end   = qq($oyear-$omonth-$oday 00:00:00);

    return ($start, $end);
}

sub month_start_end {
    my ($self) = @_;
    my ($oyear, $omonth, $oday, $ohour, $omin, $osec) = $self->{'seed'} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$/;

    my ($nsec, $nmin, $nhour, $nday, $nmonth, $nyear) = ($osec, $omin, $ohour, $oday, $omonth, $oyear);

    #########
    # last complete month
    #
    $nmonth --;

    #########
    # check rollover
    #
    if($nmonth < 1) {
	$nyear --;
	$nmonth = 12;
    }
    $nday   = 1;
    $oday   = 1;
    $oday   = sprintf "%02d", $oday;
    $nmonth = sprintf "%02d", $nmonth;
    $nday   = sprintf "%02d", $nday;
    $nsec   = sprintf "%02d", $nsec;
    $nmin   = sprintf "%02d", $nmin;
    $nhour  = sprintf "%02d", $nhour;

    my $start = qq($nyear-$nmonth-$nday 00:00:00);
    my $end   = qq($oyear-$omonth-$oday 00:00:00);

    return ($start, $end);
}

sub year_start_end {
    my ($self) = @_;
    my ($oyear, $omonth, $oday, $ohour, $omin, $osec) = $self->{'seed'} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$/;

    my ($nsec, $nmin, $nhour, $nday, $nmonth, $nyear) = ($osec, $omin, $ohour, $oday, $omonth, $oyear);

    #########
    # last complete year
    #
    $nyear --;
    $omonth = 1;
    $oday   = 1;
    $nmonth = 1;
    $nday   = 1;
    $omonth = sprintf "%02d", $omonth;
    $oday   = sprintf "%02d", $oday;
    $nmonth = sprintf "%02d", $nmonth;
    $nday   = sprintf "%02d", $nday;
    $nsec   = sprintf "%02d", $nsec;
    $nmin   = sprintf "%02d", $nmin;
    $nhour  = sprintf "%02d", $nhour;

    my $start = qq($nyear-$nmonth-$nday 00:00:00);
    my $end   = qq($oyear-$omonth-$oday 00:00:00);

    return ($start, $end);
}

sub advance {
    my ($self, $ayear, $amonth, $aday, $ahour, $amin, $asec) = @_;
    my ($syear, $smonth, $sday, $shour, $smin, $ssec) = $self->{'seed'} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$/;

    $ayear  ||= 0;
    $amonth ||= 0;
    $aday   ||= 0;
    $ahour  ||= 0;
    $amin   ||= 0;
    $asec   ||= 0;

    $syear  += $ayear;
    $smonth += $amonth;
    if($smonth > 12) {
	$smonth = 1;
	$syear++;
    }

    my $gmtime_before  = timegm( $ssec, $smin, $shour, $sday, ($smonth - 1), $syear);

    my $secs_per_day  = 60 * 60 * 24;
    my $secs_per_hour = 60 * 60;
    my $secs_per_min  = 60;

    $gmtime_before += $aday  * $secs_per_day;
    $gmtime_before += $ahour * $secs_per_hour;
    $gmtime_before += $amin  * $secs_per_min;
    $gmtime_before += $asec;

    my ($nsec, $nmin, $nhour, $nday, $nmonth, $nyear) = gmtime($gmtime_before);

    $nyear  += 1900;
    $nmonth += 1;
    $nmonth = sprintf "%02d", $nmonth;
    $nday   = sprintf "%02d", $nday;
    $nsec   = sprintf "%02d", $nsec;
    $nmin   = sprintf "%02d", $nmin;
    $nhour  = sprintf "%02d", $nhour;

    my $str = qq($nyear-$nmonth-$nday $nhour:$nmin:$nsec);
    $self->seed($str);
    return $str;
}


sub advance_one_day {
    my ($self) = @_;
    return $self->advance(0,0,1);
}
1;
