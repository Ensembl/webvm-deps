=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2018-2019] EMBL-European Bioinformatics Institute

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


=pod 

=head1 NAME

Bio::EnsEMBL::Compara::RunnableDB::LoadOneGenomeDB

=head1 SYNOPSIS

        # [preparation] make sure we have copied across NCBI taxonomy information about our species (Human) :
    mysqldump --defaults-group-suffix=_compara3 --where="taxon_id=9606" mp12_compara_homology_72 ncbi_taxa_node ncbi_taxa_name | mysql lg4_compara_generic

        # load a genome_db given a class/keyvalue locator (genome_db_id will be generated)
    standaloneJob.pl LoadOneGenomeDB.pm -compara_db "mysql://ensadmin:${ENSADMIN_PSW}@compara2/lg4_test_load1genome" \
        -locator 'Bio::EnsEMBL::DBSQL::DBAdaptor/host=ens-staging;port=3306;user=ensro;pass=;dbname=homo_sapiens_core_64_37;species=homo_sapiens;species_id=1;disconnect_when_inactive=1'

        # load a genome_db given a url-style locator
    standaloneJob.pl LoadOneGenomeDB.pm -compara_db "mysql://ensadmin:${ENSADMIN_PSW}@compara2/lg4_test_load1genome" \
        -locator "mysql://ensro@ens-staging2/mus_musculus_core_64_37"

        # load a genome_db given a reg_conf and species_name as locator
    standaloneJob.pl LoadOneGenomeDB.pm -compara_db "mysql://ensadmin:${ENSADMIN_PSW}@compara2/lg4_test_load1genome" \
        -reg_conf $ENSEMBL_CVS_ROOT_DIR/ensembl-compara/scripts/examples/ensembldb_reg.conf \
        -locator 'mus_musculus'

        # load a genome_db given a reg_conf and species_name as locator with a specific genome_db_id
    standaloneJob.pl LoadOneGenomeDB.pm -compara_db "mysql://ensadmin:${ENSADMIN_PSW}@compara2/lg4_test_load1genome" \
        -reg_conf $ENSEMBL_CVS_ROOT_DIR/ensembl-compara/scripts/pipeline/production_reg_conf.pl \
        -locator 'homo_sapiens' -genome_db_id 90

=head1 DESCRIPTION

This Runnable loads one entry into 'genome_db' table and passes on the genome_db_id.

The format of the input_id follows the format of a Perl hash reference.
Examples:
    { 'species_name' => 'Homo sapiens', 'assembly_name' => 'GRCh37' }
    { 'species_name' => 'Mus musculus' }

supported keys:
    'locator'       => <string>
        one of the ways to specify the connection parameters to the core database (overrides 'species_name' and 'assembly_name')

    'registry_dbs'  => <list_of_dbconn_hashes>
        another, simple way to specify the genome_db (and let the registry search across multiple mysql instances to do the rest)
    'species_name'  => <string>
        mandatory, but what would you expect?

    'first_found'   => <0|1>
        optional, defaults to 0.
        Defines whether we emulate (to a certain extent) the behaviour of load_registry_from_multiple_dbs
        or try the last one that still fits (this would allow to try ens-staging[12] *first*, and only then check if ens-livemirror has is a suitable copy).

    'assembly_name' => <string>
        optional: in most cases it should be possible to find the species just by using 'species_name'

    'genome_db_id'  => <integer>
        optional, in case you want to specify it (otherwise it will be generated by the adaptor when storing)

    'ensembl_genomes' => <0|1>
        optional, sets the preferential order of precedence of species_name sources, depending on whether the module is run by EG or Compara

    'db_version'    => <integer>
        optional, sets the prefered version of the core databases to load from

=cut

package Bio::EnsEMBL::Compara::RunnableDB::LoadOneGenomeDB;

use strict;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBLoader;
use Bio::EnsEMBL::Compara::GenomeDB;
use Bio::EnsEMBL::Compara::GenomeMF;

use Bio::EnsEMBL::Hive::Utils ('go_figure_dbc');

use base ('Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable');

my $suffix_separator = '__cut_here__';

