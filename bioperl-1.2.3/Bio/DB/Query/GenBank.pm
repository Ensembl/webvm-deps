# $Id: GenBank.pm,v 1.4.2.1 2003/09/09 21:28:52 lstein Exp $
#
# BioPerl module for Bio::DB::Query::GenBank.pm
#
# Cared for by Lincoln Stein <lstein@cshl.org>
#
# Copyright Lincoln Stein
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code
#

=head1 NAME

Bio::DB::Query::GenBank - Build a GenBank Entrez Query

=head1 SYNOPSIS

   my $query_string = 'Oryza[Organism] AND EST[Keyword]';
   my $query = Bio::DB::Query::GenBank->new(-db=>'nucleotide',
                                            -query=>$query_string,
					    -mindate => '2001',
					    -maxdate => '2002');
   my $count = $query->count;
   my @ids   = $query->ids;

   # get a genbank database handle
   my $gb = new Bio::DB::GenBank;
   my $stream = $gb->get_Stream_by_query($query);
   while (my $seq = $stream->next_seq) {
      ...
   }

   # initialize the list yourself
   my $query = Bio::DB::Query::GenBank->new(-ids=>[195052,2981014,11127914]);


=head1 DESCRIPTION

This class encapsulates NCBI Entrez queries.  It can be used to store
a list of GI numbers, to translate an Entrez query expression into a
list of GI numbers, or to count the number of terms that would be
returned by a query.  Once created, the query object can be passed to
a Bio::DB::GenBank object in order to retrieve the entries
corresponding to the query.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the
evolution of this and other Bioperl modules. Send
your comments and suggestions preferably to one
of the Bioperl mailing lists. Your participation
is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to
help us keep track the bugs and their resolution.
Bug reports can be submitted via email or the
web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Lincoln Stein

Email lstein@cshl.org

=head1 APPENDIX

The rest of the documentation details each of the
object methods. Internal methods are usually
preceded with a _

=cut

# Let the code begin...

package Bio::DB::Query::GenBank;
use strict;
use Bio::DB::Query::WebQuery;
use URI::Escape 'uri_unescape';

use constant EPOST               => 'http://www.ncbi.nih.gov/entrez/eutils/epost.fcgi';
use constant ESEARCH             => 'http://www.ncbi.nih.gov/entrez/eutils/esearch.fcgi';
use constant DEFAULT_DB          => 'protein';
use constant MAXENTRY            => 100;

use vars qw(@ISA @ATTRIBUTES $VERSION);

@ISA     = 'Bio::DB::Query::WebQuery';
$VERSION = '0.2';

BEGIN {
  @ATTRIBUTES = qw(db reldate mindate maxdate datetype);
  for my $method (@ATTRIBUTES) {
    eval <<END;
sub $method {
   my \$self = shift;
   my \$d    = \$self->{'_$method'};
   \$self->{'_$method'} = shift if \@_;
   \$d;
}
END
  }
}

=head2 new

 Title   : new
 Usage   : $db = Bio::DB::Query::GenBank->new(@args)
 Function: create new query object
 Returns : new query object
 Args    : -db       database ('protein' or 'nucleotide')
           -query    query string
           -mindate  minimum date to retrieve from
           -maxdate  maximum date to retrieve from
           -reldate  relative date to retrieve from (days)
           -datetype date field to use ('edat' or 'mdat')
           -ids      array ref of gids (overrides query)

This method creates a new query object.  Typically you will specify a
-db and a -query argument, possibly modified by -mindate, -maxdate, or
-reldate.  -mindate and -maxdate specify minimum and maximum dates for
entries you are interested in retrieving, expressed in the form
DD/MM/YYYY.  -reldate is used to fetch entries that are more recent
than the indicated number of days.

If you provide an array reference of IDs in -ids, the query will be
ignored and the list of IDs will be used when the query is passed to a
Bio::DB::GenBank object's get_Stream_by_query() method.  A variety of
IDs are automatically recognized, including GI numbers, Accession
numbers, Accession.version numbers and locus names.

