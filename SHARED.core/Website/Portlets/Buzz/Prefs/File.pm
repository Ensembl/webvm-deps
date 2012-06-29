#########
# Author: rmp@psyphi.net
#
package Website::Portlets::Buzz::Prefs::File;
use strict;
use Fcntl qw(:flock);
use Website::Portlets::Buzz::Prefs;
use vars qw(@ISA $BUZZRC);
@ISA    = qw(Website::Portlets::Buzz::Prefs);
$BUZZRC = "$ENV{'HOME'}/.buzzrc";

sub buzzrc {
  my ($self) = @_;
  my ($brc)  = $BUZZRC =~ m|([a-zA-Z0-9/\._]+)|;
  unless(-f $BUZZRC) {
    my ($brc) = $BUZZRC =~ m|([0-9a-zA-Z/_\.]+)|;
    `touch $brc`;
  }
  return $brc;
}

sub _feeds {
  my ($self) = @_;
  my ($fh, $content);
  eval {
    open($fh, $self->buzzrc()) or die;
    local $/ = undef;
    $content = <$fh>;
    close($fh);
  };
  $content ||= "";

  return ($content =~ /feed=(.*?)\n/smig);
}

sub add_feed {
  my ($self, $url) = @_;

  my $fh;
  open($fh, "+<@{[$self->buzzrc()]}");
  flock($fh, LOCK_EX);

  local $/    = undef;
  my $content = <$fh>;
  $content   .= "feed=$url\n";

  seek($fh, 0, 0);

  print $fh $content;

  flock($fh, LOCK_UN);
}

sub delete_feed {
  my ($self, $arg) = @_;

  my $fh;
  open($fh, "+<@{[$self->buzzrc()]}");
  flock($fh, LOCK_EX);

  local $/    = undef;
  my $content = <$fh>;

  if($arg =~ /^\d+$/) {
    my @arr = split("\n", $content);
    splice(@arr, $arg, 1);
    $content  = join("\n", @arr);
    $content .= "\n";
  } else {
    $content =~ s/feed=$arg\n//sm;
  }

  truncate($fh, 0);
  seek($fh, 0, 0);
  print $fh $content;

  flock($fh, LOCK_UN);
}
1;
