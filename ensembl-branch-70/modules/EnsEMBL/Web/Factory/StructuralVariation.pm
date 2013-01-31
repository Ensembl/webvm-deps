package EnsEMBL::Web::Factory::StructuralVariation;

use strict;
use warnings;
no warnings 'uninitialized';

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self                 = shift;
  my $structural_variation = shift;
  my $db                   = $self->database('variation');
  my $identifier           = $self->param('sv');
  
  return $self->problem ('fatal', 'Database Error', 'There is no variation database for this species.') unless $db;
   
  if (!$structural_variation) {
    return $self->problem('fatal', 'Structural Variation ID required', $self->_help('A structural variation ID is required to build this page.')) unless $identifier;
    
    $db->include_failed_variations(1);
    
    $structural_variation = $db->get_StructuralVariationAdaptor->fetch_by_name($identifier);
  }
  
  if ($structural_variation) { 
    $self->DataObjects($self->new_object('StructuralVariation', $structural_variation, $self->__data));
    
    my @svf          = $self->param('svf');
    my @sv_features  = @{$structural_variation->get_all_StructuralVariationFeatures};
    my ($sv_feature) = scalar @sv_features == 1 ? $sv_features[0] : $svf[0] ? grep $_->dbID eq $svf[0], @sv_features : undef;
    
		if ($sv_feature) {
      my $context = $self->param('context') || 500;
      $self->generate_object('Location', $sv_feature->feature_Slice->expand($context, $context));
    	$self->param('svf', $sv_feature->dbID) unless scalar @svf > 1; # This check is needed
		} elsif (scalar @svf) {
      $self->delete_param('svf');
    }
    
    $self->param('vdb', 'variation');
    $self->param('sv', $structural_variation->variation_name) unless $self->param('sv'); # For same reason as svf check above;
  } else {
    my $db_version = $self->species_defs->databases->{'DATABASE_VARIATION'}{'dbSNP_VERSION'};
    
    return $self->problem('fatal', "Could not find structural variation $identifier", $self->_help(sprintf(
      'Either %s does not exist in the current Ensembl database, %sor there was a problem retrieving it.',
      $identifier, $db_version ? "which includes data from dbSNP $db_version, " : ''
    )));
  }
}

sub _help {
  my ($self, $string) = @_;

  my %sample    = %{$self->species_defs->SAMPLE_DATA || {}};
  my $help_text = $string ? sprintf '<p>%s</p>', encode_entities($string) : '';
  my $url       = $self->hub->url({ __clear => 1, action => 'Summary', sv => $sample{'STRUCTURAL_VARIATION_PARAM'} });

  $help_text .= sprintf('
    <p>
      This view requires a structural variation identifier in the URL. For example:
    </p>
    <blockquote class="space-below"><a href="%s">%s</a></blockquote>',
    encode_entities($url),
    encode_entities($self->species_defs->ENSEMBL_BASE_URL. $url)
  );

  return $help_text;
}

1;