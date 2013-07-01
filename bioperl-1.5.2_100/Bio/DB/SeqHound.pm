# BioPerl module for Bio::DB::SeqHound
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code
# 

=head1 NAME

Bio::DB::SeqHound - Database object interface to SeqHound

=head1 SYNOPSIS

    use Bio::DB::SeqHound;
    $sh = new Bio::DB::SeqHound();

    $seq = $sh->get_Seq_by_acc("CAA28783"); # Accession Number

    # or ...

    $seq = $sh->get_Seq_by_gi(4557225); # GI Number

=head1 VERSION

1.1

=head1 DESCRIPTION

SeqHound is a database of biological sequences and structures.  This
script allows the retrieval of sequence objects (Bio::Seq) from the
SeqHound database at the Blueprint Initiative.

Bioperl extension permitting use of the SeqHound Database System
developed by researchers at

 The Blueprint Initiative
 Samuel Lunenfeld Research Institute
 Mount Sinai Hospital
 Toronto, Canada


=head1 FEEDBACK/BUGS

known bugs: fail to get sequences for some RefSeq record with CONTIG,
example GI = 34871762

E<lt>seqhound@blueprint.orgE<gt>

=head1 MAILING LISTS

User feedback is an integral part of the evolution of this Bioperl module. Send
your comments and suggestions preferably to seqhound.usergroup mailing lists.
Your participation is much appreciated.

E<lt>seqhound.usergroup@lists.blueprint.orgE<gt>

=head1 WEBSITE

For more information on SeqHound http://www.blueprint.org/seqhound/

=head1 DISCLAIMER

This software is provided 'as is' without warranty of any kind.

=head1 AUTHOR

Rong Yao, Hao Lieu, Ian Donaldson

E<lt>seqhound@blueprint.orgE<gt>

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::DB::SeqHound;
use strict;
use vars qw($HOSTBASE $CGILOCATION $LOGFILENAME);

use Bio::Root::IO;
use Bio::SeqIO;
use IO::String;
use POSIX qw(strftime);

use base qw(Bio::DB::WebDBSeqI Bio::Root::Root);
BEGIN {    
    $HOSTBASE = 'http://seqhound.blueprint.org';
    $CGILOCATION = '/cgi-bin/seqrem?fnct=';
    $LOGFILENAME = 'shoundlog';
}


# helper method to get db specific options

=head2 new

 Title   : new
 Usage   : $sh = Bio::DB::SeqHound->new(@options);
 Function: Creates a new seqhound handle
 Returns : New seqhound handle
 Args    : 

=cut

sub new {
    	my ($class, @args ) = @_;
    	my $self = $class->SUPER::new(@args);
	if ($self->_init_SeqHound eq "TRUE"){
		return $self;
	}
	else {
		return;
	}
}

=head1 Routines Bio::DB::WebDBSeqI from Bio::DB::RandomAccessI

=head2 get_Seq_by_id

 Title   : get_Seq_by_id
 Usage   : $seq = $db->get_Seq_by_id('ROA1_HUMAN'); 
 Function: Gets a Bio::Seq object by its name
 Returns : a Bio::Seq object
 Args    : the id (as a string) of a sequence
 Throws  : "id does not exist" exception
 Example : Each of these calls retrieves the same sequence record
 	   $seq = $db->get_Seq_by_id(56);        #retrieval by GI
	   $seq = $db->get_Seq_by_id("X02597");  #retrieval by NCBI accession
	   $seq = $db->get_Seq_by_id("BTACHRE"); #retrieval by sequence "name"
	   a sequence "name" is a secondary identifier (usually assigned by the
	   submitting database external to the NCBI) that may not be visible in
	   the GenBank flat file version of the record but is always present in
	   the ASN.1 format.
 Note    : Since in GenBank.pm, this function accepts a gi, an accession number
           or a sequence name, SeqHound also satisfies these inputs.
	   If the input uid is a number, it is treated as a gi, if the uid is a
	   string, it is treated as an accession number first. If the search still
	   fails, it is treated as a sequence name.
	   Since SeqHound stores biological data from different source sequence
	   databases like: GenBank, GenPept, SwissProt, EMBL, RefSeq,
	   you can pass ids from the above databases to this function. 
	   The Bio::Seq object returned by this function is identical to the
	   Bio::Seq generated by the GenBank.pm and GenPept.pm.
	   The Bio::Seq object returned by this function sometimes has minor
	   difference in the SeqFeature from the Bio::Seq object generated 
	   in RefSeq.pm. 
	   The Bio::Seq objects created from this function will have the NCBI
	   versions of the SwissProt and EMBL sequence data information.

