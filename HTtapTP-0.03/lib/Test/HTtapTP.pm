package Test::HTtapTP;
use strict;
use warnings;

sub __init {
    require Test::HTtapTP::Builder;

    # Do this to ensure that { plan tests => 1; ok(1, "cool"); die }
    # will show an explicit failure
    my $Test = Test::HTtapTP::Builder->rebless_singleton;

    $Test->set_SIG;
    # Do all setup except web-specific stuff, so tests behave the same
    # under prove(1)

    $Test->init_for_web if $ENV{GATEWAY_INTERFACE};

    return;
}


__init()
  unless $ENV{TEST_HTTAPTP_INHIBIT}; # intended for use in HTtapTP self-tests


1;