=cut

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  my ($db,$reldate,$mindate,$maxdate,$datetype,$ids)
    = $self->_rearrange([qw(DB RELDATE MINDATE MAXDATE DATETYPE IDS)],@_);
  $self->db($db || DEFAULT_DB);
  $reldate  && $self->reldate($reldate);
  $mindate  && $self->mindate($mindate);
  $maxdate  && $self->maxdate($maxdate);
  $datetype ||= 'mdat';
  $datetype && $self->datetype($datetype);
  $self;
}

=head2 cookie

 Title   : cookie
 Usage   : ($cookie,$querynum) = $db->cookie
 Function: return the NCBI query cookie
 Returns : list of (cookie,querynum)
 Args    : none

NOTE: this information is used by Bio::DB::GenBank in
conjunction with efetch.

=cut

sub cookie {
  my $self = shift;
  if (@_) {
    $self->{'_cookie'}   = shift;
    $self->{'_querynum'} = shift;
  }

  else {
    $self->_run_query;
    @{$self}{qw(_cookie _querynum)};
  }
}

=head2 _request_parameters

 Title   : _request_parameters
 Usage   : ($method,$base,@params = $db->_request_parameters
 Function: return information needed to construct the request
 Returns : list of method, url base and key=>value pairs
 Args    : none

=cut

sub _request_parameters {
  my $self = shift;
  my ($method,$base);
  my @params = map {eval("\$self->$_") ? ($_ => eval("\$self->$_")) : () } @ATTRIBUTES;
  push @params,('usehistory'=>'y','tool'=>'bioperl');
  $method = 'get';
  $base   = ESEARCH;
  push @params,('term'   => $self->query);
  push @params,('retmax' => $self->{'_count'} || MAXENTRY);
  ($method,$base,@params);
}


=head2 count

 Title   : count
 Usage   : $count = $db->count;
 Function: return count of number of entries retrieved by query
 Returns : integer
 Args    : none

Returns the number of entries that are matched by the query.

=cut

sub count   {
  my $self = shift;
  if (@_) {
    my $d = $self->{'_count'};
    $self->{'_count'}   = shift;
    return $d;
  }
  else {
    $self->_run_query;
    return $self->{'_count'};
  }
}

=head2 ids

 Title   : ids
 Usage   : @ids = $db->ids([@ids])
 Function: get/set matching ids
 Returns : array of sequence ids
 Args    : (optional) array ref with new set of ids

=cut

=head2 query

 Title   : query
 Usage   : $query = $db->query([$query])
 Function: get/set query string
 Returns : string
 Args    : (optional) new query string

=cut

=head2 _parse_response

 Title   : _parse_response
 Usage   : $db->_parse_response($content)
 Function: parse out response
 Returns : empty
 Args    : none
 Throws  : 'unparseable output exception'

=cut

sub _parse_response {
  my $self    = shift;
  my $content = shift;
  if (my ($warning) = $content =~ m!<ErrorList>(.+)</ErrorList>!s) {
    warn "Warning(s) from GenBank: $warning\n";
  }
  if (my ($error) = $content =~ /<OutputMessage>([^<]+)/) {
    $self->throw("Error from Genbank: $error");
  }

  my ($count) = $content =~  /<Count>(\d+)/;
  my ($max)   = $content =~  /<RetMax>(\d+)/;
  my $truncated = $count > $max;
  $self->count($count);
  if (!$truncated) {
    my @ids = $content =~ /<Id>(\d+)/g;
    $self->ids(\@ids);
  }
  $self->_truncated($truncated);
  my ($cookie)    = $content =~ m!<WebEnv>(\S+)</WebEnv>!;
  my ($querykey)  = $content =~ m!<QueryKey>(\d+)!;
  $self->cookie(uri_unescape($cookie),$querykey);
}

1;
