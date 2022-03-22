#
# Ensembl module for Bio::EnsEMBL::Funcgen::ResultFeature
#

=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2018-2022] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.


=head1 NAME

Bio::EnsEMBL::Funcgen::ResultFeature - A module to represent a lightweight ResultFeature object

=head1 SYNOPSIS

use Bio::EnsEMBL::Funcgen::ResultFeature;

my $rfeature = Bio::EnsEMBL::Funcgen::ResultFeature->new_fast([$start, $end, $score ]);

my @rfeatures = @{$rset->get_displayable_ResultFeature_by_Slice($slice)};

foreach my $rfeature (@rfeatures){
    my $score = $rfeature->score();
    my $rf_start = $rfeature->start();
    my $rf_end = $rfeature->end();
}

=head1 DESCRIPTION

This is a very sparse class designed to be as lightweight as possible to enable fast rendering in the web browser.
As such only the information absolutely required is contained.  Any a piori information is omitted e.g. seq_region_id, 
this will already be known as ResultFeatures are retrieved via a Slice method in ResultSet via the ResultSetAdaptor, 
likewise with analysis and experimental_chip information.  ResultFeatures are transient objects, in that they are not 
stored in the DB, but are a very small subset of information from the result and oligo_feature tables. ResultFeatures 
should only be generated by the ResultSetAdaptor as there is no parameter checking in place.

=cut


package Bio::EnsEMBL::Funcgen::ResultFeature;

use strict;
use warnings;
use Bio::EnsEMBL::Utils::Exception qw( throw );
use base qw( Bio::EnsEMBL::Feature );

### TO BE REMOVED IN FAVOUR OF Bio::EnsEMBL::Funcgen::Collection::ResultFeature


=head2 new_fast

  Args       : Array with attributes start, end, strand, score, probe, result_set_id, winow_size  IN THAT ORDER.
               WARNING: None of these are validated, hence can omit some where not needed
  Example    : none
  Description: Fast and list version of new. Only works if the code is very disciplined.
  Returntype : Bio::EnsEMBL::Funcgen::ResultFeature
  Exceptions : None
  Caller     : ResultSetAdaptor
  Status     : At Risk

=cut

sub new_fast {
  my $class = shift;
  bless \@_, $class;
}




=head2 start

  Example    : my $start = $rf->start();
  Description: Getter of the start attribute for ResultFeature
               objects.
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : At Risk - Now also sets to enable projection

=cut

sub start {  
  $_[0]->[0] =  $_[1] if $_[1];
  $_[0]->[0];
}


=head2 end

  Example    : my $start = $rf->end();
  Description: Getter of the end attribute for ResultFeature
               objects.
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : At Risk - Now also sets to enable projection

=cut

sub end {  
  $_[0]->[1] =  $_[1] if $_[1];
  $_[0]->[1];
}


#Do we need to chacnge this to strand and have slice strand context, as with start and end

sub strand {  shift->[2];}

=head2 score

  Example    : my $score = $rf->score();
  Description: Getter of the score attribute for ResultFeature
               objects
  Returntype : string/float/double?
  Exceptions : None
  Caller     : General
  Status     : At Risk

=cut

sub score {  shift->[3];}


=head2 probe

  Example    : my $probe = $rf->probe();
  Description: Getter of the probe attribute for ResultFeature
               objects
  Returntype : Bio::EnsEMBL::Funcgen::Probe
  Exceptions : None
  Caller     : General
  Status     : At Risk - This can only be used for Features with window 0.

=cut

#probe_id is currently not available in the result_feature table, so this would be a result/probe_feature query.

sub probe {  shift->[4];}


#The following are only used for storage and retrieval, hence why they are not included in new_fast which is streamlined
#for performance
#These have no validation so all thi smust be done in the caller/storer i.e. the adaptor

sub result_set_id {  shift->[5];}
sub window_size {  shift->[6];}

#May not ever need this
#We pass the slice to store
#Don't normally want to remap, so don't need furing fetch
#Now also sets for to enable projection

sub slice {  
  $_[0]->[7] =  $_[1] if $_[1];
  $_[0]->[7];
}


#Had to reimplement these as they used direct hash calls rather than acessor
#redefined to use accessors to array

sub length {
  my $self = shift;
  return $self->end - $self->start + 1;
}

=head2 move

  Arg [1]    : int start
  Arg [2]    : int end
  Arg [3]    : (optional) int strand
  Example    : None
  Description: Sets the start, end and strand in one call rather than in 
               3 seperate calls to the start(), end() and strand() methods.
               This is for convenience and for speed when this needs to be
               done within a tight loop.
  Returntype : none
  Exceptions : Thrown is invalid arguments are provided
  Caller     : general
  Status     : Stable

=cut

sub move {
  my $self = shift;

  throw('start and end arguments are required') if(@_ < 2);

  my $start  = shift;
  my $end    = shift;
  my $strand = shift;

  if(defined($start) && defined($end) && $end < $start) {
    throw('start must be less than or equal to end');
  }
  if(defined($strand) && $strand != 0 && $strand != -1 && $strand != 1) {
    throw('strand must be 0, -1 or 1');
  }

  $self->[0] = $start;
  $self->[1] = $end;
  $self->[2] = $strand if(defined($strand));
}



=head2 feature_Slice

  Args       : none
  Example    : $slice = $feature->feature_Slice()
  Description: Reimplementation of Bio::EnsEMBL::Feature method to enable
               assembly mapping
  Returntype : Bio::EnsEMBL::Slice or undef if this feature has no attached
               Slice.
  Exceptions : warning if Feature does not have attached slice.
  Caller     : web drawing code
  Status     : Stable

=cut


sub feature_Slice {
  my $self = shift;

  my $slice = $self->[7];

  if(!$slice) {
    warning('Cannot obtain Feature_Slice for feature without attached slice');
    return undef;
  }

  return $slice->sub_Slice($self->[0], $self->[1]); 
}



1;

