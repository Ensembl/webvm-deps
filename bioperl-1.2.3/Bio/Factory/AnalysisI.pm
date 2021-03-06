# $Id: AnalysisI.pm,v 1.2.2.1 2003/07/04 02:40:29 shawnh Exp $
#
# BioPerl module for Bio::Factory::AnalysisI
#
# Cared for by Martin Senger <senger@ebi.ac.uk>
# For copyright and disclaimer see below.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::Factory::AnalysisI - An interface to analysis tool factory

=head1 SYNOPSIS

This is an interface module - you do not instantiate it.
Use I<Bio::Tools::Run::AnalysisFactory> module:

  use Bio::Tools::Run::AnalysisFactory;
  my $list = new Bio::Tools::Run::AnalysisFactory->available_analyses;

=head1 DESCRIPTION

This interface contains all public methods for showing available
analyses and for creating objects representing them.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
email or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR

Martin Senger (senger@ebi.ac.uk)

=head1 COPYRIGHT

Copyright (c) 2003, Martin Senger and EMBL-EBI.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind.

=head1 SEE ALSO

=over

=item *

http://industry.ebi.ac.uk/soaplab/Perl_Client.html

=back

=head1 APPENDIX

This is actually the main documentation...

If you try to call any of these methods directly on this
C<Bio::Factory::AnalysisI> object you will get a I<not implemented>
error message. You need to call them on a
C<Bio::Tools::Run::AnalysisFactory> object instead.

=cut


# Let the code begin...

package Bio::Factory::AnalysisI;
use vars qw(@ISA $Revision);
use strict;
use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);

BEGIN {
    $Revision = q$Id: AnalysisI.pm,v 1.2.2.1 2003/07/04 02:40:29 shawnh Exp $;
}


# -----------------------------------------------------------------------------

=head2 available_categories

 Usage   : $factory->available_categories;
 Returns : an array reference with the names of
           available categories
 Args    : none

The analysis tools may be grouped into categories by their functional
similarity, or by the similar data types they deal with. This method
shows all available such categories.

=cut

sub available_categories { shift->throw_not_implemented(); }

# -----------------------------------------------------------------------------

=head2 available_analyses

 Usage   : $factory->available_analyses;
           $factory->available_analyses ($category);
 Returns : an array reference with the names of
           all available analyses, or the analyses
           available in the given '$category'
 Args    : none || category_name

Show available analyses. Their names usually consist of category
analysis names, separated by C<::>.

=cut

sub available_analyses { shift->throw_not_implemented(); }

# -----------------------------------------------------------------------------

=head2 create_analysis

 Usage   : $factory->create_analysis ($name);
 Returns : a Bio::Tools::Run::Analyis object
 Args    : analysis name

A real I<factory> method creating an analysis object. The created
object gets all access and location information from the factory
object.

=cut

sub create_analysis { shift->throw_not_implemented(); }

# -----------------------------------------------------------------------------


1;
__END__

