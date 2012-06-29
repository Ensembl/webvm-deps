#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2002-02-21
# Last Modified: $Date: 2008/01/31 14:56:38 $
# Id:            $Id: Template.pm,v 1.4 2008/01/31 14:56:38 rmp Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/Utilities/Template.pm,v $
# $HeadURL$
#
package Website::Utilities::Template;
use strict;
use warnings;
use Scalar::Util qw(weaken);
use CGI qw(escape escapeHTML);
use English qw(-no_match_vars);
use Carp;

our $DEFAULT_WRAP_LEN = 60;
our $VERSION          = do { my @r = (q$Revision: 1.4 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

sub new {
  my ($class, $ref) = @_;
  my $self = {};
  bless $self, $class;

  for my $k (qw(htx template callback)) {
    if(defined $ref->{$k}) {
      $self->{$k} = $ref->{$k};
    }
  }

  if(defined $self->htx()) {
    $self->load();
  }

  return $self;
}

sub htx {
  my ($self, $htx) = @_;
  if(defined $htx) {
    $self->{'htx'} = $htx;
  }
  return $self->{'htx'};
}

sub template {
  my ($self, $template) = @_;
  if(defined $template) {
    $self->{'template'} = $template;
  }
  return $self->{'template'};
}

sub callback {
  my ($self, $callback) = @_;
  if(defined $callback) {
    $self->{'callback'} = $callback;
  }
  return $self->{'callback'};
}

sub load {
  my ($self) = @_;
  my ($htx)  = $self->htx() =~ m|([a-zA-Z0-9\./_\-]+)|mx;

  if($htx && !-f $htx) {
    carp qq(Could not find file '$htx');
    return;
  }

  eval {
    local $RS = undef;
    open my $fin, q(<), $htx or croak $ERRNO;
    $self->{'template'} = <$fin>;
    close $fin;
  };

  if(!$self->{'template'}) {
    carp q(Failed to load any data from template file);
    return 0;
  }

  if($EVAL_ERROR) {
    carp $EVAL_ERROR;
    return 0;

  } else {
    return 1;
  }
}

sub generate {
  my ($self, $defs, $content, $depth) = @_;

  $depth   ||= 1;
  if(!defined $content) {
    $content = $self->{'template'};
  }
  if(!defined $content) {
    carp qq(No template data found htx=@{[$self->htx()||q()]});
    $content = q();
  }

  eval {
    my $ref = ref $defs;
    if($defs && $ref    &&
       $ref ne 'ARRAY'  &&
       $ref ne 'SCALAR' &&
       $ref ne 'CODE') {
      for my $f (qw(SCRIPT_NAME PATH_INFO QUERY_STRING HTTP_HOST)) {
	$defs->{$f} ||= $ENV{$f} || q();
      }
    }
  };

  #########
  # Switch out element lists
  #
  $content =~ s/XXX_([a-z0-9_\%\.\-]+?)_\[(.*?)\]_\1_XXX/&_switchout($self, $1, $defs, $2, $depth+1)/smegix;

  #########
  # switch out sticky settings
  #
  for my $sticky (qw(checked selected)) {
    $content =~ s#XXX_${sticky}_([a-z0-9_\%\.\-]+?)_XXX#{
                                                         if($defs->{'___parent'}) {
                                                           my $p = $defs->{'___parent'}->{$1};
                                                           my $c = $defs->{$1};
                                                           if(!$p) { eval { $p = $defs->{'___parent'}->$1; }; }
                                                           if(!$c) { eval { $c = $defs->$1; }; }
                                                           ($p && $c && ($p eq $c))?$sticky:q();
                                                         } else { 'foo'; }
                                                        }#smegix;
  }

  #########
  # Switch out basic elements using coderefs or hash elements
  #
  $content =~ s/XXX_([a-z0-9_\%\.\-]+?)_XXX/&_switchout($self, $1, $defs)/smegix;

  #########
  # Switch out ternary operations
  #
  $content =~ s/XXX_([a-z0-9_\%\.\-]+?)_\?(.*?)\?_\1_:(.*?)\?_\1_XXX/$self->_ternary($defs, $1, $2, $3, $depth)/smegix;

  return $content;
}

sub _ternary {
  my ($self, $defs, $arg1, $arg2, $arg3, $depth) = @_;
  my $data = undef;
  eval {
    #########
    # See if we can call a method
    #
    $data = $defs->$arg1;
  };
  if($EVAL_ERROR) {
    eval {
      #########
      # See if we can pull a hash value
      #
      $data = $defs->{$arg1};
    };
  }

  my $ref = ref $data;
  if($ref) {
    if($ref eq 'ARRAY') {
      $data = scalar @{$data};

    } elsif($ref eq 'HASH') {
      $data = scalar keys %{$data};
    }
  }

  return $self->generate($defs, $data?$arg2:$arg3, $depth+1);
}

sub _switchout {
  my ($self, $k, $defs, $subtemplate, $depth) = @_;

  #########
  # Run the callback, if present.
  # This can be used to give the user feedback that the page is loading
  #
  my $cb = $self->{'callback'};
  if($cb && ref $cb eq 'CODE') {
    &{$cb}($k, $depth, $defs);
  }

  #########
  # key may be of the form: %20s_thing
  # If so, trap the value for sprintf'ing later, and change $k to be what it should be
  #
  my $k_orig    = $k;
  my ($sprintf) = $k =~ /^(%\-?[\d\.]*[Eesdfw])_/mx;
  if($sprintf) {
    $k =~ s/^${sprintf}_//mx;
  }

  if(!ref $defs) {
    croak "failure for k=$k_orig\nsubtemplate=$subtemplate\ndepth=$depth\ndefs=$defs\n";
  }

  return $self->_switchout_substitution($k_orig, $sprintf, $self->_switchout_determination($defs, $k, $subtemplate, $depth));
}

sub _switchout_determination {
  my ($self, $defs, $k, $subtemplate, $depth) = @_;
  my ($val, $exists_flag);

  if(ref $defs eq 'ARRAY') {
    $val = $defs;

  } elsif(ref $defs ne 'SCALAR' && exists $defs->{$k}) {
    #########
    # not a scalar or array
    #
    $exists_flag = 1;
    $val         = $defs->{$k};
  }

  if($val && ref $val eq 'CODE') {
    #########
    # Next see run the code block if it was a code ref
    #
    eval {
      $val = &{$val}($defs);
    };
    $EVAL_ERROR and carp $EVAL_ERROR;

  } elsif(!(defined $val) && ref $defs ne 'ARRAY') {
    #########
    # Otherwise try and call the $val method on what we hope is an object
    #
    eval {
      if($defs->can($k)) {
	$exists_flag = 1;
      }
      $val = $defs->$k();
    };
  }

  if($val && ref $val eq 'ARRAY') {
    if($subtemplate) {
      #########
      # If we were called to perform an array population (element lists substitution, above)
      # Or the result of $defs->$k() is an array ref (e.g. an array of associated entities)
      # Then descend down using $subtemplate as the next chunk of template to use
      #
      my @tmp    = @{$val};
      my $newval = q();
      my $tabrow = 1;
      for my $el (@tmp) {
	if(ref $el && ref $el ne 'ARRAY') {
	  #########
	  # If we have an array of objects (or hashes) we can do some special things
	  #
	  $el->{'tabrow'} = $tabrow;
	}

	#########
	# store a WEAK! reference to each child's parent so it can be used to determine 'selected' or 'checked' settings
	#
	eval { weaken($el->{'___parent'} = $defs); };

	$newval .= $self->generate($el, $subtemplate, $depth);
	$tabrow  = 1+!($tabrow-1);
      }
      $val = $newval;

    } elsif($k =~ /^\d+$/mx) {
      #########
      # If a plain array index was requested, drop the value straight in
      #
      $exists_flag = 1;
      $val         = $val->[$k];
    } else {
      undef $val;
    }
  }

  return ($exists_flag, $val);
}

sub _switchout_substitution {
  my ($self, $k, $sprintf, $exists_flag, $val) = @_;

  if($exists_flag) {
    if(!defined $val) {
      $val = q();
    }

    if($sprintf) {
      if($sprintf =~ /\d+w/mx) {
	#########
	# A Text::Wrap directive
	#
	my ($len)  = $sprintf =~ /(\d+)/mx;
	$len     ||= $DEFAULT_WRAP_LEN;
	my $lineno = 0;
	my @out;
	$val       =~ s/[\r\n]+/ /smgx;
	$val       =~ s/\t/        /smgx;
	my @in     = split /\s/mx, $val;
	my $line   = q();
	my $buf    = 0;

	for my $w (@in) {
	  my $tmp = $line . ($line?q( ):q()) . $w;

	  if(length $tmp <= $len) {
	    $line = $tmp;
	    $buf  = 1;

	  } else {
	    push @out, $line;
	    $line = $w;
	    $buf  = 0;
	  }
	}

	if($buf) {
	  pop @out;
	  push @out, $line;
	}
	$val = join "\n", @out;

	return $val;
      }

      if($sprintf =~ /[df]/mx) {
	$val ||= '0';
      }

      if($sprintf eq '%e') {
	return escapeHTML($val);
      }

      if($sprintf eq '%E') {
	return escape($val);
      }
      return sprintf $sprintf, $val;
    }
    return $val;
  }

  return $val || "XXX_${k}_XXX";
}

1;

__END__

=head1 NAME

Website::Utilities::Template - A simple, lightweight templating system

=head1 VERSION

$Revision: 1.4 $

=head1 SYNOPSIS

use Website::Utilities::Template;
my $template = Website::Utilities::Template->new({
  'htx' => '/path/to/template/file.htx',
});

print $template->generate($object);

=head1 DESCRIPTION

A simple, easy to use templating system with almost no dependencies.

=head1 SUBROUTINES/METHODS

=head2 new : constructor

 my $template = Website::Utilities::Template->new({
   'htx'      => '/path/to/template.htx',   # external template file
   'template' => q(...),                    # template data
   'callback' => sub { },                   # block callback
 });

=head2 htx : get/set accessor for the html template file

 $template->htx('/path/to/template.htx');

 my $htxfile = $template->htx();

=head2 template : get/set accessor for template data

 $template->template(q(XXX....XXX));

 my $templatedata = $template->template();

=head2 callback get/set access for callback code ref

 $template->callback(sub {my ($sKey, $iDepth, $hrData) = @_; ....});

 my $cCallback = $template->callback();

=head2 load : loads an htx file inside new()

 $template->htx('/path/to/template.htx');
 $template->load();

=head2 generate : Process given data into template

 my $sProcessed = $template->generate($entity, $template_block);

 $entity can be object, hashref or arrayref.
 $template_block is optional and useful for processing dynamic templates

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Scalar interpolation

 XXX_foo_XXX

 Suitable for hash keys or object methods.

=head2 Array interpolation

 XXX_foo_[ ... ]_foo_XXX

=head2 Ternary conditional

 XXX_foo_? ...true... ?_foo_: ...false... ?_foo_XXX

=head1 DEPENDENCIES

 Scalar::Util
 CGI

=head1 INCOMPATIBILITIES

-

=head1 BUGS AND LIMITATIONS

Doesn't (yet) support template includes.

=head1 AUTHOR

Roger Pettett, E<lt>rmp@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 GRL, by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
