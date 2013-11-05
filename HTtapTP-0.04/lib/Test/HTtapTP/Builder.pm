package Test::HTtapTP::Builder;
use strict;
use warnings;

use CGI;
use Carp;

use Test::Builder 0.94;
# 0.92 doesn't have the is_passing hook we need
# 0.89_01 0.93_01 have it, but were dev releases


our @ISA;
our @CARP_NOT = qw( Test::HTtapTP );


# This is horrible.  Monkey-patching Test::Builder::is_passing is an
# alternative which seemed worse.
sub rebless_singleton {
    my ($pkg, $obj) = @_;

    $obj ||= Test::Builder->new; # the singleton
    if ($obj->isa($pkg)) {
        # done already
    } else {
        @ISA = (ref($obj)); # subclass of...  whatever we were given
        bless $obj, $pkg; # rebless
    }

    return $obj;
}


sub is_passing {
    my $self = shift;
    if (@_ && !$_[0]) {
        # caller is clearing the is_passing flag
        my $fail_count = grep { !$_ } $self->summary;
        $self->make_failure_explicit unless $fail_count;
    }
    return $self->SUPER::is_passing(@_);
}

sub make_failure_explicit {
    my ($self) = @_;
    # ensure something in the output stream shows that we are not passing
    my $k = __PACKAGE__.'/is_passing';
    if ($self->{$k}) {
        warn "recursion dodged";
    } else {
        local $self->{$k} = 1;
        my $cls = ref($self);
        $self->ok(0, "fail marker on STDOUT from $cls, to show is_passing being cleared");
    }
}


# Using CGI.pm because it's there and we don't need much.
# Private because new frameworks shouldn't be tied to it.
sub _cgi {
    my ($self) = @_;
    return $self->{__PACKAGE__.'/_cgi'} ||= CGI->new;
}

sub init_for_web {
    my ($self, $use_no, @opt) = @_;

    # We get import/unimport options here
    my %opt;
    while (@opt) {
        my $opt = shift @opt;
        if ($opt eq ':cors_ok') {
            $opt{$opt} = $use_no;
        } else {
            croak "Unknown import option '$opt'";
        }
    }

    # Check the HTTP call?
    my $cgi = $self->_cgi;
    my $meth = $cgi->request_method;
    if ($meth eq 'GET') {
        # Run the tests
        print "Access-Control-Allow-Origin: *\n".
          "Access-Control-Expose-Headers: Content-Type\n"
            if $opt{':cors_ok'};
        print "Content-type: text/plain\n\n";
        $self->failure_output(\*STDOUT);

        $SIG{__WARN__} = sub { $self->_warn(w => @_); warn @_ };
        $SIG{__DIE__} = sub { $self->_warn(e => @_); die @_ };
        # ...continue with script compile + run ...

    } elsif ($meth eq 'OPTIONS' && $cgi->http('Origin') && $cgi->http('Access-Control-Request-Method')) {
        # CORS request
        if ($opt{':cors_ok'}) {
            print "Status: 204 No Content
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET
Access-Control-Allow-Headers: X-HTtapTP-Name, X-HTtapTP-Version, X-HTtapTP-Timeout
Access-Control-Max-Age: 30\n\n";

            # Request is handled, even before the script is compiled
            exit 0;

        } else {
            my $pkg = ref($self);
            my $msg = "CORS not enabled by default.  Import ':cors_ok' to enable";
            print "Status: 403 Forbidden
Content-Type: text/plain\n
$msg\n";
            croak $msg;
        }

    } else {
        print "Status: 400 Bad Request
Content-type: text/plain\n\n
not ok 1 - request type $meth is not accepted\n";
        die "Bad method $meth - request aborted";
    }

    return;
}

sub _warn {
    my ($self, $letter, $msg) = @_;
    my @loc = ($letter);

    # https://rt.cpan.org/Ticket/Display.html?id=75390
    # Workaround just hides that particular noise
    return if $letter eq 'e' && $msg =~
      m{^Can't locate Mo/(builder|default)\.pm in \@INC \(.*\) at \(eval \d+\) line 1\.$};

    # explain internal errors which pass through, but don't hide them
    push @loc, 'internal to test framework' if $letter eq 'e' &&
      eval { $msg->isa("Test::Builder::Exception") };

    push @loc, 'parsing' if !defined $^S;
    push @loc, 'in eval' if $^S; # else a bare error

    $msg =~ s{\n\z}{};
    $msg =~ s{\n}{\n  | }g;
    local $" = '; ';
    $self->diag("[@loc] $msg");
    return;
}


# Set %SIG handlers to attempt to tell STDOUT of our demise
sub set_SIG {
    my ($self) = @_;

    my $cls = ref($self);
    foreach my $sig (qw( HUP INT QUIT USR1 USR2 PIPE ALRM TERM XCPU )) {
        my $msg = "Caught SIG$sig in $cls; will re-zap self";
        $SIG{$sig} = sub {
            $self->ok(0, $msg);
            delete $SIG{$sig};
            kill $sig, $$;
            die "$msg - failed?"; # just in case
        };
    }
    return;
}

1;