sub fetch_input {
    my $self = shift @_;

    my $core_dba;

    if(my $locator = $self->param('locator') ) {   # use the locator and skip the registry

        eval {
            $core_dba = Bio::EnsEMBL::DBLoader->new($locator);
        };

        unless($core_dba) {     # assume this is a hive-type locator and try more tricks:
            my $dbc = go_figure_dbc( $locator, 'core' )
                or die "Could not connect to '$locator' as DBC";

            $core_dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new( -DBCONN => $dbc );

            $self->param('locator', $core_dba->locator($suffix_separator) );  # substitute the given locator by one in conventional format
        }
        $self->param('core_dba', $core_dba);
        return;
    }

    if ($self->param('master_dbID')) {
        $self->param('master_dba', Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->go_figure_compara_dba( $self->param_required('master_db') ) );
        my $master_genome_db = $self->param('master_dba')->get_GenomeDBAdaptor->fetch_by_dbID($self->param('master_dbID'));
        $self->param('master_genome_db', $master_genome_db);
        die sprintf("Could not find the genome_db_id %d in the master database\n", $self->param('master_dbID')) if not $master_genome_db;

        # Let's give all the parameters that should uniquely map
        $self->param('species_name', $master_genome_db->name);
        $self->param('genebuild', $master_genome_db->genebuild);
        $self->param('assembly_name', $master_genome_db->assembly);
        $self->param('genome_component', $master_genome_db->genome_component);
    }

    if( $self->param('species_name') ) {    # perform our tricky multiregistry search: find the last one still suitable

        foreach my $this_core_dba (@{$self->iterate_through_registered_species}) {

            my $this_assembly = $this_core_dba->assembly_name();
            my $this_start_date = $this_core_dba->get_MetaContainer->get_genebuild();

            my $genebuild = $self->param('genebuild') || $this_start_date;
            my $assembly_name = $self->param('assembly_name') || $this_assembly;

            if($this_assembly eq $assembly_name && $this_start_date eq $genebuild) {
                $core_dba = $this_core_dba;
                $self->param('assembly_name', $assembly_name);

                if($self->param('first_found')) {
                    last;
                }
            } else {
                warn "Found assembly '$this_assembly' when looking for '$assembly_name', or '$this_start_date' when looking for '$genebuild'\n";
            }

        } # try next registry server
    }

    if( $core_dba ) {
        $self->param('core_dba', $core_dba);
    } else {
        die "Could not find species_name='".$self->param('species_name')."', assembly_name='".$self->param('assembly_name')."' on the servers provided, please investigate";
    }
}

sub run {
    my $self = shift @_;

    my $genome_db = $self->create_genome_db($self->param('core_dba'), $self->param('genome_db_id'), $self->param('locator'), $self->param('genome_component'), $self->param('master_genome_db'));

    $self->param('genome_db', $genome_db);
}

sub write_output {      # store the genome_db and dataflow
    my $self = shift;

    $self->store_and_dataflow_genome_db($self->param('genome_db'));
}

# ------------------------- non-interface subroutines -----------------------------------

sub create_genome_db {
    my ($self, $core_dba, $asked_genome_db_id, $asked_locator, $asked_genome_component, $master_object) = @_;

    my $locator         = $asked_locator || $core_dba->locator($suffix_separator);

    my $genome_db       = Bio::EnsEMBL::Compara::GenomeDB->new(
        -DB_ADAPTOR => $core_dba,
        # Extra arguments that cannot be guessed from the core database
        -GENOME_COMPONENT => $asked_genome_component,
    );
    if ($master_object) {
        $genome_db->_check_equals($master_object);
        $genome_db->dbID($master_object->dbID);
    } elsif ($asked_genome_db_id) {
        $genome_db->dbID( $asked_genome_db_id );
    }
    $genome_db->locator( $locator );

    return $genome_db;
}

sub store_and_dataflow_genome_db {
    my $self = shift @_;
    my $genome_db = shift @_;
    my $branch = shift @_ || 1;

    $self->compara_dba->get_GenomeDBAdaptor->store($genome_db);
    my $genome_db_id            = $genome_db->dbID();

    $self->dataflow_output_id( {
        'genome_db_id' => $genome_db_id,
    }, $branch);
}

sub iterate_through_registered_species {
    my $self = shift;

    my $registry_conf_file = $self->param('registry_conf_file');
    my $registry_dbs = $self->param('registry_dbs') || [];
    my $registry_files = $self->param('registry_files') || [];
    $registry_conf_file || $registry_dbs || $registry_files || die "unless 'locator' is specified, 'registry_conf_file', 'registry_dbs' or 'registry_files' become obligatory parameter";

    my @core_dba_list = ();

    if ($registry_conf_file) {

        Bio::EnsEMBL::Registry->load_all( $registry_conf_file, undef, "no_clear" );
        my $this_core_dba = Bio::EnsEMBL::Registry->get_DBAdaptor($self->param('species_name'), 'core');

        push @core_dba_list, $this_core_dba if ($this_core_dba);

    }

    for(my $r_ind=0; $r_ind<scalar(@$registry_dbs); $r_ind++) {
        my %reg_params = %{ $registry_dbs->[$r_ind] };
        $reg_params{'-db_version'} = $self->param('db_version') if $self->param('db_version') and not $reg_params{'-db_version'};
        Bio::EnsEMBL::Registry->load_registry_from_db( %reg_params, -species_suffix => $suffix_separator.$r_ind, -verbose => $self->debug );

        my $no_alias_check = 1;
        my $this_core_dba = Bio::EnsEMBL::Registry->get_DBAdaptor($self->param('species_name').$suffix_separator.$r_ind, 'core', $no_alias_check) || next;
        push @core_dba_list, $this_core_dba;
    }

    for(my $r_ind=0; $r_ind<scalar(@$registry_files); $r_ind++) {

        my $reg_content = Bio::EnsEMBL::Compara::GenomeMF->all_from_file( $registry_files->[$r_ind] );
        push @core_dba_list, grep {$_->get_production_name() eq $self->param('species_name')} @$reg_content;
    }

    return \@core_dba_list;
}



1;

