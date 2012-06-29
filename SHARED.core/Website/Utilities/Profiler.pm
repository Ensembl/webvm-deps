#########
# Author:        rmp
# Last Modified: $Date: 2007/02/28 17:21:56 $ $Author: rmp $
# Id:            $Id: Profiler.pm,v 1.2 2007/02/28 17:21:56 rmp Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/Utilities/Profiler.pm,v $
# $HeadURL$
#
# Basic profiling utility
#
package Website::Utilities::Profiler;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use Carp;

our $DEBUG = 0;
our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

sub new {
  my $class = shift;
  $DEBUG and print {*STDERR} "new profiler\n";
  return bless {}, $class;
}

sub begin {
  my ($self, $label) = @_;
  $self->{'timers'}->{$label} = [gettimeofday()];
  $self->{'startcounts'}->{$label}++;
  $DEBUG and print {*STDERR} "begin $label\n";
  return;
}

sub end {
  my ($self, $label) = @_;
  my ($s, $usec)     = gettimeofday();

  if(!exists $self->{'timers'}->{$label}) {
    carp qq(Profiler was asked to end '$label' by ).caller;
    return;
  }

  my $before = $self->{'timers'}->{$label}->[0] + ($self->{'timers'}->{$label}->[1]/1_000_000);
  my $after  = $s + ($usec/1_000_000);
  my $delta  = $after-$before;

  $self->{'tally'}->{$label} += $delta;
  $self->{'endcounts'}->{$label}++;

  if(!defined $self->{'max'}->{$label} || $delta > $self->{'max'}->{$label}) {
    $self->{'max'}->{$label} = $delta;
  }

  if(!defined $self->{'min'}->{$label} || $delta < $self->{'min'}->{$label}) {
    $self->{'min'}->{$label} = $delta;
  }

  $DEBUG and print {*STDERR} "end $label\n";
  return;
}

sub report {
  my ($self, $mode) = @_;
  $mode           ||= 'text';

  my $firstlen      = 0;
  for my $k (keys %{$self->{'tally'}}) {
    if(length $k > $firstlen) {
      $firstlen = length $k;
    }
  }
  $firstlen+=2;

  my $text = qq(@{[
    sprintf("%-${firstlen}s %-8s %-8s %-15s %-14s %-14s %-14s\n", 'Tag', 'Begun', 'Ended', 'Total Time (s)', 'Mean Time (s)', 'Max Time (s)', 'Min Time (s)'),
    map {
      sprintf("%-${firstlen}s %-8d %-8d %-15f %-14f %-14f %-14f\n",
              $_,
              $self->{'startcounts'}->{$_},
              $self->{'endcounts'}->{$_},
              $self->{'tally'}->{$_},
              $self->{'tally'}->{$_}/$self->{'startcounts'}->{$_},
              $self->{'max'}->{$_},
              $self->{'min'}->{$_});
    } sort {
      $self->{'tally'}->{$b} <=> $self->{'tally'}->{$a}
    } keys %{$self->{'tally'}}]});

  if($mode eq 'html') {
    $text          =~ s|^\s*(.*?)\s*$|<tr><td>$1</td></tr>|mgx;
    $text          =~ s|\ \ +|</td><td>|smgx;
    my ($firstrow) = $text =~ m|(<tr>.*</tr>)|mx;
    $text          =~ s|(<tr>.*</tr>)||mx;
    $firstrow      =~ s|<([^<]*)td([^>]*)>|<${1}th${2}>|mxg;
    $text          = q(<div class="debug"><table class="sortable zebra" id="profiler"><caption>DEBUGGING Profiler Report</caption><thead>).$firstrow.q(</thead><tbody>).$text.q(</tbody></table></div>);
  }

  return $text;
}

1;
__END__

=head1 NAME

Website::Utilities::Profiler - a basic profiling tool

=head1 VERSION

$Revision: 1.2 $

=head1 SYNOPSIS

my $profiler = Website::Utilities::Profiler->new();
$profiler->begin('my tag');
$profiler->end('my tag');
print $profiler->report();

=head1 DESCRIPTION

Keeps track of timings and number of execution passes between begin and with a given tag.

=head1 SUBROUTINES/METHODS

=head2 new : Constructor

 my $prof = Website::Utilities::Profiler->new();

=head2 begin : start timing for this tag

 $prof->begin('a tag');

=head2 end : end timing for this tag

 $prof->end('a tag');

=head2 report : dump the report (to this point) from the profiler

 print $prof->report();       # a basic text report

 print $prof->report('html'); # a slightly prettier html report

=head1 DIAGNOSTICS

 $Website::Utilities::Profiler::DEBUG = 1;

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

Time::HiRes

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rmp@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 GRL, by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
