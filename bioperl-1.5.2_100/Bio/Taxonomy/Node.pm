# $Id: Node.pm,v 1.17.4.1 2006/10/02 23:10:31 sendu Exp $
#
# BioPerl module for Bio::Taxonomy::Node
#
# Cared for by Jason Stajich <jason-at-bioperl-dot-org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Taxonomy::Node - A node in a represented taxonomy

=head1 SYNOPSIS

  use Bio::Taxon;
  # This module has been renamed Bio::Taxon - use that instead

=head1 DESCRIPTION

This module has been renamed Bio::Taxon - use that instead.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Jason Stajich

Email jason-at-bioperl-dot-org

=head1 CONTRIBUTORS

Juguang Xiao,     juguang@tll.org.sg
Gabriel Valiente, valiente@lsi.upc.edu
Sendu Bala,       bix@sendu.me.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::Taxonomy::Node;
use strict;


use base qw(Bio::Taxon);

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->warn("This module has been renamed Bio::Taxon - use that instead");
    return $self;
}

1;