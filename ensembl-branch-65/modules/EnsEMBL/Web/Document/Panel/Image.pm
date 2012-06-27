# $Id: Image.pm,v 1.3 2010-09-28 10:12:32 sb23 Exp $

package EnsEMBL::Web::Document::Panel::Image;

use strict;

use base qw(EnsEMBL::Web::Document::Panel);

sub _start { return '<div class="autocenter_wrapper"><div class="autocenter">'; }
sub _end   { return '</div></div>'; }

1;
