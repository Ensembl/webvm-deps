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

=head1 NAME

Bio::EnsEMBL::Hive::RunnableDB::DumpMultiAlign::MD5SUM

=head1 SYNOPSIS

This RunnableDB module is part of the DumpMultiAlign pipeline.

=head1 DESCRIPTION

The RunnableDB module runs the md5sum command

=cut


package Bio::EnsEMBL::Compara::RunnableDB::DumpMultiAlign::MD5SUM;

use strict;
use base ('Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable');

sub fetch_input {
    my $self = shift;

}

sub run {
    my $self = shift;

    #
    #Run md5sum comamnd
    #
    chdir $self->param('output_dir');
    my $cmd = "md5sum *.gz > MD5SUM";

    if(my $return_value = system($cmd)) {
        $return_value >>= 8;
        die "system( $cmd ) failed: $return_value";
    }

}

sub write_output {
    my $self = shift @_;

}

1;