=cut

sub get_Seq_by_id {
	my ($self, $id)= @_;
	if ($id =~ /^\d+$/){
		my $seqio= $self-> _get_Seq_from_gbff ($id);
		if (defined $seqio){
			return $seqio->next_seq;
		}
	}
	elsif ($id =~ /^\S+$/){
	    #print "id is string, try search by accession or name\n";
	    my $gi = $self ->_get_gi_from_acc ($id);
	    if (!defined $gi){
			my $gi = $self->_get_gi_from_name($id);
			if (defined $gi){
				my $seqio = $self->_get_Seq_from_gbff($gi);
				if (defined $seqio){
					return $seqio->next_seq;
				}
			}
		}
		else{
			my $seqio = $self->_get_Seq_from_gbff($gi);
			if (defined $seqio){
				return $seqio->next_seq;
			}
			else {
				my $gi = $self->_get_gi_from_name($id);
				if (defined $gi) {
					my $seqio = $self->_get_Seq_from_gbff($gi);
					if (defined $seqio){
						return $seqio->next_seq;
					}
				}
			}
			
		}
	}
    	else{
		$self->warn("[get_Seq_by_id]: invalid input id.");
		return;
	}
	$self->warn("[get_Seq_by_id]: id $id does not exist");
	return;
}
						                    

=head2 get_Seq_by_acc

  Title   : get_Seq_by_acc
  Usage   : $seq = $db->get_Seq_by_acc('M34830');
  Function: Gets a Seq object by accession numbers
  Returns : a Bio::Seq object
  Args    : the accession number as a string
  Throws  : "id does not exist" exception
  Note    : Since in GenBank.pm, this function accepts an accession number
            or a sequence name, SeqHound also satisfies these inputs.
	    If the input uid is a string, it is treated as an accession number first.
	    If the search fails, it is treated as a sequence name.
	    Since SeqHound stores biological data from different source sequence
	    databases like: GenBank, GenPept, SwissProt, EMBL, RefSeq,
	    you can pass ids from the above databases to this function. 
	    The Bio::Seq object returned by this function is identical to the
	    Bio::Seq generated by the GenBank.pm and GenPept.pm.
	    The Bio::Seq object returned by this function sometimes has minor
	    difference in the SeqFeature from the Bio::Seq object generated 
	    in RefSeq.pm. 
	    The Bio::Seq objects created from this function will have the NCBI
	    versions of the SwissProt and EMBL sequence data information.

=cut

sub get_Seq_by_acc {
	my ($self, $acc) = @_;
	#exclude $acc is a number, since function does not accept gi as input
	if ($acc =~ /^\d+$/) {
		$self->warn ("[get_Seq_by_acc]: id $acc does not exist");
		return;
	}
	my ($ret, $gi);
	$gi= $self->_get_gi_from_acc($acc);
	#print "get_Seq_by_acc: gi = $gi\n";
    	if (defined $gi) {
		my $seqio = $self->_get_Seq_from_gbff($gi);
		if (defined $seqio){
			return $seqio->next_seq;
		}
	}
	#else, treat input as sequence name
	else {
		$gi = $self->_get_gi_from_name($acc);   	 	
		#print "in get_Seq_by_acc: else gi = $gi\n";
		if (defined $gi){
			my $seqio = $self->_get_Seq_from_gbff($gi);
			if (defined $seqio){
				return $seqio->next_seq;
			}
		}
	}
	$self->warn("[get_Seq_by_acc]: id $acc does not exist.");
	return;
}


