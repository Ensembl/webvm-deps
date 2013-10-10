# $Id: Vuserdata.pm,v 1.9 2012-04-02 13:23:41 sb23 Exp $

package Bio::EnsEMBL::GlyphSet::Vuserdata;

use strict;

use base qw(Bio::EnsEMBL::GlyphSet::V_density);

### Fetches userdata and munges it into a basic format 
### for rendering by the parent module

sub _init {
  my $self = shift;
  my $rtn  = $self->build_tracks;
  return $self->{'text_export'} && $self->can('render_text') ? $rtn : undef;
}

1;
