# $Id: Copyright.pm,v 1.4 2012-07-19 09:38:29 hr5 Exp $

package EnsEMBL::Web::Document::Element::Copyright;

### Copyright notice for footer (basic version with no logos)

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub new {
  return shift->SUPER::new({
    %{$_[0]},
    sitename => '?'
  });
}

sub sitename :lvalue { $_[0]{'sitename'}; }

sub content {
  my @time = localtime;
  my $year = @time[5] + 1900;
  
  return qq{
    <div class="column-two left">
      <p>&copy; $year <span class="print_hide"><a href="http://www.sanger.ac.uk/" class="nowrap">WTSI</a> / 
        <a href="http://www.ebi.ac.uk/" style="white-space:nowrap">EBI</a></span>
        <span class="screen_hide_inline">WTSI / EBI</span>.
        (<a href="http://www.ensembl.org/info/about/legal/privacy.html">Privacy policy</a>)
      </p>
    </div>
  };
}

sub init {
  $_[0]->sitename = $_[0]->species_defs->ENSEMBL_SITETYPE;
}

1;