=head2 get_Seq_by_gi

 Title   : get_Seq_by_gi
 Usage   : $seq = $sh->get_Seq_by_gi('405830');
 Function: Gets a Bio::Seq object by gi number
 Returns : A Bio::Seq object
 Args    : gi number (as a string)
 Throws  : "gi does not exist" exception
 Note    : call the same code get_Seq_by_id

=cut

sub get_Seq_by_gi
{
    	my ($self, $gi) = @_;
    	return get_Seq_by_id($self, $gi);
}

=head2 get_Seq_by_version

 Title   : get_Seq_by_version
 Usage   : $seq = $db->get_Seq_by_version('X77802');
 Function: Gets a Bio::Seq object by sequence version
 Returns : A Bio::Seq object
 Args    : accession.version (as a string)
 Throws  : "acc.version does not exist" exception
 Note    : SeqHound only keeps the most up-to-date version of a sequence. So
           for the above example, use 
	   $seq = $db->get_Seq_by_acc('X77802'); 
	   instead of X77802.1


=head2 get_Stream_by_query

  Title   : get_Stream_by_query
  Usage   : $seq = $db->get_Stream_by_query($query);
  Function: Retrieves Seq objects from Entrez 'en masse', rather than one
            at a time.  For large numbers of sequences, this is far superior
            than get_Stream_by_[id/acc]().
  Example : $query_string = 'Candida maltosa 26S ribosomal RNA gene'; 
  	    $query = Bio::DB::Query::GenBank->new(-db=>'nucleotide',
                                        -query=>$query_string);
            $stream = $sh->get_Stream_by_query($query);
	    or
	    $query = Bio::DB::Query::GenBank->new (-db=> 'nucleotide',
	    				-ids=>['X02597', 'X63732', 11002, 4557284]);
	    $stream = $sh->get_Stream_by_query($query);
  Returns : a Bio::SeqIO stream object
  Args    : $query :   A Bio::DB::Query::GenBank object. It is suggested that
            you create a Bio::DB::Query::GenBank object and get the entry
            count before you fetch a potentially large stream.

=cut

sub get_Stream_by_query{
	my ($self, $query) = @_;
	my @ids = $query->ids;
	#print join ",", @ids, "\n";
	return get_Stream_by_id($self, \@ids);	
}	


=head2 get_Stream_by_id

  Title   : get_Stream_by_id
  Usage   : $stream = $db->get_Stream_by_id(['J05128', 'S43442', 34996479]);
  Function: Gets a series of Seq objects by unique identifiers
  Returns : a Bio::SeqIO stream object
  Args    : $ref : a reference to an array of unique identifiers for
                   the desired sequence entries, according to genbank.pm
		   this function accepts gi, accession number
		   and sequence name
  Note    : Since in GenBank.pm, this function accepts a gi, an accession number
            or a sequence name, SeqHound also satisfies these inputs.
	    If the input uid is a number, it is treated as a gi, if the uid is a
	    string, it is treated as an accession number first. If the search still
	    fails, it is treated as a sequence name.
	    Since SeqHound stores biological data from different source sequence
	    databases like: GenBank, GenPept, SwissProt, EMBL, RefSeq,
	    you can pass ids from the above databases to this function. 
	    The Bio::Seq object returned by this function is identical to the
	    Bio::Seq generated by the GenBank.pm and GenPept.pm.
	    The Bio::Seq object returned by this function sometimes has minor
	    difference in the SeqFeature from the Bio::Seq object generated 
	    in RefSeq.pm. 
	    The Bio::Seq objects created from this function will have the NCBI
	    versions of the SwissProt and EMBL sequence data information.   

=cut

sub get_Stream_by_id
{
	my ($self, $id) = @_;
	my (@gilist, @not_exist);
	if(!defined $id) {
		$self->warn("[get_Stream_by_id]: undefined input id");
		return;
    	}
	if (ref($id)=~ /array/i){
		foreach my $i (@$id){
			if ($i =~ /^\d+$/){
				push(@gilist, $i);
			}
			elsif ($i =~ /^\S+$/) {
				my $gi = _get_gi_from_acc($self, $i);
				if (!defined $gi){
					$gi = _get_gi_from_name($self, $i);
					if (!defined $gi){
					    $self->warn("[get_Stream_by_id]: id $i does not exist.");
						push (@not_exist, $i);
					}
					else {
						push (@gilist, $gi);
					}
				}
				else {
					push(@gilist, $gi);
				}
			}
			else {
			    $self->warn("[get_Stream_by_id]: id $i does not exist.");
				push (@not_exist, $i);
			}
		}
		my $seqio = _get_Seq_from_gbff($self, \@gilist);
		return $seqio;
	}
	else {
		return;
	}
}


