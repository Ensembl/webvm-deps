#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2003-09-17
# Last Modified: 2005-09-26
#
# Calendar interface over Calendar::Simple
# Also does pretty HTML markup with callbacks for data
#
package Website::Utilities::Calendar;
require Calendar::Simple; # don't import exported method 'calendar'
use strict;
use vars qw(@ISA @MONTHS);
@ISA    = qw(Calendar::Simple);
@MONTHS = qw(January February March April May June July
	     August September October November December);

sub new {
  my ($class, $ref) = @_;
  my $self = {};

  for my $k (qw(month year data_attributes header_attributes header_cb row_attributes table_attributes highlights callback_arg format)) {
    $self->{$k} = $ref->{$k} if($ref->{$k});
  }
  bless $self, $class;
  return $self;
}

sub month {
  my ($self, $month) = @_;
  $self->{'month'}   = $month if($month);
  return $self->{'month'};
}

sub year {
  my ($self, $year) = @_;
  $self->{'year'}   = $year if($year);
  return $self->{'year'};
}

sub highlight {
  my ($self, $day, $attr_ref) = @_;

  if(ref($attr_ref)) {
    #########
    # html td cell attributes
    #
    $self->{'highlights'}->{$day} = $attr_ref->{'html'} if(exists $attr_ref->{'html'});

    #########
    # data td cell callback
    #
    $self->{'callbacks'}->{$day}  = $attr_ref->{'cb'}   if(exists $attr_ref->{'cb'});

  } else {
    $self->{'highlights'}->{$day} = $attr_ref;
  }
}

sub calendar {
  my ($self, $format)  = @_;
  my $month ||= ($self->month() || "");
  my $year  ||= ($self->year()  || "");
  $format   ||= $self->{'format'};
  ($year)     = $year  =~ /(\d+)/;
  ($month)    = $month =~ /(\d+)/;
  $year     ||= (localtime)[5] + 1900;
  $month    ||= (localtime)[4] + 1;
  $month      = "" if($year eq "");

  #########
  # now reset them
  #
  $self->{'month'} = $month;
  $self->{'year'}  = $year;

  if(!$month && !$year) {
    warn qq(No month or year specified);
    return "";
  }

  my $caldata  = [&Calendar::Simple::calendar($month, $year)];
  my $calendar = "";

  if($format && $format eq "html") {
    $calendar = $self->html_calendar($caldata);

  } else {
    $calendar  = qq($MONTHS[$month -1] $year\n);
    $calendar .= qq(@{[map { sprintf("%2s", $_||"") } qw(Su Mo Tu We Th Fr Sa)]}\n);

    for my $m (@$caldata) {
      $calendar .= qq(@{[map { $_?sprintf("%2d", $_||''):"  "; } @$m]}\n);
    }
    $calendar .= "\n";
  }

  return $calendar;
}

sub html_calendar {
  my ($self, $caldata) = @_;

  my $dattr     = $self->{'data_attributes'}   || qq(align="right");
  my $rattr     = $self->{'row_attributes'}    || qq(valign="middle");
  my $hattr     = $self->{'header_attributes'} || qq(class="barial");
  my $tattr     = $self->{'table_attributes'}  || "";


  my $header    = qq($MONTHS[$self->{'month'} -1] $self->{'year'}\n);
  my $header_cb = $self->{'header_cb'};
  $header       = &$header_cb($header, $self->{'callback_arg'}) if($header_cb);
  my $markup    = qq(<table $tattr>\n  <tr $rattr><th $hattr colspan="7">$header</th></tr>\n);
  $markup      .= qq(<tr>@{[map { "<th>$_</th>" } qw(Su Mo Tu We Th Fr Sa)]}</tr>\n);

  for my $m (@{$caldata}) {
    $markup .= qq(<tr>);
    for my $day (@$m) {
      $day   ||= "";
      my $attr = $dattr;
      $attr    = $self->{'highlights'}->{$day} if(exists($self->{'highlights'}->{$day}));

      my $cb   = $self->{'callbacks'}->{$day};
      $day     = &$cb($day, $self->{'callback_arg'}) if($cb);

      $markup .= qq(<td $attr>$day</td>);
    }
    $markup .= qq(</tr>\n);
  }

  $markup .= qq(</table>\n);

  return $markup;
}

1;
