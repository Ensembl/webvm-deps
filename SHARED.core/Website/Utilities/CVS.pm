package Website::Utilities::CVS;
#########
# CVS helper utility
# rmp 2002-01-09
#
use strict;
use vars qw($CVS);
$CVS = "/usr/local/bin/cvs";

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);
  return $self;
}

sub versioned_file {
    my ($self, $filename, $rev) = @_;

    $filename = &safe_filename($filename);
    $rev      = &safe_rev($rev);

    open(IN, qq($CVS update -p -r$rev "$filename" 2>/dev/null |));
    local $/;
    undef $/;
    my $file=<IN>;
    close IN;
    return $file;
}

sub version {
  my ($self, $filename) = @_;

  $filename = &safe_filename($filename);
  open(IN, qq($CVS log -l "$filename" 2>/dev/null |));
  local $/;
  undef $/;
  my $content = <IN> || "";
  close IN;

  if ($content =~ /head: (.*?)\n/) {
    return $1;
  } else {
    return "1.0";
  }
}

sub add {
  my ($self, $filename) = @_;

  $filename = &safe_filename($filename);

  open(IN, qq($CVS add "$filename" 2>/dev/null |));
  my $status = <IN>;
  unless(close (IN)){
#    &mailErrors("Problems cvs add of $filename\n");
  }
}

sub delete {
  my ($self, $filename) = @_;

  $filename = &safe_filename($filename);

  open(IN, qq($CVS delete "$filename" 2>/dev/null |));
  my $status = <IN>;
  unless(close (IN)){
#    &mailErrors("Problems cvs add of $filename\n");
  }
}

sub commit {
  my ($self, $filename, $msg) = @_;

  $filename = &safe_filename($filename);
  $msg      = &safe_msg($msg);

  open(IN, qq($CVS commit -m "$msg" "$filename" 2>/dev/null |));
  my $status = <IN>;
  unless(close (IN)){
#    &mailErrors("Problems cvs commit of $filename\n");
  }
}

sub history {
  my ($self, $filename) = @_;

  $filename       = &safe_filename($filename);
  my $content     = "";
  my $rev_counter = 0;
  my $rec_flag    = undef;

  open(IN, qq($CVS log -l "$filename" 2>/dev/null |));
  while(defined (my $line = <IN>)) {

    if($line =~ /^revision/ && !defined $rec_flag) {
      $rec_flag = 1;
    }

    if(defined $rec_flag) {
      $content .= $line;

      if($line =~ /^revision/) {
	$rev_counter++;
      }
    }

    last if($rev_counter == 10);
  }

  close IN;

  return $content;
}

sub safe_filename {
    my ($filename) = @_;
    ($filename)    = $filename =~ /([a-zA-Z0-9\/\!\"\'\$\%\^\&\(\)\[\]\{\}\:\@\~\#\,\.\-_\+=]+)/;
    return $filename;
}

sub safe_rev {
    my ($rev) = @_;
    ($rev)    = $rev =~ /([0-9.]+)/;
    return $rev;
}

sub safe_msg {
    my ($msg) = @_;
    ($msg)    = $msg =~ /([a-zA-Z0-9\/\!\"\'\$\%\^\&\(\)\[\]\{\}\:\@\~\#\,\.\-_\+=]+)/;
    return $msg;
}

1;