=head2 get_Stream_by_acc

  Title   : get_Stream_by_acc
  Usage   : $seq = $db->get_Stream_by_acc(['M98777', 'M34830']);
  Function: Gets a series of Seq objects by accession numbers
  Returns : a Bio::SeqIO stream object
  Args    : $ref : a reference to an array of accession numbers for
                   the desired sequence entries
  Note    : For SeqHound, this just calls the same code for get_Stream_by_id()

=cut

sub get_Stream_by_acc
{
	my ($self, $acc) = @_;
	return get_Stream_by_id($self, $acc);
}

=head2 get_Stream_by_gi

  Title   : get_Stream_by_gi
  Usage   : $seq = $db->get_Seq_by_gi([161966, 255064]);
  Function: Gets a series of Seq objects by gi numbers
  Returns : a Bio::SeqIO stream object
  Args    : $ref : a reference to an array of gi numbers for
                   the desired sequence entries
  Note    : For SeqHound, this just calls the same code for get_Stream_by_id()

=cut

sub get_Stream_by_gi{
	my ($self, $gi) = @_;
	return get_Stream_by_id($self, $gi);	
}	

=head2 get_request

 Title   : get_request
 Usage   : my $lcontent = $self->get_request;
 Function: get the output from SeqHound API http call
 Returns : the result of the remote call from SeqHound
 Args    : %qualifiers = a hash of qualifiers 
           (SeqHound function name, id, query etc)
 Example : $lcontent = $self->get_request(-funcname=>'SeqHoundGetGenBankff',
		 			-query=>'gi',
					-uid=>555);
 Note    : this function overrides the implementation in Bio::DB::WebDBSeqI.

=cut

sub get_request {
	my $self = shift;
    	my ( @qualifiers) = @_;
    	my ($funcname, $query, $uids, $other) = $self->_rearrange([qw(FUNCNAME QUERY UIDS OTHER)],
							@qualifiers);
	# print ("get funcname = $funcname, query = $query, uids= $uids\n"); 
	unless( defined $funcname ne '') {
	$self->throw("please specify the SeqHound function for query");
    	}
    	my $url = $HOSTBASE . $CGILOCATION . $funcname;
    	unless( defined $uids ne '') {
	$self->throw("please specify a uid or a list of uids to fetch");
    	}
    	unless ( defined $query && $query ne '') {
	$self->throw("please specify a valid query field");
	}
	
 	if (defined $uids && defined $query) {
		if( ref($uids) =~ /array/i ) {
	       	$uids = join(",", @$uids);
		}
		$url=$url."&".$query."=".$uids;
		if (defined $other){
			$url=$url."&".$other;
		}
		my $ua = LWP::UserAgent->new(env_proxy => 1);
		my $req = HTTP::Request->new ('GET', $url);
		my $res = $ua->request($req);
		if ($res->is_success){
			return $res->content;
		}
		else {
			my $result = "HTTP::Request error: ".$res->status_line."\n";
			$self->warn("$result");
			return $result;
		}
	}

}

=head2 postprocess_data

 Title   : postprocess_data
 Usage   : $self->postprocess_data (-funcname => $funcname,
		                    -lcontent => $lcontent,
				    -outtype  => $outtype);
 Function: process return String from http seqrem call 
           output type can be a string or a Bio::SeqIO object.
 Returns : void
 Args    : $funcname is the API function name of SeqHound 
           $lcontent is a string output from SeqHound server http call
           $outtype is a string or a Bio::SeqIO object 
 Example : $seqio = $self->postprocess_data ( -lcontent => $lcontent,
                             		-funcname => 'SeqHoundGetGenBankffList',
				      	-outtype => 'Bio::SeqIO');
	   or
	   $gi = $self->postprocess_data( -lcontent => $lcontent,
			                -funcname => 'SeqHoundFindAcc',
					-outtype => 'string');
 Note    : this method overrides the method works for genbank/genpept,
           this is for SeqHound

