# $Id: Match.pm,v 1.2.2.1 2003/02/20 05:11:45 heikki Exp $
#
# BioPerl module for Bio::Coordinate::Result::Match
#
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copywright Heikki Lehvaslaiho
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code
#

=head1 NAME

Bio::Coordinate::Result::Match - An other name for Bio::Location::Simple

=head1 SYNOPSIS

  $loc = new Bio::Coordinate::Result::Match(-start=>10,
                                            -end=>30,
                                            -strand=>+1);

=head1 DESCRIPTION

This is a location class for coordinate mapping results.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org                         - General discussion
  http://bio.perl.org/MailList.html             - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via email
or the web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Heikki Lehvaslaiho

Email heikki@ebi.ac.uk

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

package Bio::Coordinate::Result::Match;
use vars qw(@ISA);
use strict;

use Bio::Location::Simple;
use Bio::Coordinate::ResultI;

@ISA = qw(Bio::Location::Simple Bio::Coordinate::ResultI);


1;
