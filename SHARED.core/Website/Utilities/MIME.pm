package Website::Utilities::MIME;
#########
# MIME types helper
# Author: rmp
# Created: 2001-01-09
# Last Modified: 2003-12-09
#
use vars qw($DEBUG);

sub new {
  my ($class) = @_;
  my @MIME_TYPES = qw(/GPFS/data1/WWW/conf/mime.types);
#		      /nfs/WWW/conf/mime.types
#		      /nfs/WWWdev/conf/mime.types);

  my $self = {
	      'mime_types' => \@MIME_TYPES,
	     };
  bless($self, $class);

  $self->init();

  return $self;
}

sub init {
  my ($self) = @_;
  my $fh;
  for my $f (@{$self->{'mime_types'}}) {
    eval {
      open($fh, $f) or die;
      $/ = "\n";
      while(defined(my $l = <$fh>)) {
	chomp $l;
	next if ($l =~ /^\s*\#/);
		 
	my ($encoding, @suffixes) = split(/\s+/, $l);
	next if(scalar @suffixes == 0); # no suffixes
	$self->add_type($encoding, \@suffixes);
	$DEBUG and print STDERR "Loaded $encoding for @suffixes\n";
      }
      close($fh);
    };
  }
}

sub add_type {
  my ($self, $encoding, $suf_ref) = @_;
  $self->{'encodings'}->{$encoding} = $suf_ref;
}

sub by_type {
  my ($self, $encoding) = @_;
  return unless(exists $self->{'encodings'}->{$encoding});

  my $enc = (@{$self->{'encodings'}->{$encoding}})[0];
  ($enc)  = $enc =~ m|([a-z/0-9\-]+)|;
  return $enc;
}

sub by_suffix {
  my ($self, $path) = @_;
  my ($suffix)      = $path =~ /([^\.]+)$/;

  return "text/plain" if(!defined $suffix);
  $suffix = lc($suffix);

  if(defined $self->{'reverse_cache'}->{$suffix}) {
    return $self->{'reverse_cache'}->{$suffix};

  } else {
    for my $k (keys %{$self->{'encodings'}}) {
      for my $s (@{$self->{'encodings'}->{$k}}) {
	if($s eq $suffix) {
	  $self->{'reverse_cache'}->{$suffix} = $k;
	  ($k) = $k =~ m|([a-z/0-9\-\.]+)|;
	  return $k;
	}
      }
    }
  }
  $DEBUG and warn qq(No encoding found for suffix $suffix);
  return "text/plain";
}

1;