=cut

sub postprocess_data
{
    my ($self, @args) = @_;
    my ($funcname, $lcontent, $outtype) = $self->_rearrange(
                        [qw(FUNCNAME LCONTENT OUTTYPE)], @args);
    my $result;
	if (!defined $outtype){ 
		$self->throw("please specify the output type, string, Bio::SeqIO etc");
	}
        if (!defined $lcontent){
		$self->throw("please provide the result from SeqHound call");
	}
	if (!defined $funcname){
		$self->throw("Please provide the function name");
	}

	#set up verbosity level if need record in the log file
    my $log_msg = "Writing into '$LOGFILENAME' log file.\n";
    my $now = strftime("%a %b %e %H:%M:%S %Y", localtime);
    if ($lcontent eq "") {
        $self->debug($log_msg);
        open (my $LOG, '>>', $LOGFILENAME);
        print $LOG "$now		$funcname. No reply.\n";
        return;
    }
    elsif ($lcontent =~ /HTTP::Request error/) {
        $self->debug($log_msg);
        open (my $LOG, '>>', $LOGFILENAME);
        print $LOG "$now		$funcname. Http::Request error problem.\n";
        return;
    }
    elsif ($lcontent =~ /SEQHOUND_ERROR/) {
        $self->debug($log_msg);
        open (my $LOG, '>>', $LOGFILENAME);
        print $LOG "$now	$funcname error. SEQHOUND_ERROR found.\n";
        return;
    }
    elsif ($lcontent =~ /SEQHOUND_NULL/) {
        $self->debug($log_msg);
        open (my $LOG, '>>', $LOGFILENAME);
        print $LOG "$now	$funcname Value not found in the database. SEQHOUND_NULL found.\n";
        return;
    }
    else {
        chomp $lcontent;
        my @lines = split(/\n/, $lcontent, 2);
        if ($lines[1] =~ /^-1/) {
            $self->debug($log_msg);
            open (my $LOG, '>>', $LOGFILENAME);
            print $LOG "$now	$funcname Value not found in the database. -1 found.\n";
            return;
        }
        elsif ($lines[1]  =~ /^0/) {
            $self->debug($log_msg);
            open (my $LOG, '>>', $LOGFILENAME);
            print $LOG "$now	$funcname failed.\n";
            return;
        }
        else {
            $result = $lines[1];
        }
    }

	#a list of functions in SeqHound which can wrap into Bio::seqIO object
	if ($outtype eq 'Bio::SeqIO'){
		my $buf = IO::String->new($result);
		my $io = Bio::SeqIO->new (-format => 'genbank', -fh => $buf);
		if (defined $io && $io ne ''){
		    return $io;
		}
		else { return;}
   	}	
   	#return a string if outtype is "string"
   	return $result;
}


=head2 _get_gi_from_name
 
 Title   : _get_gi_from_name
 Usage   : $self->_get_gi_from_name('J05128');
 Function: get the gene identifier from a sequence name
           in SeqHound database
 Return  : gene identifier or undef
 Args    : a string represented sequence name

=cut

sub _get_gi_from_name
{
	my ($self, $name) = @_;
	my ($ret, $gi);
	$ret = $self->get_request( -funcname => 'SeqHoundFindName',
			               -query => 'name',
				       -uids  => $name);
	#print "_get_gi_from_name:  ret = $ret\n";
	$gi = $self->postprocess_data(-lcontent => $ret,
			                -funcname => 'SeqHoundFindName',
					-outtype => 'string');
	#print "_get_gi_from_name: gi = $gi\n";
	return $gi;
}

=head2 _get_gi_from_acc
 
 Title   : _get_gi_from_acc
 Usage   : $self->_get_gi_from_acc('M34830')
 Function: get the gene identifier from an accession number
 	  in SeqHound database
 Return  : gene identifier or undef
 Args    : a string represented accession number

