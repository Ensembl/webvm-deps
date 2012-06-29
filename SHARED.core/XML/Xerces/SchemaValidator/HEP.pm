#########
# Author:        rmp
# Maintainer:    rmp
# Created:       2006-03-30
# Last Modified: 2006-03-30
#
# Epigenome HEP project-specific xml schema-validator
#
package XML::Xerces::SchemaValidator::HEP;
use strict;
use base "XML::Xerces::SchemaValidator";

our $SCHEMA = [qw(http://epigenomics.com/sequencing/hep/sanger/amplicon http://www.sanger.ac.uk/PostGenomics/epigenome/schema/AmpliconData.xsd
		  http://epigenomics.com/sequencing/hep/sanger/plate    http://www.sanger.ac.uk/PostGenomics/epigenome/schema/PlateData.xsd
		  http://epigenomics.com/sequencing/hep/sanger/primer   http://www.sanger.ac.uk/PostGenomics/epigenome/schema/PrimerData.xsd
		  http://epigenomics.com/sequencing/hep/sanger/tissue   http://www.sanger.ac.uk/PostGenomics/epigenome/schema/TissueData.xsd)];

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  bless $self, $class;
  $self->setExternalSchemaLocation($SCHEMA);
  return $self;
}

1;
