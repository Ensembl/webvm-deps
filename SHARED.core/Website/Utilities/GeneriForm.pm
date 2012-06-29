#########
# Author: rmp
# Maintainer: rmp
# Created: 2004-03-06
# Last Modified: 2004-03-06
#
# Generic form, smart bits.
#
package Website::Utilities::GeneriForm;
use strict;
use Config::IniFiles;
use Website::Utilities::Template;
use Website::Utilities::Mail;
use DBI;
use vars qw($AUTOLOAD);

sub new {
  my ($class, $ref) = @_;
  my $self = {
	      'fieldtoname' => {},
	      'data'        => {},
	     };
  bless $self, $class;

  if($ref->{'config'}) {
    $self->{'config'} = $ref->{'config'};
    $self->load_config();
  }
  $self->{'action'} = $ref->{'action'};

  return $self;
}

sub load_config {
  my $self = shift;

  $self->{'conf'} ||= Config::IniFiles->new(
					    -file => $self->{'config'},
					   );
}

sub inifile {
  my $self = shift;
  return $self->conf->val("general","inifile");
}

sub title {
  my $self = shift;
  return $self->conf->val("general","title");
}

sub banner {
  my $self = shift;
  return $self->conf->val("general","banner");
}

sub author {
  my $self = shift;
  return $self->conf->val("general","author");
}

sub include {
  my $self = shift;
  return ($self->conf->val("general","include") eq "yes");
}

sub fields {
  my $self = shift;
  if($self->conf() &&
     $self->conf->SectionExists("widgets")) {
    return $self->conf->Parameters("widgets");
  }
}

sub names {
  my $self = shift;
  my $seen = {};

 F: for my $f ($self->fields()) {
    my $settings = $self->conf->val("widgets", $f);
  S: for my $setting (split(',', $settings)) {
      my ($field, $val) = split(':', $setting);
      next S unless($field eq "name");
      $seen->{$val}++;
      $self->{'fieldtoname'}->{$f} = $val;
      next F;
    }
    $seen->{$f}++;
    $self->{'fieldtoname'}->{$f} = $f;
  }

  return keys %$seen;
}

sub name_by_field {
  my ($self, $f) = @_;
  #########
  # initialise fieldtoname hash
  #
  $self->names();

  return $self->{'fieldtoname'}->{$f};
}

sub conf {
  my ($self, $conf) = @_;
  $self->{'conf'}   = $conf if($conf);
  return $self->{'conf'};
}

