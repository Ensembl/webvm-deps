# $Id: AltPage.pm,v 1.1 2012-08-22 10:24:57 ap5 Exp $

package EnsEMBL::Web::Controller::AltPage;

### Alternative dynamic page with fluid layout

use strict;

use base qw(EnsEMBL::Web::Controller::Page);
 
sub page_type   { return 'Fluid'; }

1;
