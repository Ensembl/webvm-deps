package Test::HTtapTP::Builder;
use strict;
use warnings;

use Test::Builder 0.94;
# 0.92 doesn't have the is_passing hook we need
# 0.89_01 0.93_01 have it, but were dev releases


our @ISA;

# This is horrible.  Monkey-patching Test::Builder::is_passing is an
# alternative which seemed worse.
sub rebless_singleton {
    my ($pkg, $obj) = @_;

    $obj ||= Test::Builder->new; # the singleton
    @ISA = (ref($obj)); # subclass of...  whatever we were given
    bless $obj, $pkg; # rebless

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


sub init_for_web {
    my ($self) = @_;

    print "Content-type: text/plain\n\n";
    $self->failure_output(\*STDOUT);

    $SIG{__WARN__} = sub { $self->_warn(w => @_); warn @_ };
    $SIG{__DIE__} = sub { $self->_warn(e => @_); die @_ };

    return;
}

sub _warn {
    my ($self, $letter, $msg) = @_;
    $msg =~ s{\n\z}{};
    $msg =~ s{\n}{\n  | }g;
    $self->diag("[$letter] $msg");
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
