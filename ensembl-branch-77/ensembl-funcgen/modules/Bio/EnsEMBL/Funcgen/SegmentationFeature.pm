#
# Ensembl module for Bio::EnsEMBL::Funcgen::SegmentationFeature
#


=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2018-2019] EMBL-European Bioinformatics Institute

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

Bio::EnsEMBL::SegmentationFeature - Genomic segmentation feature

=head1 SYNOPSIS

use Bio::EnsEMBL::Funcgen::SegmentationFeature;

my $feature = Bio::EnsEMBL::Funcgen::SegmentationFeature->new
 (
  -SLICE         => $chr_1_slice,
  -START         => 1_000_000,
  -END           => 1_000_024,
	-STRAND        => 0,
  -FEATURE_SET   => $fset,
  -FEATURE_TYPE  => $ftype,
 );


=head1 DESCRIPTION

An SegmentationFeature object represents the genomic placement of a prediction
generated by the eFG analysis pipeline. This normally represents the 
output of a peak calling analysis. It can have a score and/or a summit, the 
meaning of which depend on the specific Analysis used to infer the feature.
For example, in the case of a feature derived from a peak call over a ChIP-seq
experiment, the score is the peak caller score, and summit is the point in the
feature where more reads align with the genome.

=head1 SEE ALSO

Bio::EnsEMBL::Funcgen::DBSQL::SegmentationFeatureAdaptor

=cut

package Bio::EnsEMBL::Funcgen::SegmentationFeature;

use strict;
use warnings;
use Bio::EnsEMBL::Utils::Argument  qw( rearrange );
use Bio::EnsEMBL::Utils::Exception qw( throw );

use base qw( Bio::EnsEMBL::Funcgen::SetFeature );

=head2 new

  Arg [-SLICE]        : Bio::EnsEMBL::Slice - The slice on which this feature is.
  Arg [-START]        : int - The start coordinate of this feature relative to the start of 
                        the slice it is sitting on. Coordinates start at 1 and are inclusive.
  Arg [-END]          : int -The end coordinate of this feature relative to the start of 
                        the slice it is sitting on. Coordinates start at 1 and are inclusive.
  Arg [-STRAND]       : int - The orientation of this feature. Valid values are 1, -1 and 0.
  Arg [-FEATURE_SET]  : Bio::EnsEMBL::Funcgen::FeatureSet
  Arg [-FEATURE_TYPE] : Bio::Ensembl::Funcgen::FeatureType
  Arg [-DISPLAY_LABEL]: optional string - Display label for this feature
  Arg [-SCORE]        : optional int - Score assigned by analysis pipeline
  Arg [-dbID]         : optional int - Internal database ID.
  Arg [-ADAPTOR]      : optional Bio::EnsEMBL::DBSQL::BaseAdaptor - Database adaptor.

  Example             : my $feature = Bio::EnsEMBL::Funcgen::SegmentationFeature->new
                                   (
									-SLICE         => $chr_1_slice,
									-START         => 1_000_000,
									-END           => 1_000_024,
                                    -STRAND        => -1,
                                    -FEATURE_SET   => $fset,
                                    -FEATURE_TYPE  => $ftype,
									-DISPLAY_LABEL => $text,
									-SCORE         => $score,
                                   );


  Description: Constructor for SegmentationFeature objects.
  Returntype : Bio::EnsEMBL::Funcgen::SegmentationFeature
  Exceptions : None
  Caller     : General
  Status     : Medium Risk

=cut

#Hard code strand => 0 here? And remove from input params?

sub new {
  my $caller = shift;
	my $class  = ref($caller) || $caller;
  my $self  = $class->SUPER::new(@_);
  my ($score, $ftype) = rearrange(['SCORE', 'FEATURE_TYPE'], @_);

  #test ftype as SetFeature method defaults to feature_set->feature_type
  throw('You must pass a valid FeatureType') if ! defined $ftype;

  $self->{score} = $score if $score;
  $self->{feature_type} = $ftype;
	
  return $self;
}


=head2 score

  Arg [1]    : (optional) int - score
  Example    : my $score = $feature->score();
  Description: Getter and setter for the score attribute for this feature. 
  Returntype : int
  Exceptions : None
  Caller     : General
  Status     : At Risk

=cut

sub score {
  my $self = shift;		
  return $self->{'score'};
}


=head2 display_label

  Example    : my $label = $feature->display_label();
  Description: Getter for the display label of this feature.
  Returntype : String
  Exceptions : None
  Caller     : General
  Status     : At Risk

=cut

sub display_label {
  my $self = shift;
  
  if(! $self->{'display_label'}  && $self->adaptor){
	$self->{'display_label'} = $self->feature_type->name()." -";
	$self->{'display_label'} .= " ".$self->cell_type->name();
  }
  
  return $self->{'display_label'};
}

=head2 summary_as_hash

  Example       : $segf_summary = $segf->summary_as_hash;
  Description   : Retrieves a textual summary of this SegmentationFeature.
  Returns       : Hashref of descriptive strings
  Status        : Intended for internal use (REST)

=cut

sub summary_as_hash {
  my $self = shift;

  return
    {
     segmentation_feature_type => $self->feature_type->name,
     cell_type                 => $self->feature_set->cell_type->name,
     start                     => $self->seq_region_start,
     end                       => $self->seq_region_end,
     seq_region_name           => $self->seq_region_name              };
}

1;

