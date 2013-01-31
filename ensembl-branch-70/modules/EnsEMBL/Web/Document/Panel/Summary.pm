# $Id: Summary.pm,v 1.4 2010-09-28 10:12:32 sb23 Exp $

package EnsEMBL::Web::Document::Panel::Summary;

use strict;

use base qw(EnsEMBL::Web::Document::Panel);

sub add_description {
  my ($self, $description) = @_;
  return "<p>$description</p>";
}

sub add_row {
  my ($self, $label, $content) = @_;
  
  return qq{
    <dl class="summary">
      <dt>$label</dt>
      <dd>
        $content
      </dd>
    </dl>
  };
}

1;