sub build_widgets {
  my ($self, $options) = @_;
  my $ref  = {};
  my $seen = {};

  for my $f ($self->fields()) {

    my $settings = $self->conf->val("widgets", $f);
    my $opt = {
	       'name' => $f,
	      };
    for my $setting (split(',', $settings)) {
      my ($field, $val) = split(':', $setting);
      $opt->{$field}    = $val if($val);
      $opt->{"_$field"} = $val if($val);

      if($options->{'read_defaults'} && $field eq "checked") {
	$opt->{'checked'} = 1;
      } elsif($field eq "selected") {
	$opt->{'selected'} = 1;
      }
    }

    if($options->{'override_type'}) {
      $opt->{'type'}    = "hidden";

      #########
      # skip creation of duplicate names for hidden form values
      #
      if($seen->{$opt->{'name'}||$f}++) {
	$ref->{$f} = "";
	next;
      }
    }

    #########
    # remember defaults - useful for radiobutton checking
    #
    $opt->{'default_value'} = $opt->{'value'};

    $opt->{'type'}  ||= "text";
    if($opt->{'type'} =~ /^(text|hidden|checkbox|radio)$/) {
      $opt->{'type'}  = sprintf(qq(input type="%s"), $opt->{'type'});
    }

    if($self->{'data'}->{$opt->{'name'}}) {
      $opt->{'value'} = $self->{'data'}->{$opt->{'name'}};
    }

    if($opt->{'type'} eq "selectmultiple") {
      $opt->{'size'} ||= 4;
    }

    if($opt->{'type'} =~ /checkbox|radio/) {
      $opt->{'checked'} = " checked" if(
					$opt->{'checked'} ||
					($self->{'data'}->{$opt->{'name'}} &&
					 $opt->{'default_value'} &&
					 $self->{'data'}->{$opt->{'name'}} eq $opt->{'default_value'})
				       );
    }

    for my $f (qw(name rows cols size maxlength value wrap)) {
      if($opt->{$f}) {
	next if($f eq "value" && $opt->{'type'} eq "textarea" );
	$opt->{$f} = sprintf(qq( $f="%s"), $opt->{$f});
      }
    }

    if($opt->{'type'} =~ /textarea/ ) {
      $opt->{'content'}  = ">" . ($opt->{'value'}||"");
      $opt->{'value'}    = "";
      $opt->{'closetag'} = "</" . $opt->{'type'};

    } elsif($opt->{'type'} =~ /select/) {
      $opt->{'content'}  = ">" . $opt->{'value'};
      $opt->{'closetag'} = "</" . $opt->{'type'};

    } else {
      $opt->{'closetag'} = " /";
    }

    if($opt->{'type'} eq "textarea") {
      $opt->{'wrap'}    ||= "virtual";
      $opt->{'maxlength'} = "";
      $opt->{'size'}      = "";

    } else {
      $opt->{'wrap'} = "";
      $opt->{'rows'} = "";
      $opt->{'cols'} = "";
    }


    if($opt->{'type'} eq "select" || $opt->{'type'} eq "selectmultiple") {
      my @sels   = split(/\|/, $opt->{'value'});
      my @opts   = split(/\|/, $opt->{'options'});
      $ref->{$f} = sprintf("<select %s %s %s>\n%s\n</select>",
			   ($opt->{'type'} eq "selectmultiple")?"multiple":"",
			   $opt->{'name'}     || "",
			   $opt->{'size'}     || "",
			   join("\n",
				map {
				  my $o   = $_;
				  my $sel = (grep { /$o/ } @sels)?"selected":"";
				  qq(<option value="$o" $sel>$o</option>);
				} @opts));
    } else {
      $ref->{$f} = sprintf("<%s%s%s%s%s%s%s%s%s%s%s>",
			   $opt->{'type'}      || "",
			   $opt->{'name'}      || "",
			   $opt->{'rows'}      || "",
			   $opt->{'cols'}      || "",
			   $opt->{'size'}      || "",
			   $opt->{'maxlength'} || "",
			   $opt->{'checked'}   || "",
			   $opt->{'selected'}  || "",
			   $opt->{'value'}     || "",
			   $opt->{'content'}   || "",
			   $opt->{'closetag'}  || "",
			  );
    }
  }

  $ref->{'begin_form'}    = qq(<form method="POST" action="$ENV{'SCRIPT_NAME'}">\n@{[$self->safeconfig()]});
  $ref->{'end_form'}      = qq(</form>);

  return $ref;
}

sub safeconfig {
  my $self       = shift;
  my $hostroot   = $ENV{'DOCUMENT_ROOT'};
  $hostroot      =~ s/htdocs\/?//;
  my $safeconfig = $self->{'config'};
  $safeconfig    =~ s/$hostroot//;
  return qq(<input type="hidden" name="config" value="$safeconfig" />);
}

sub form {
  my $self          = shift;
  my $htx           = $self->conf->val("form", "template") || $self->conf->val("general", "template");
  my $read_defaults = undef;
  $read_defaults    = 1 if(!$self->{'action'});
  my $ref           = $self->build_widgets({
					    'read_defaults' => 1,
					   });
  $ref->{'submit'}  = qq(<input type="submit" name="action" value="review" />);
  $ref->{'edit'}    = "";
  my $tmpl          = Website::Utilities::Template->new({
							'htx' => $htx,
						       });
  return $tmpl->generate($ref);
}

