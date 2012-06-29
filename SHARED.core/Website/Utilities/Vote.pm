#########
# voting object
# rmp 2002-05-09
#
package Website::Utilities::Vote;
use strict;

sub new {
  my ($class, $refs) = @_;

  my $self = {};
  bless($self, $class);

  $self->load($refs);

  return $self;
}

sub load {
  my ($self, $refs)    = @_;
  my $ini              = $refs->{'ini'};
  $self->{'id'}        = $refs->{'question'};
  $self->{'title'}     = $ini->val("question$self->{'id'}", "Title");
  $self->{'options'}   = $ini->val("question$self->{'id'}", "Options");
  $self->{'counts'}    = "";
  $self->{'countfile'} = $ini->val("settings", "countfile") . "/" . $self->{'id'};

  eval {
    open(FIN, $self->{'countfile'}) or die;
    $self->{'counts'} = <FIN>;
    $self->{'counts'} ||= "";
    chomp $self->{'counts'};
    close(FIN);
  };

  if($self->{'counts'} eq "") {
    $self->{'counts'} = join('|', map { 0 } $self->options());
  }
}

sub id {
  my ($self) = @_;
  return $self->{'id'};
}

sub title {
  my ($self) = @_;
  return $self->{'title'};
}

sub options {
  my ($self) = @_;
  return split(/\|/, $self->{'options'});
}

sub counts {
  my ($self) = @_;
  return split(/\|/, $self->{'counts'});
}

sub count {
  my ($self, $opt) = @_;

  my @opts   = $self->options();
  my @counts = $self->counts();
  for (my $i = 0; $i < scalar @opts; $i++) {
    if($opts[$i] eq $opt) {
      return ($counts[$i]||0) + 0;
      last;
    }
  }
}

sub max_count {
  my ($self) = @_;
  my $max = 0;
  for my $c ($self->counts()) {
    $max = $c if($c > $max);
  }
  return $max;
}

sub total {
  my ($self) = @_;
  my $tot = 0;
  for my $c ($self->counts()) {
    $tot += $c;
  }
  return $tot;
}

sub vote {
  my ($self, $opt) = @_;
  #########
  # jump out if nothing was actually clicked
  #
  warn qq(Vote::voting\n);

  return unless($opt);

  my @opts   = $self->options();
warn qq(Vote knows @opts options);
  my @counts = $self->counts();
  for (my $i = 0; $i < scalar @opts; $i++) {
    if($opts[$i] eq $opt) {
      $counts[$i] ++;
      $self->{'counts'} = join('|', @counts);
      warn qq(Vote::vote updating);
      $self->update();
      last;
    }
  }
}

sub update {
  my ($self) = @_;

  warn qq(Website::Utilities::Vote::update: saving to $self->{'countfile'});
  unless(defined $self->{'id'}) {
    warn qq(Website::Utilities::Vote::update Cannot update without an id\n);
    return;
  }
  eval {
    open(FOUT, ">$self->{'countfile'}") or die $!;
    print FOUT $self->{'counts'}, "\n" or die $!;
    close(FOUT) or die $!;
  };
  warn $@ if($@);
}

1;
