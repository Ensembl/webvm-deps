=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2018-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=head1 AUTHOR

  Originally from Steve Chervitz.  Refactored by Ewan Birney.

=cut

=head1 NAME

Bio::EnsEMBL::Root

=head1 DESCRIPTION

Do not use Bio::EnsEMBL::Root anymore. It is included for backwards
compatibility (every object in EnsEMBL used to inherit from this class)
but will eventually be phased out. The replacement for the _rearrage
method is the rearrange method which can be imported in the following
way:

  use Bio::EnsEMBL::Utils::Argument qw(rearrange);

  # can now call rearrange as a class method (instead as object method)
  my ( $start, $end ) = rearrange( [ 'START', 'END' ], @args );

If you want to use the throw or warn methods the replacement use the
class methods throw and warning from the Bio::EnsEMBL::Utils::Exception
class:

  use Bio::EnsEMBL::Utils::Exception qw(throw warning);

  # can now call throw or warning even without blessed reference
  warning('This is a warning');
  throw('This is an exception');

This module was stolen from BioPerl to avoid problems with moving to
BioPerl 1 from 0.7

=head1 METHODS

=cut

package Bio::EnsEMBL::Root;

use strict;
use vars qw($VERBOSITY);
use Bio::EnsEMBL::Utils::Exception qw( );
use Bio::EnsEMBL::Utils::Argument qw( );


$VERBOSITY = 0;

sub new{
  my($caller,@args) = @_;
  
  my $class = ref($caller) || $caller;
  return bless({}, $class);
}


=head2 throw

  DEPRECATED

=cut

sub throw{
   my ($self,$string) = @_;

   Bio::EnsEMBL::Utils::Exception->warning("\n------------------ DEPRECATED ---------------------\n".
                                        "Bio::EnsEMBL::Root::throw has been deprecated\n".
					"use Bio::EnsEMBL::Utils::Exception qw(throw); \n".
				        "throw('message'); #instead\n".
					"\n---------------------------------------------------\n");

   Bio::EnsEMBL::Utils::Exception->throw($string);


}

=head2 warn

   DEPRECATED 

=cut

sub warn{
    my ($self,$string) = @_;



    Bio::EnsEMBL::Utils::Exception->warning("\n------------------ DEPRECATED ---------------------\n".
                                        "Bio::EnsEMBL::Root::warn has been deprecated\n".
					 "use Bio::EnsEMBL::Utils::Exception qw(warning); \n".
					 "warning('message'); #instead\n".
					 "\n---------------------------------------------------\n");
    
    Bio::EnsEMBL::Utils::Exception->warning($string);

}
				       


		     
=head2 verbose

  DEPRECATED

=cut

sub verbose{
   my ($self,$value) = @_;

    Bio::EnsEMBL::Utils::Exception->warning("\n------------------ DEPRECATED ---------------------\n".
                                        "Bio::EnsEMBL::Root::verbose has been deprecated\n".
					 "use Bio::EnsEMBL::Utils::Exception qw(verbose); \n".
					 "verbose(value); #instead\n".
					 "\n---------------------------------------------------\n");
    
   Bio::EnsEMBL::Utils::Exception->verbose($value);
   
 }

=head2 stack_trace_dump

  DEPRECATED

=cut

sub stack_trace_dump{
   my ($self) = @_;

    Bio::EnsEMBL::Utils::Exception->warning("\n------------------ DEPRECATED ---------------------\n".
                                        "Bio::EnsEMBL::Root::stack_trace_dump has been deprecated\n".
					 "use Bio::EnsEMBL::Utils::Exception qw(stack_trace_dump); \n".
					 "stack_trace_dump(); #instead\n".
					 "\n---------------------------------------------------\n");

   Bio::EnsEMBL::Utils::Exception->stack_trace_dump();

}


=head2 stack_trace

  DEPRECATED

=cut

sub stack_trace{
   my ($self) = @_;

    Bio::EnsEMBL::Utils::Exception->warning("\n------------------ DEPRECATED ---------------------\n".
                                        "Bio::EnsEMBL::Root::stack_trace has been deprecated\n".
					 "use Bio::EnsEMBL::Utils::Exception qw(stack_trace); \n".
					 "stack_trace(); #instead\n".
					 "\n---------------------------------------------------\n");

   Bio::EnsEMBL::Utils::Exception->stack_trace();

}


=head2 _rearrange

  DEPRECATED

=cut

#----------------'
sub _rearrange {
#----------------
    my($self,$order,@param) = @_;

    my $mess = "use Bio::EnsEMBL::Utils::Argument qw(rearrange); \n";
       $mess .= "rearrange(order, list); #instead\n";

    Bio::EnsEMBL::Utils::Exception->deprecate($mess);

   return Bio::EnsEMBL::Utils::Argument->rearrange($order,@param);

}

1;
