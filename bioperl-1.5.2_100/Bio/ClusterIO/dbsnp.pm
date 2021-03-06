# $Id: dbsnp.pm,v 1.16.4.1 2006/10/02 23:10:13 sendu Exp $
# BioPerl module for Bio::ClusterIO::dbsnp
#
# Copyright Allen Day <allenday@ucla.edu>, Stan Nelson <snelson@ucla.edu>
# Human Genetics, UCLA Medical School, University of California, Los Angeles

# POD documentation - main docs before the code

=head1 NAME

Bio::ClusterIO::dbsnp - dbSNP input stream

=head1 SYNOPSIS

Do not use this module directly.  Use it via the Bio::ClusterIO class.

=head1 DESCRIPTION

Parse dbSNP XML files, one refSNP entry at a time.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...
package Bio::ClusterIO::dbsnp;

use strict;
use Bio::Root::Root;
use Bio::Variation::SNP;
use XML::Parser::PerlSAX;
use XML::Handler::Subs;
use Data::Dumper;
use IO::File;

use vars qw($DTD $DEBUG %MODEMAP %MAPPING);
$DTD = 'ftp://ftp.ncbi.nih.gov/snp/specs/NSE.dtd';
use base qw(Bio::ClusterIO);

BEGIN {
  %MAPPING = (
#the ones commented out i haven't written methods for yet... -Allen
			  'Rs_rsId'               => 'id',
#			  'Rs_taxId'                   => 'tax_id',
#			  'Rs_organism'                => 'organism',
			  'Rs_snpType'                => {'type' => 'value'},
			  'Rs_sequence_observed'                => 'observed',
			  'Rs_sequence_seq5'                 => 'seq_5',
			  'Rs_sequence_seq3'                 => 'seq_3',
#			  'Rs_sequence_exemplarSs'         => 'exemplar_subsnp',
			  'Rs_create_build'           => 'ncbi_build',
#??			  'Rs_update_build'           => 'ncbi_build',
#			  'NSE-rs_ncbi-num-chr-hits'       => 'ncbi_chr_hits',
#			  'NSE-rs_ncbi-num-ctg-hits'       => 'ncbi_ctg_hits',
#			  'NSE-rs_ncbi-num-seq-loc'        => 'ncbi_seq_loc',
#			  'NSE-rs_ncbi-mapweight'          => 'ncbi_mapweight',
#			  'NSE-rs_ucsc-build-id'           => 'ucsc_build',
#			  'NSE-rs_ucsc-num-chr-hits'       => 'ucsc_chr_hits',
#			  'NSE-rs_ucsc-num-seq-loc'        => 'ucsc_ctg_hits',
#			  'NSE-rs_ucsc-mapweight'          => 'ucsc_mapweight',

			  'Rs_het_value'                     => 'heterozygous',
			  'Rs_het-stdError'                  => 'heterozygous_SE',
			  'Rs_validation'               => {'validated' => 'value'}, #??
#			  'NSE-rs_genotype'                => {'genotype' => 'value'},

			  'Ss_handle'                  => 'handle',
			  'Ss_batchId'                => 'batch_id',
			  'Ss_locSnpId'               => 'id',
#			  'Ss_locSnpId'              => 'loc_id',
#			  'Ss_orient'                  => {'orient' => 'value'},
#			  'Ss_buildId'                => 'build',
			  'Ss_methodClass'            => {'method' => 'value'},
#			  'NSE-ss_accession_E'             => 'accession',
#			  'NSE-ss_comment_E'               => 'comment',
#			  'NSE-ss_genename'                => 'gene_name',
#			  'NSE-ss_assay-5_E'               => 'seq_5',
#			  'NSE-ss_assay-3_E'               => 'seq_3',
#			  'NSE-ss_observed'                => 'observed',

#			  'NSE-ss-popinfo_type'            => 'pop_type',
#			  'NSE-ss-popinfo_batch-id'        => 'pop_batch_id',
#			  'NSE-ss-popinfo_pop-name'        => 'pop_name',
#			  'NSE-ss-popinfo_samplesize'      => 'pop_samplesize',
#			  'NSE-ss_popinfo_est-het'         => 'pop_est_heterozygous',
#			  'NSE-ss_popinfo_est-het-se-sq'   => 'pop_est_heterozygous_se_sq',

#			  'NSE-ss-alleleinfo_type'         => 'allele_type',
#			  'NSE-ss-alleleinfo_batch-id'     => 'allele_batch_id',
#			  'NSE-ss-alleleinfo_pop-id'       => 'allele_pop_id',
#			  'NSE-ss-alleleinfo_snp-allele'   => 'allele_snp',
#			  'NSE-ss-alleleinfo_other-allele' => 'allele_other',
#			  'NSE-ss-alleleinfo_freq'         => 'allele_freq',
#			  'NSE-ss-alleleinfo_count'        => 'allele_count',

#			  'NSE-rsContigHit_contig-id'      => 'contig_hit',
#			  'NSE-rsContigHit_accession'      => 'accession_hit',
#			  'NSE-rsContigHit_version'        => 'version',
#			  'NSE-rsContigHit_chromosome'     => 'chromosome_hit',

#			  'NSE-rsMaploc_asn-from'          => 'asn_from',
#			  'NSE-rsMaploc_asn-to'            => 'asn_to',
#			  'NSE-rsMaploc_loc-type'          => {'loc_type' => 'value'},
#			  'NSE-rsMaploc_hit-quality'       => {'hit_quality' => 'value'},
#			  'NSE-rsMaploc_orient'            => {'orient' => 'value'},
#			  'NSE-rsMaploc_physmap-str'       => 'phys_from',
#			  'NSE-rsMaploc_physmap-int'       => 'phys_to',

			  'FxnSet_geneId'             => 'locus_id',  # does the code realise that there can be multiple of these
			  'FxnSet_symbol'              => 'symbol',
			  'FxnSet_mrnaAcc'            => 'mrna',
			  'FxnSet_protAcc'            => 'protein',
			  'FxnSet_fxnClass'    => {'functional_class' => 'value'},

			  #...
			  #...
			  #there are lots more, but i don't need them at the moment... -Allen
			  );
}

