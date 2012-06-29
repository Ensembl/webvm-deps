package Website::Utilities::Find;
#########
# rmp 2002-02-18
# a taint-safe File::Find
# because the 5.004_04 version sucks
#

sub new {
  my ($class, $ref) = @_;
  my $self = {
	      'results' => [],
	      'type'    => 'f',
	     };
  bless($self, $class);

  for my $f (qw(dir)) {
    $self->{$f} = $ref->{$f} if(defined $ref->{$f});
  }

  return $self;
}

sub dir {
  my ($self, $dir) = @_;
  $self->{'dir'} = $dir if(defined $dir);
  return $self->{'dir'};
}

sub type {
  my ($self, $type) = @_;
  $self->{'type'} = $type if(defined $type);
  return $self->{'type'};
}

sub find {
  my ($self) = @_;

  my $dir  = $self->dir();
  my $type = $self->type();

  opendir DIR, "$dir";
  my @files = readdir DIR;
  closedir DIR;

  for my $f (@files) {
    #########
    # don't chase your tail
    #
    next if($f eq "." || $f eq "..");

    #########
    # woah! don't traverse symlinks!
    #
    next if(-l "$dir/$f");

    if(-d "$dir/$f") {
      #########
      # recurse subdirs
      #
      push @{$self->{'results'}}, "$dir/$f" if(!defined $type || $type eq "d");
      my $find = Website::Utilities::Find->new({
						'dir'  => "$dir/$f",
						'type' => $type,
					       });
      push @{$self->{'results'}}, $find->find();

    } else {
      #########
      # store files
      #
      push @{$self->{'results'}}, "$dir/$f";
    }
  }

  return @{$self->{'results'}};
}

1;
