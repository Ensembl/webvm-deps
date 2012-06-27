# $Id: GeneSpliceImage.pm,v 1.4 2011-04-28 10:36:11 sb23 Exp $

package EnsEMBL::Web::Component::Gene::GeneSpliceImage;

use strict;

use base qw(EnsEMBL::Web::Component::Gene::GeneSNPImage);

sub content { return $_[0]->SUPER::content(1, 'GeneSpliceView'); }

1;