sub _initialize{
   my ($self,@args) = @_;
   $self->SUPER::_initialize(@args);
   my ($usetempfile) = $self->_rearrange([qw(TEMPFILE)],@args);
   defined $usetempfile && $self->use_tempfile($usetempfile);
   $self->{'_xmlparser'} = new XML::Parser::PerlSAX();
   $DEBUG = 1 if( ! defined $DEBUG && $self->verbose > 0);
}

=head2 next_cluster

 Title   : next_cluster
 Usage   : $dbsnp = $stream->next_cluster()
 Function: returns the next refSNP in the stream
 Returns : Bio::Variation::SNP object representing composite refSNP
           and its component subSNP(s).
 Args    : NONE

=cut

###
#Adapted from Jason's blastxml.pm
###
sub next_cluster {
  my $self = shift;
  my $data = '';
  my($tfh);

  if( $self->use_tempfile ) {
	$tfh = IO::File->new_tmpfile or $self->throw("Unable to open temp file: $!");
	$tfh->autoflush(1);
  }

  my $start = 1;
  while( defined( $_ = $self->_readline ) ){
	#skip to beginning of refSNP entry
	if($_ !~ m!<Rs>! && $start){
	  next;
	} elsif($_ =~ m!<Rs>! && $start){
	  $start = 0;
	} 

	#slurp up the data
	if( defined $tfh ) {
	  print $tfh $_;
	} else {
	  $data .= $_;
	}

	#and stop at the end of the refSNP entry
	last if $_ =~ m!</Rs>!;
  }

  #if we didn't find a start tag
  return if $start;

  my %parser_args;
  if( defined $tfh ) {
	seek($tfh,0,0);
	%parser_args = ('Source' => { 'ByteStream' => $tfh },
					'Handler' => $self);
  } else {
	%parser_args = ('Source' => { 'String' => $data },
					'Handler' => $self);
  }

  my $starttime;
  my $result;

  if(  $DEBUG ) {  $starttime = [ Time::HiRes::gettimeofday() ]; }

  eval {
	$result = $self->{'_xmlparser'}->parse(%parser_args);
  };

  if( $@ ) {
	$self->warn("error in parsing a report:\n $@");
	$result = undef;
  }

  if( $DEBUG ) {
	$self->debug( sprintf("parsing took %f seconds\n", Time::HiRes::tv_interval($starttime)));
  }

  return $self->refsnp;
}

