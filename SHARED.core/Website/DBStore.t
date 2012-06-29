use strict;
use warnings;
use Test::More tests => 200;
use SangerPaths qw(core);
use Website::DBStore;
use Website::Utilities::IdGenerator;
use Carp;

my $dbstore = Website::DBStore->new();
for my $i (1..100) {
  my $blobostuff = join q(), map { chr int rand 255 } (1..1024*(int rand 100));
  $blobostuff  ||= q();
  my $is_perm    = int rand 2;
  my $id         = $dbstore->set($blobostuff, undef, undef, $is_perm);
  my $fromdb     = $dbstore->get($id);

  is($blobostuff, $fromdb, q(Get/set without id ok));
}

$dbstore = Website::DBStore->new();
for my $i (1..100) {
  my $blobostuff = join q(), map { chr int rand 255 } (1..1024*(int rand 100));
  $blobostuff  ||= q();
  my $is_perm    = int rand 2;
  my $id         = Website::Utilities::IdGenerator->get_unique_id();

  $dbstore->set($blobostuff, $id, undef, $is_perm);
  my $fromdb     = $dbstore->get($id);

  is($blobostuff, $fromdb, q(Get/set with id ok));
}
