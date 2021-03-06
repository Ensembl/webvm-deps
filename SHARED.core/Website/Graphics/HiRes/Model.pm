#########
# Author:        rmp
# Maintainer:    $Author: jc3 $
# Created:       2006-10-31
# Last Modified: $Date: 2007/07/02 13:45:32 $
# Id:            $Id: Model.pm,v 1.4 2007/07/02 13:45:32 jc3 Exp $
# Source:        $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/Graphics/HiRes/Model.pm,v $
# $HeadURL$
#
#
package Website::Graphics::HiRes::Model;
use strict;
use warnings;
use DBI;
use English qw(-no_match_vars);
use Carp;

our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };
our $DBHOST  = 'webdbsrv';
our $DBNAME  = 'imaging01';
our $DBPORT  = 3306;
our $DBUSER  = 'imagingrw';
our $DBPASS  = '6r7RnqvR';

sub fields { return qw(hash name pixel_width pixel_height zoom_minimum zoom_maximum username copyright); }

sub new {
  my ($class, $self) = @_;
  $self  ||= {};
  bless $self, $class;

  if($self->{'hash'} && !$self->{'noload'}) {
    $self->load();
  }
  return $self;
}

sub dbname { return $DBNAME; }
sub dbhost { return $DBHOST; }
sub dbport { return $DBPORT; }
sub dbuser { return $DBUSER; }
sub dbpass { return $DBPASS; }

sub dbh {
  my $self = shift;

  if(!$self->{'dbh'}) {
    my $dsn = sprintf 'DBI:mysql:database=%s;host=%s;port=%s',
                      $self->dbname(),
		      $self->dbhost(),
		      $self->dbport();
    $self->{'dbh'} = DBI->connect_cached($dsn,
					 $self->dbuser(),
					 $self->dbpass(),
					 {
					  RaiseError => 1,
					 });

  }
  return $self->{'dbh'};
}

sub _accessor {
  my ($self, $field, $val) = @_;
  if(defined $val) {
    $self->{$field} = $val;
    delete $self->{'_loaded'};
  }
  return $self->{$field};
}

sub hash         { my $self = shift; return $self->_accessor('hash',         @_); }
sub name         { my $self = shift; return $self->_accessor('name',         @_); }
sub pixel_width  { my $self = shift; return $self->_accessor('pixel_width',  @_); }
sub pixel_height { my $self = shift; return $self->_accessor('pixel_height', @_); }
sub zoom_minimum { my $self = shift; return $self->_accessor('zoom_minimum', @_); }
sub zoom_maximum { my $self = shift; return $self->_accessor('zoom_maximum', @_); }
sub username     { my $self = shift; return $self->_accessor('username',     @_); }
sub copyright    { my $self = shift; return $self->_accessor('copyright',     @_); }

sub hashdir {
  my $self = shift;
  my $hash = $self->hash();
  $hash    =~ s|^(.{3})(.{3})(.{3})|$1/$2/$3/|mx;
  return $hash;
}

sub load {
  my $self = shift;
  my $pk   = 'hash';

  if(!$self->{'_loaded'}) {
    eval {
      my $query = qq(SELECT @{[join ', ', $self->fields()]}
                     FROM   image
                     WHERE  $pk=?);

      my $sth   = $self->dbh->prepare($query);
      $sth->execute($self->{$pk});
      my $ref   = $sth->fetchrow_hashref();
      
      if ($self->{$pk} != $ref->{$pk}) {
        die "Image @{[$self->{$pk}]} was not found in the database!";
      }
        
      for my $f ($self->fields()) {
	$self->{$f} = $ref->{$f};
      }
      $sth->finish();
    };
    $EVAL_ERROR and carp $EVAL_ERROR;
  }
  $self->{'_loaded'} = 1;
  return $self;
}

sub save {
  my $self  = shift;
  my $dbh   = $self->dbh();
  my $query = qq(REPLACE INTO image (@{[join(', ', $self->fields())]})
                 VALUES (@{[join ', ', map { '?' } $self->fields()]}));
  eval {
    $self->dbh->do($query, {}, map { $self->$_() } $self->fields());
  };

  $EVAL_ERROR and warn $EVAL_ERROR;
}

sub DESTROY {
  my $self = shift;
  delete $self->{'dbh'};
  return;
}

1;

__END__

=head1 NAME

Website::Graphics::hires - an API into the Hi-res Image RESource (HIRES)

=head1 VERSION

$Revision: 1.4 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 fields : Array of accessors

  my @fields = $oHIRES->fields();
  my @fields = Website::Graphics::hires->fields();

=head2 new : Constructor

  my $oHIRES = Website::Graphics::hires->new();

=head2 dbname : Name of database to connect to

  my $dbname = $oHIRES->dbname();

=head2 dbhost : Hostname of database server

  my $dbhost = $oHIRES->dbhost();

=head2 dbport : Port of database instance

  my $dbport = $oHIRES->dbport();

=head2 dbuser : Username to connect as

  my $dbuser = $oHIRES->dbuser();

=head2 dbpass : Password to use

  my $dbpass = $oHIRES->dbpass();

=head2 dbh : A database handle into the image meta-data store

  my $dbh = $oHIRES->dbh();

=head2 hash : Get/set accessor for primary key (hashed identifier) of image

  my $sValue = $oHIRES->hash();
  $oHIRES->hash($sNewValue);

=head2 name : Get/set accessor for original filename of image

  my $sValue = $oHIRES->name();
  $oHIRES->name($sNewValue);

=head2 pixel_width : Get/set accessor for x-dimension of original image

  my $sValue = $oHIRES->pixel_width();
  $oHIRES->pixel_width($sNewValue);

=head2 pixel_height : Get/set accessor for y-dimension of original image

  my $sValue = $oHIRES->pixel_height();
  $oHIRES->pixel_height($sNewValue);

=head2 username : Most recent uploader of this image

  my $sValue = $oHIRES->username();
  $oHIRES->username($sNewValue);

=head2 zoom_minimum : Most recent uploader of this image

  my $sValue = $oHIRES->zoom_minimum();
  $oHIRES->zoom_minimum($sNewValue);

=head2 zoom_maximum : Most recent uploader of this image

  my $sValue = $oHIRES->zoom_maximum();
  $oHIRES->zoom_maximum($sNewValue);

=head2 load : Load from the database against our primary key 'hash'

  $oHIRES->load();

=head2 save : Save into database against our primary key 'hash'

  $oHIRES->save();

=head2 render : Render HTML+Javascript for the configured image

  print $oHIRES->render();

=head2 DESTROY

  $oHIRES->DESTROY();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: jc3 $

=head1 LICENSE AND COPYRIGHT

=cut
