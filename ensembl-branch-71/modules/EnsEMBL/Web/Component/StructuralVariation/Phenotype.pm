# $Id: Phenotype.pm,v 1.3 2013-03-22 14:56:29 lg10 Exp $

package EnsEMBL::Web::Component::StructuralVariation::Phenotype;

use strict;

use base qw(EnsEMBL::Web::Component::StructuralVariation);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content {
  my $self = shift;
  my $object = $self->object;

  ## first check we have uniquely determined variation
  return $self->_info('A unique location can not be determined for this Structural Variation', $object->not_unique_location) if $object->not_unique_location;
  
  my $supporting_evidences = $object->Obj->get_all_SupportingStructuralVariants();
  my $table_rows = $self->table_data($supporting_evidences);
  
  return '<p>We do not have any phenotype data associated wih this structural variation.</p>' unless scalar @$table_rows;
  
  my $table = $self->new_table([], [], { data_table => 1 });
   

  $table->add_columns(
    { key => 'disease',    title => 'Disease/Trait',  align => 'left', sort => 'html' }, 
    { key => 's_evidence', title => 'Supporting evidence(s)', align => 'left', sort => 'html' }
  );
  
  $table->add_rows(@$table_rows);
  
  return $table->render;
};


sub table_data { 
  my ($self, $supporting_evidences) = @_;
  
  my $hub        = $self->hub;
  my $object     = $self->object;
  
  my %phenotypes;
  my %ssv_phen;
                 
  my $count_se = scalar @$supporting_evidences;
                 
  foreach my $evidence (@$supporting_evidences) {
  
    my $svas = $evidence->get_all_PhenotypeFeatures();
    my $ssv_name = $evidence->variation_name;
    
    foreach my $sva (@$svas) {
      next if ($sva->seq_region_start==0 || $sva->seq_region_end==0);
      
      my $phe = ($sva->phenotype) ? $sva->phenotype->description : undef;
      if ($phe && !$ssv_phen{$ssv_name}{$phe}) {
        $ssv_phen{$ssv_name}{$phe} = 1;
        if (exists $phenotypes{$phe}) {
          $phenotypes{$phe}{s_evidence} .= ', '.$sva->object_id;
        } 
        else {
          $phenotypes{$phe} = {
            disease    => qq{<b>$phe</b>},
            s_evidence => $sva->object_id
          };
        }
      }
    }
  } 
  return [values %phenotypes];
}


1;