sub review {
  my $self         = shift;
  my $htx          = $self->conf->val("review", "template") || $self->conf->val("general", "template");
  my $ref          = $self->build_widgets({
					   'override_type' => 1,
					  });
  $ref->{'submit'} = qq(<input type="submit" name="action" value="submit" />);
  $ref->{'edit'}   = qq(<input type="submit" name="action" value="edit" />);
  my $tmpl         = Website::Utilities::Template->new({
							'htx' => $htx,
						       });
  my $seen = {};

  for my $f ($self->fields()) {
    my $name = $self->name_by_field($f);
    next if($seen->{$name}++);
    $ref->{$f} .= $self->{'data'}->{$name};
  }

  return $tmpl->generate($ref);
}

sub submit {
  my $self         = shift;
  my $htx          = $self->conf->val("submit", "template") ||
    $self->conf->val("review", "template") ||
      $self->conf->val("general", "template");
  my $ref          = $self->build_widgets({
					  'override_type' => 1,
					  });
  $ref->{'submit'} = "";
  $ref->{'edit'}   = "";

  my $tmpl = Website::Utilities::Template->new({
						'htx' => $htx,
					       });
  my $seen = {};

  for my $f ($self->fields()) {
    my $name = $self->name_by_field($f);
    next if($seen->{$name}++);
    $ref->{$f}    = $self->{'data'}->{$name};
    $ref->{$name} = $self->{'data'}->{$name} if($f ne $name);
  }

  my $target = $self->conf->val("submit", "targets") || $self->conf->val("submit", "target") || "email";

  my $content = "";
  for my $t (split(',', $target)) {
    my $method = "target_$t";
    unless($self->can($method)) {
      print STDERR qq(GeneriForm::submit: Unknown method: $method!\n);
      $content .= qq(Unknown target method ($method)\n);
      next;
    }
    $self->$method($ref);
  }
  return $content . $tmpl->generate($ref);
}

sub AUTOLOAD {
  my ($self, $val) = @_;
  my ($func)       = $AUTOLOAD =~ /^.*::(.*?)$/;

  $self->{'data'}->{$func} = $val if($val);
  return $self->{'data'}->{$func};
}

sub target_email {
  my ($self, $ref) = @_;
  my $htx          = $self->conf->val("submit", "emailtemplate") ||
    $self->conf->val("submit", "email_template") ||
      $self->conf->val("submit", "template") ||
	$self->conf->val("review", "template") ||
	  $self->conf->val("general", "template");

  my $tmpl = Website::Utilities::Template->new({
						'htx' => $htx,
					       });

  my $to   = $self->conf->val("submit", "to");
  my $cc   = $self->conf->val("submit", "cc");
  my $bcc  = $self->conf->val("submit", "bcc");
  my $from = $self->conf->val("submit", "from")    || "w3adm";
  my $subj = $self->conf->val("submit", "subject") || "Electronic Form Submission";

  Website::Utilities::Mail->new({
				 'to'      => $to,
				 'cc'      => $cc,
				 'bcc'     => $bcc,
				 'from'    => $from,
				 'subject' => $subj,
				 'message' => $tmpl->generate($ref),
				})->send();
}

sub target_dbi {
  my ($self, $ref) = @_;

  my $info = {};
  for my $f (qw(dbhost dbport dbname dbuser dbpassword dbtable)) {
    $info->{$f} = $self->conf->val("submit", $f);
  }

  #########
  # set defaults
  #
  $info->{'dbhost'} ||= "webdbsrv1";
  $info->{'dbport'} ||= 3306;
  $info->{'dbname'} ||= "generiform";
  $info->{'dbuser'} ||= "generiformrw";

  eval {
    my $dbh = DBI->connect("DBI:mysql:database=$info->{'dbname'};host=$info->{'dbhost'};port=$info->{'dbport'}",
			   $info->{'dbuser'}, $info->{'dbpassword'}, { RaiseError => 1 });
    my @names = sort $self->names();
    my $insert = qq(INSERT INTO $info->{'dbtable'}
		    (@{[join(',', @names)]})
		    VALUES(@{[join(',', map { $dbh->quote($ref->{$_}||"") } @names)]}));
    print STDERR $insert, "\n";
    $dbh->do($insert);
  };
  warn $@ if($@);
}

1;