=head2 SAX methods

=cut

=head2 start_document

 Title   : start_document
 Usage   : $parser->start_document;
 Function: SAX method to indicate starting to parse a new document.
           Creates a Bio::Variation::SNP
 Returns : none
 Args    : none

=cut

sub start_document{
  my ($self) = @_;
  $self->{refsnp} = Bio::Variation::SNP->new;
}

sub refsnp {
  return shift->{refsnp};
}

=head2 end_document

 Title   : end_document
 Usage   : $parser->end_document;
 Function: SAX method to indicate finishing parsing a new document
 Returns : none
 Args    : none

=cut

sub end_document{
  my ($self,@args) = @_;
}

=head2 start_element

 Title   : start_element
 Usage   : $parser->start_element($data)
 Function: SAX method to indicate starting a new element
 Returns : none
 Args    : hash ref for data

=cut

sub start_element{
  my ($self,$data) = @_;
  my $nm = $data->{'Name'};
  my $at = $data->{'Attributes'};

  if($nm eq 'Ss'){
	$self->refsnp->add_subsnp;
	return;
  }
  if(my $type = $MAPPING{$nm}){
	if(ref $type eq 'HASH'){
	  #okay, this is nasty.  what can you do?
	  $self->{will_handle}   = (keys %$type)[0];
	  my $valkey             = (values %$type)[0];
	  $self->{last_data}     = $at->{$valkey};
	} else {
	  $self->{will_handle} = $type;
	  $self->{last_data} = undef;
	}
  } else {
	undef $self->{will_handle};
  }
}

=head2 end_element

 Title   : end_element
 Usage   : $parser->end_element($data)
 Function: Signals finishing an element
 Returns : none
 Args    : hash ref for data

=cut

sub end_element {
  my ($self,$data) = @_;
  my $nm = $data->{'Name'};
  my $at = $data->{'Attributes'};

  my $method = $self->{will_handle};
  if($method){
	if($nm =~ /^Rs/ or $nm =~ /^NSE-SeqLoc/ or $nm =~ /^FxnSet/){
	  $self->refsnp->$method($self->{last_data});
	} elsif ($nm =~ /^Ss/){
	  $self->refsnp->subsnp->$method($self->{last_data});
	}
  }
}

=head2 characters

 Title   : characters
 Usage   : $parser->characters($data)
 Function: Signals new characters to be processed
 Returns : characters read
 Args    : hash ref with the key 'Data'

=cut

sub characters{
  my ($self,$data) = @_;
  $self->{last_data} = $data->{Data}
    if $data->{Data} =~ /\S/; #whitespace is meaningless -ad
}

=head2 use_tempfile

 Title   : use_tempfile
 Usage   : $obj->use_tempfile($newval)
 Function: Get/Set boolean flag on whether or not use a tempfile
 Example : 
 Returns : value of use_tempfile
 Args    : newvalue (optional)

=cut

sub use_tempfile{
  my ($self,$value) = @_;
  if( defined $value) {
	$self->{'_use_tempfile'} = $value;
  }
  return $self->{'_use_tempfile'};
}

1;