=cut

sub _get_gi_from_acc
{
	my ($self, $acc) = @_;
	my ($ret, $gi);
	$ret = $self->get_request ( -funcname => 'SeqHoundFindAcc',
			               -query => 'acc',
				       -uids  => $acc);
	#print "_get_gi_from_acc:  ret = $ret\n";
	$gi = $self->postprocess_data(  -lcontent => $ret,
			                -funcname => 'SeqHoundFindAcc',
					-outtype => 'string');
	#print "_get_gi_from_acc:  gi = $gi\n";
	return $gi;
}

=head2 _get_Seq_from_gbff
 
 Title   : _get_Seq_from_gbff
 Usage   : $self->_get_Seq_from_gbff($str)
 Function: get the Bio::SeqIO stream object from gi or a list of gi
           in SeqHound database
 Return  : Bio::SeqIO or undef
 Args    : a string represented gene identifier or
           a list of gene identifiers
 Example : $seq = $self->_get_Seq_from_gbff(141740);
           or
	   $seq = $self->_get_Seq_from_gbff([141740, 255064, 45185482]);

=cut

sub _get_Seq_from_gbff
{
	my ($self, $gi) = @_;
	if(!defined $gi) {
		$self->warn("[_get_Seq_from_gbff]: undefined input gi");
		return;
    	}
	my $lcontent;
	if (ref($gi) =~ /array/i){
		my @copyArr = @$gi;
		my @tempArr;
		$lcontent = "SEQHOUND_OK\n";
		while ($#copyArr != -1){
			@tempArr =_MaxSizeArray(\@copyArr);
		    	#in order to keep the correct output order as GenBank does
			my $gi = join (",", reverse(@tempArr));
    			my $result;
    			my $ret = $self->get_request(  -funcname => 'SeqHoundGetGenBankffList',
            	                   			-query => 'pgi',
			 				-uids => $gi);
			if (defined $ret){
				my @lines = split(/\n/, $ret, 2);
      				if($lines[0] =~ /SEQHOUND_ERROR/ || $lines[0] =~ /SEQHOUND_NULL/){
      				}
	  			else {
					if ($lines[1] =~ /^(null)/ || $lines[1] eq ""){
     	 			}
         			else{
           				$result = $lines[1];
         			}
			}
			#append genbank flat files for long list
			$lcontent = $lcontent.$result;
			}
		}
	}
    	#else $gi is a single variable
	else {
		$lcontent = $self->get_request(  -funcname => 'SeqHoundGetGenBankffList',
            	                   		-query => 'pgi',
			 			-uids => $gi);
	}
     	my $seqio = $self->postprocess_data ( -lcontent => $lcontent,
                             			-funcname => 'SeqHoundGetGenBankffList',
				      		-outtype => 'Bio::SeqIO');
		
	return $seqio;
}


=head2 _init_SeqHound

 Title   : _init_SeqHound
 Usage   : $self->_init_SeqHound();
 Function: call SeqHoundInit at blueprint server 
 Return  : $result (TRUE or FALSE)
 Args    : 

=cut

sub _init_SeqHound
{
	my $self = shift;
	my $ret = $self->get_request(-funcname => 'SeqHoundInit',
						-query => 'NetEntrezOnToo',
						-uids => 'true',
						-other => 'appname=Bioperl');
	my $result = $self->postprocess_data(-lcontent => $ret,
					-funcname => 'SeqHoundInit',
					-outtype => 'string');
	return $result || 'FALSE';

}

=head2 _MaxSizeArray

 Title   : _MaxSizeArray
 Usage   : $self->_MaxSizeArray(\@arr)
 Function: get an array with the limit size
 Return  : an array with the limit size
 Args    : a reference to an array

=cut

sub _MaxSizeArray 
{
  my $argArr = shift;
  my @copyArr;
  my $MAXQ = 5;
  my $len = scalar(@$argArr);
  for(my $i = 0; $i < $len;){
    $copyArr[$i++] = $$argArr[0]; 
    shift(@$argArr);
    if($i == $MAXQ) 
    {
       last;
    }
  }
  return @copyArr;
}

1;
__END__
