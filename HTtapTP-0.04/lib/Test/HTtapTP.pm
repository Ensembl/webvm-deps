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

    return;
}


# Doing HTTP things waits until import, so we have those options
sub import {
    my ($pkg, @opt) = @_;
    return $pkg->_import(1, @opt);
}
sub unimport {
    my ($pkg, @opt) = @_;
    return $pkg->_import(0, @opt);
}
sub _import {
    my ($pkg, $val, @opt) = @_;
    my $Test = Test::HTtapTP::Builder->rebless_singleton;
    $Test->init_for_web($val, @opt) if $ENV{GATEWAY_INTERFACE};
    return;
}


__init()
  unless $ENV{TEST_HTTAPTP_INHIBIT}; # intended for use in HTtapTP self-tests


1;
