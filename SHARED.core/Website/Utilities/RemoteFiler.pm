#########
# Author:     rmp
# Maintainer: rmp
# Created:    2006-02-28
#
package Website::Utilities::RemoteFiler;
use strict;

=head2 new : Constructor

  my $rf = RemoteFiler->new({
    'user'   => 'bob',                # optional username
    'server' => 'cbi1',               # server name to ssh back to
    'path'   => '/path/to/somewhere', # optional directory root
  });

=cut
sub new {
  my ($class, $refs) = @_;
  my $self = {};
  bless $self, $class;
  for my $f (qw(server path user)) {
    $self->{$f} = $refs->{$f} if($refs->{$f});
  }
  return $self;
}

sub _ssh_cmd {
  my $self = shift;
  my $server = $self->{'server'} || "";
  my $user   = $self->{'user'}   || "";

  my $ssh = "ssh $server";
  if($user) {
    $ssh = "ssh $user\@$server";
  }

  return $ssh;
}

=head2 read_dir : Read remote directory contents

  my @dirlist = $rf->read_dir();               # read from 'path'
  my @dirlist = $rf->read_dir("subdirectory"); # read from 'path/subdirectory'

=cut
sub read_dir {
  my ($self, $subdir) = @_;
  my $ssh    = $self->_ssh_cmd();
  $subdir  ||= "";
  my $path   = $self->{'path'}."/".$subdir;
  my $fh;
  open($fh, "$ssh ls -1 $path|") or dir $!;
  my @list = map { chomp; $_ } <$fh>;
  close($fh);
  return @list;
}

=head2 read_file : Read remote file contents

  #########
  # Simple read for small files
  #
  my $contents = $rf->read_file("filename.txt");

  #########
  # Read with callback for large files
  #
  my $cb = sub { print $_[0]; };
  $rf->read_file("filename.txt", $cb);

=cut
sub read_file {
  my ($self, $filename, $cb) = @_;
  my $ssh  = $self->_ssh_cmd();
  my $path = $self->{'path'}."/".$filename;
  my $fh;
  open($fh, "$ssh cat $path|");
  binmode($fh);

  my $contents = "";

  if($cb && ref($cb) eq "CODE") {
    while(<$fh>) {
      &$cb($_);
    }
  } else {
    local $/ = undef;
    $contents = <$fh>;
  }

  close($fh);
  return $contents;
}

1;
