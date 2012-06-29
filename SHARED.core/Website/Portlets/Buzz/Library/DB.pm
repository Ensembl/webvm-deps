#########
# Author: rmp@psyphi.net
#
package Website::Portlets::Buzz::Library::DB;
use strict;
use Website::Portlets::Buzz::Library;
use vars qw(@ISA);
@ISA = qw(Website::Portlets::Buzz::Library);

sub feeds {
  my $self = shift;
  my $seen = {};

  return grep {
    !$seen->{$_->title()}++;
  } sort {
    $a->title() cmp $b->title()
  } $self->gen_getarray("Website::Portlets::Buzz::Feed",
			qq(SELECT id AS feed
			   FROM   cache));
}

1;
