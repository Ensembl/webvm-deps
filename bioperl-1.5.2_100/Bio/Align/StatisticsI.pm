# $Id: StatisticsI.pm,v 1.7.4.1 2006/10/02 23:10:12 sendu Exp $
#
# BioPerl module for Bio::Align::StatisticsI
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::Align::StatisticsI - Calculate some statistics for an alignment

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the interface here

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Jason Stajich

Email jason@bioperl.org

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::Align::StatisticsI;
use strict;


use base qw(Bio::Root::RootI);

=head2 distance

 Title   : distance
 Usage   : my $distance_mat = $stats->distance(-align  => $aln, 
		 			       -method => $method);
 Function: Calculates a distance matrix for all pairwise distances of
           sequences in an alignment.
 Returns : Array ref
 Args    : -align  => Bio::Align::AlignI object
           -method => String specifying specific distance method 
                      (implementing class may assume a default)

=cut

sub distance{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

=head2 available_distance_methods

 Title   : available_distance_methods
 Usage   : my @methods = $stats->available_distance_methods();
 Function: Enumerates the possible distance methods
 Returns : Array of strings
 Args    : none


=cut

sub available_distance_methods{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

1;
