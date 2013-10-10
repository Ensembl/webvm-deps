=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

   http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=head1 NAME

  Bio::EnsEMBL::Compara::PipeConfig::ProteinTrees_conf

=head1 DESCRIPTION

    The PipeConfig file for ProteinTrees pipeline that should automate most of the pre-execution tasks.

=head1 SYNOPSIS

    #1. update ensembl-hive, ensembl and ensembl-compara CVS repositories before each new release

    #2. you may need to update 'schema_version' in meta table to the current release number in ensembl-hive/sql/tables.sql

    #3. make sure that all default_options are set correctly

    #4. Run init_pipeline.pl script:
        init_pipeline.pl Bio::EnsEMBL::Compara::PipeConfig::ProteinTrees_conf -password <your_password> -mlss_id <your_current_PT_mlss_id>

    #5. Sync and loop the beekeeper.pl as shown in init_pipeline.pl's output

=head1 AUTHORSHIP

Ensembl Team. Individual contributions can be found in the CVS log.

=head1 MAINTAINER

$Author: mm14 $

=head VERSION

$Revision: 1.168 $

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::PipeConfig::ProteinTrees_conf;

use strict;
use warnings;

use Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf;

use base ('Bio::EnsEMBL::Compara::PipeConfig::ComparaGeneric_conf');


sub default_options {
    my ($self) = @_;

    return {
        %{$self->SUPER::default_options},   # inherit the generic ones

    # parameters that are likely to change from execution to another:
#       'mlss_id'               => 40077,   # it is very important to check that this value is current (commented out to make it obligatory to specify)
        #'release'               => '68',
        #'work_dir'              => '/lustre/scratch101/ensembl/'.$self->o('ENV', 'USER').'/protein_trees_'.$self->o('rel_with_suffix'),
        'do_not_reuse_list'     => [ ],     # names of species we don't want to reuse this time
        'method_link_dump_file' => $self->o('ensembl_cvs_root_dir').'/ensembl-compara/sql/method_link.txt',


    # dependent parameters: updating 'work_dir' should be enough
        'pipeline_basename' => 'PT',
        'pipeline_name'         => $self->o('pipeline_basename'),   # name the pipeline to differentiate the submitted processes
        'fasta_dir'             => $self->o('work_dir') . '/blast_db',  # affects 'dump_subset_create_blastdb' and 'blastp_with_reuse'
        'cluster_dir'           => $self->o('work_dir') . '/cluster',
        'dump_dir'              => $self->o('work_dir') . '/dumps',

    # blast parameters:
        'blast_params'              => '-seg no -max_hsps_per_subject 1 -use_sw_tback -num_threads 1',
        'per_species_blast_min_length'   => 5,

        'protein_members_range'     => 100000000, # highest member_id for a protein member

    # clustering parameters:
        'outgroups'                     => [],      # affects 'hcluster_dump_input_per_genome'
        'clustering_max_gene_halfcount' => 750,     # (half of the previously used 'clutering_max_gene_count=1500) affects 'hcluster_run'

    # tree building parameters:
        'treebreak_gene_count'      => 400,     # affects msa_chooser
        'mafft_gene_count'          => 200,     # affects msa_chooser
        'mafft_runtime'             => 7200,    # affects msa_chooser
        'use_genomedb_id'           => 0,       # affects 'njtree_phyml' and 'ortho_tree'
        'species_tree_input_file'   => '',      # you can define your own species_tree for 'njtree_phyml' and 'ortho_tree'

    # homology_dnds parameters:
        'codeml_parameters_file'    => $self->o('ensembl_cvs_root_dir').'/ensembl-compara/scripts/pipeline/protein_trees.codeml.ctl.hash',      # used by 'homology_dNdS'
        'taxlevels'                 => [],
        'filter_high_coverage'      => 0,   # affects 'group_genomes_under_taxa'

    # mapping parameters:
        'do_stable_id_mapping'      => 1,
        'do_treefam_xref'           => 0,

    # executable locations:
        #'hcluster_exe'              => '/software/ensembl/compara/hcluster/hcluster_sg',
        #'mcoffee_home'              => '/software/ensembl/compara/tcoffee/Version_9.03.r1318/',
        #'mafft_home'                => '/software/ensembl/compara/mafft-7.017/',
        #'sreformat_exe'             => '/usr/local/ensembl/bin/sreformat',
        #'treebest_exe'              => '/software/ensembl/compara/treebest.doubletracking',
        #'quicktree_exe'             => '/software/ensembl/compara/quicktree_1.1/bin/quicktree',
        #'buildhmm_exe'              => '/software/ensembl/compara/hmmer3/hmmer-3.0/src/hmmbuild',
        #'codeml_exe'                => '/usr/local/ensembl/bin/codeml',
        #'blast_bin_dir'             => '/software/ensembl/compara/ncbi-blast-2.2.27+/bin',

    # HMM specific parameters
        #'hmm_clustering'            => 0, ## by default run blastp clustering
        #'cm_file_or_directory'      => '/lustre/scratch109/sanger/fs9/treefam8_hmms',
        #'hmm_library_basedir'       => '/lustre/scratch109/sanger/fs9/treefam8_hmms',
        ##'cm_file_or_directory'      => '/lustre/scratch110/ensembl/mp12/panther_hmms/PANTHER7.2_ascii', ## Panther DB
        ##'hmm_library_basedir'       => '/lustre/scratch110/ensembl/mp12/Panther_hmms',
        #'pantherScore_path'         => '/software/ensembl/compara/pantherScore1.03',
        #'hmmer_path'                => '/software/ensembl/compara/hmmer-2.3.2/src/',

    # hive_capacity values for some analyses:
        #'reuse_capacity'            =>   4,
        #'blast_factory_capacity'    =>  50,
        #'blastp_capacity'           => 900,
        #'mcoffee_capacity'          => 600,
        #'split_genes_capacity'      => 600,
        #'njtree_phyml_capacity'     => 400,
        #'ortho_tree_capacity'       => 200,
        #'ortho_tree_annot_capacity' => 300,
        #'quick_tree_break_capacity' => 100,
        #'build_hmm_capacity'        => 200,
        #'ktreedist_capacity'        =>  50,
        #'merge_supertrees_capacity' => 100,
        #'other_paralogs_capacity'   => 100,
        #'homology_dNdS_capacity'    => 200,
        #'qc_capacity'               =>   4,
        #'hc_capacity'               =>   4,
        #'HMMer_classify_capacity'   => 100,

    # connection parameters to various databases:

        # Uncomment and update the database locations

        # the production database itself (will be created)
        #'pipeline_db' => {
        #    -host   => 'compara3',
        #    -port   => 3306,
        #    -user   => 'ensadmin',
        #    -pass   => $self->o('password'),
        #    -dbname => $self->o('ENV', 'USER').'_compara_homology_'.$self->o('rel_with_suffix'),
        #},

        # the master database for synchronization of various ids
        #'master_db' => {
        #    -host   => 'compara1',
        #    -port   => 3306,
        #    -user   => 'ensro',
        #    -pass   => '',
        #    -dbname => 'sf5_ensembl_compara_master',
        #},
        'master_db' => undef,
        'ncbi_db' => $self->o('master_db'),
        'use_master_db'         => 1,

        # Add the database entries for the current core databases and link 'curr_core_sources_locs' to them
        #'curr_core_sources_locs'    => [ $self->o('staging_loc1'), $self->o('staging_loc2') ],
        'curr_file_sources_locs'    => [  ],    # It can be a list of JSON files defining an additionnal set of species

        # Add the database entries for the core databases of the previous release
        #'prev_core_sources_locs'   => [ $self->o('livemirror_loc') ],

        # Add the database location of the previous Compara release
        #'prev_rel_db' => {
        #   -host   => 'compara3',
        #   -port   => 3306,
        #   -user   => 'ensro',
        #   -pass   => '',
        #   -dbname => 'mm14_compara_homology_67',
        #},

        # Are we reusing the dbIDs and the blastp alignments ?
        'reuse_from_prev_rel_db'    => 0,
        'force_blast_run'           => 1,

        'prev_release'              => 0,   # 0 is the default and it means "take current release number and subtract 1"

    };
}


sub pipeline_create_commands {
    my ($self) = @_;

    # There must be some species on which to compute trees
    die "There must be some species on which to compute trees"
        if ref $self->o('curr_core_sources_locs') and not scalar(@{$self->o('curr_core_sources_locs')})
        and ref $self->o('curr_file_sources_locs') and not scalar(@{$self->o('curr_file_sources_locs')});

    # If the pipeline should use genome_db_ids, the user MUST provide a species tree
    die "use_genomedb_id is only possible with a custom species tree" if $self->o('use_genomedb_id') and not $self->o('species_tree_input_file');

    # The master db must be defined to allow mapping stable_ids and checking species for reuse
    die "The master dabase must be defined with a mlss_id" if $self->o('use_master_db') and not ($self->o('master_db') and $self->o('mlss_id'));
    die "Mapping of stable_id is only possible with a master database" if $self->o('do_stable_id_mapping') and not $self->o('use_master_db');
    die "Species reuse is only possible with a master database" if $self->o('reuse_from_prev_rel_db') and not $self->o('use_master_db');
    die "Species reuse is only possible with a previous compara database" if $self->o('reuse_from_prev_rel_db') and not $self->o('prev_rel_db');
    die "Species reuse is only possible with some previous core databases" if $self->o('reuse_from_prev_rel_db') and ref $self->o('prev_core_sources_locs') and not scalar(@{$self->o('prev_core_sources_locs')});

    # Without a master database, we must provide other parameters
    die if not $self->o('use_master_db') and not $self->o('ncbi_db');

    return [
        @{$self->SUPER::pipeline_create_commands},  # here we inherit creation of database, hive tables and compara tables

        'mkdir -p '.$self->o('cluster_dir'),
        'mkdir -p '.$self->o('dump_dir'),
        'mkdir -p '.$self->o('fasta_dir'),

            # perform "lfs setstripe" only if lfs is runnable and the directory is on lustre:
        'which lfs && lfs getstripe '.$self->o('fasta_dir').' >/dev/null 2>/dev/null && lfs setstripe '.$self->o('fasta_dir').' -c -1 || echo "Striping is not available on this system" ',
    ];
}


sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
            %{$self->SUPER::pipeline_wide_parameters},
            'hc_member_type'  => 'ENSEMBLPEP',
           };
}


sub pipeline_analyses {
    my ($self) = @_;
    return [

# ---------------------------------------------[backbone]--------------------------------------------------------------------------------

        {   -logic_name => 'backbone_fire_db_prepare',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -input_ids  => [ {
                'output_file'   => $self->o('dump_dir').'/#filename#',
            } ],
            -flow_into  => {
                '1->A'  => [ 'copy_ncbi_tables_factory' ],
                'A->1'  => [ 'backbone_fire_genome_load' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'backbone_fire_genome_load',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
            -parameters => {
                'table_list'        => '',
                'filename'          => 'snapshot_1_before_genome_load.sql',
            },
            -flow_into  => {
                '1->A'  => [ 'genome_reuse_factory' ],
                'A->1'  => [ $self->o('hmm_clustering') ? 'backbone_fire_hmmClassify' : 'backbone_fire_allvsallblast' ],
            },
        },

       $self->o('hmm_clustering') ? (
            {
             -logic_name => 'backbone_fire_hmmClassify',
             -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
             -parameters => {
                             'table_list' => '',
                             'filename'       => 'snapshot_2_before_hmmClassify.sql',
                            },
            -flow_into  => {
                            '1->A' => [ 'load_models' ],
                            'A->1' => [ 'backbone_fire_tree_building' ],
                           },
            },
        ) : (), # do not show the hmm analysis if the option is off

### For hmmalign instead of mcoffee
#             {
#              -logic_name => 'backbone_fire_hmmAlign',
#              -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
#              -parameters => {
#                              'updated_tables' => 'gene_tree_root gene_tree_root_tag gene_tree_node gene_tree_node_tag gene_tree_node_attr',
#                              'filename'       => 'snapshot_before_hmmalign.sql',
#                              'output_file'    => $self->o('dump_dir') . '/#filename#',
#                             }
#             },

        {   -logic_name => 'backbone_fire_allvsallblast',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
            -parameters => {
                'table_list'    => '',
                'filename'      => 'snapshot_2_before_allvsallblast.sql',
            },
            -flow_into  => {
                '1->A'  => [ 'paf_reuse_factory' ],
                'A->1'  => [ 'backbone_fire_hcluster' ],
            },
        },

        {   -logic_name => 'backbone_fire_hcluster',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
            -parameters => {
                'table_list'    => '',
                'filename'      => 'snapshot_3_before_hcluster.sql',
            },
            -flow_into  => {
                '1->A'  => [ 'hcluster_dump_factory' ],
                'A->1'  => [ 'backbone_fire_tree_building' ],
            },
        },

        {   -logic_name => 'backbone_fire_tree_building',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
            -parameters => {
                'table_list'    => 'peptide_align_feature_%',
                'exclude_list'  => 1,
                'filename'      => 'snapshot_4_before_tree_building.sql',
            },
            -flow_into  => {
                '1->A'  => [ 'cluster_factory' ],
                'A->1'  => [ 'backbone_fire_dnds' ],
            },
        },

        {   -logic_name => 'backbone_fire_dnds',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
            -parameters => {
                'table_list'    => 'peptide_align_feature_%',
                'exclude_list'  => 1,
                'filename'      => 'snapshot_5_before_dnds.sql',
            },
            -flow_into  => {
                '1->A'  => [ 'group_genomes_under_taxa' ],
                'A->1'  => [ 'backbone_fire_name_mapping' ],
            },
        },

        {   -logic_name => 'backbone_fire_name_mapping',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
            -parameters => {
                'table_list'    => 'peptide_align_feature_%',
                'exclude_list'  => 1,
                'filename'      => 'snapshot_6_before_name_mapping.sql',
            },
            -flow_into  => {
                '1->A'  => [ 'fire_enabled_mappings' ],
                'A->1'  => [ 'backbone_pipeline_finished' ],
            },
        },


        {   -logic_name => 'backbone_pipeline_finished',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -meadow_type    => 'LOCAL',
        },

# ---------------------------------------------[copy tables from master]-----------------------------------------------------------------

        {   -logic_name => 'copy_ncbi_tables_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'inputlist'    => [ 'ncbi_taxa_node', 'ncbi_taxa_name' ],
                'column_names' => [ 'table' ],
                'fan_branch_code' => 2,
            },
            -flow_into => {
                '2->A' => [ 'copy_ncbi_table'  ],
                'A->1' => [ $self->o('use_master_db') ? 'populate_method_links_db' : 'populate_method_links_file' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name    => 'copy_ncbi_table',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::MySQLTransfer',
            -parameters    => {
                'src_db_conn'   => $self->o('ncbi_db'),
                'mode'          => 'overwrite',
                'filter_cmd'    => 'sed "s/ENGINE=MyISAM/ENGINE=InnoDB/"',
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name    => 'populate_method_links_db',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::MySQLTransfer',
            -parameters    => {
                'src_db_conn'   => $self->o('master_db'),
                'mode'          => 'overwrite',
                'filter_cmd'    => 'sed "s/ENGINE=MyISAM/ENGINE=InnoDB/"',
                'table'         => 'method_link',
            },
            -analysis_capacity  => 1,
            -flow_into      => [ 'load_genomedb_factory' ],
            -meadow_type    => 'LOCAL',
        },

# ---------------------------------------------[load GenomeDB entries from master+cores]---------------------------------------------

        {   -logic_name => 'load_genomedb_factory',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ObjectFactory',
            -parameters => {
                'compara_db'            => $self->o('master_db'),   # that's where genome_db_ids come from

                'call_list'             => [ 'compara_dba', 'get_MethodLinkSpeciesSetAdaptor', ['fetch_by_dbID', $self->o('mlss_id')], 'species_set_obj', 'genome_dbs'],
                'column_names2getters'  => { 'genome_db_id' => 'dbID', 'species_name' => 'name', 'assembly_name' => 'assembly', 'genebuild' => 'genebuild', 'locator' => 'locator' },

                'fan_branch_code'       => 2,
            },
            -flow_into => {
                '2->A' => [ 'load_genomedb' ],
                'A->1' => [ 'create_mlss_ss' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'load_genomedb',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::LoadOneGenomeDB',
            -parameters => {
                'registry_dbs'  => $self->o('curr_core_sources_locs'),
                'db_version'    => $self->o('release'),
                'registry_files'    => $self->o('curr_file_sources_locs'),
            },
            -analysis_capacity => 1,
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name     => 'populate_method_links_file',
            -module         => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters     => {
                'method_link_dump_file' => $self->o('method_link_dump_file'),
                'command_line_db'   => $self->dbconn_2_mysql('pipeline_db', 1),
                'cmd'               => 'mysqlimport #command_line_db# #method_link_dump_file#',
            },
            -flow_into      => [ 'load_all_genomedbs' ],
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'load_all_genomedbs',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::LoadAllGenomeDBs',
            -parameters => {
                'registry_dbs'  => $self->o('curr_core_sources_locs'),
                'db_version'    => $self->o('release'),
                'registry_files'    => $self->o('curr_file_sources_locs'),
            },
            -analysis_capacity => 1,
            -meadow_type    => 'LOCAL',
            -flow_into => [ 'create_mlss_ss' ],
        },
# ---------------------------------------------[filter genome_db entries into reusable and non-reusable ones]------------------------

        {   -logic_name => 'create_mlss_ss',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::PrepareSpeciesSetsMLSS',
            -parameters => $self->o('use_master_db') ? {
                'mlss_id'   => $self->o('mlss_id'),
                'master_db' => $self->o('master_db'),
            } : {},
            -flow_into => [ 'make_species_tree', 'check_reuse_factory' ],
            -meadow_type    => 'LOCAL',
        },



        {   -logic_name => 'check_reuse_factory',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ObjectFactory',
            -parameters => {
                'call_list'             => [ 'compara_dba', 'get_GenomeDBAdaptor', 'fetch_all'],
                'column_names2getters'  => { 'genome_db_id' => 'dbID' },

                'fan_branch_code'       => 2,
            },
            -flow_into  => {
                '2->A' => [ 'check_reusability' ],
                'A->1' => [ 'extra_sql_prepare' ],
            },
            -meadow_type    => 'LOCAL',
        },


        {   -logic_name => 'check_reusability',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::CheckGenomedbReusability',
            -parameters => {
                $self->o('reuse_from_prev_rel_db' ) ? ('reuse_db' => $self->o('prev_rel_db')) : (),
                'registry_dbs'      => $self->o('prev_core_sources_locs'),
                'release'           => $self->o('release'),
                'prev_release'      => $self->o('prev_release'),
                'do_not_reuse_list' => $self->o('do_not_reuse_list'),
            },
            -hive_capacity => 10,
            -rc_name => '500Mb_job',
            -flow_into => {
                2 => {
                    'mysql:////species_set' => { 'genome_db_id' => '#genome_db_id#', 'species_set_id' => '#reuse_ss_id#' },
                },
                3 => {
                    'mysql:////species_set' => { 'genome_db_id' => '#genome_db_id#', 'species_set_id' => '#nonreuse_ss_id#' },
                },
            },
        },

        {   -logic_name    => 'extra_sql_prepare',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SqlCmd',
            -parameters => {
                'sql' => [
                    # Stores the species sets in CSV format
                    'INSERT INTO meta (meta_key,meta_value) SELECT "reuse_ss_csv", IFNULL(GROUP_CONCAT(genome_db_id), "-1") FROM species_set WHERE species_set_id=#reuse_ss_id#',
                    'INSERT INTO meta (meta_key,meta_value) SELECT "nonreuse_ss_csv", IFNULL(GROUP_CONCAT(genome_db_id), "-1") FROM species_set WHERE species_set_id=#nonreuse_ss_id#',
                    # Non species-set related query. Speeds up the split-genes search
                    'ALTER TABLE member ADD KEY gene_list_index (source_name, taxon_id, chr_name, chr_strand, chr_start)',
                    # Counts the number of species
                    'INSERT INTO meta (meta_key,meta_value) SELECT "species_count", COUNT(*) FROM genome_db',
                ],
            },
            -meadow_type    => 'LOCAL',
        },

# ---------------------------------------------[load species tree]-------------------------------------------------------------------

        {   -logic_name    => 'make_species_tree',
            -module        => 'Bio::EnsEMBL::Compara::RunnableDB::MakeSpeciesTree',
            -parameters    => {
                'species_tree_input_file' => $self->o('species_tree_input_file'),   # empty by default, but if nonempty this file will be used instead of tree generation from genome_db
            },
            -flow_into  => {
                3 => { 'mysql:////method_link_species_set_tag' => { 'method_link_species_set_id' => '#mlss_id#', 'tag' => 'species_tree', 'value' => '#species_tree_string#' } },
            },
        },

# ---------------------------------------------[reuse members]-----------------------------------------------------------------------

        {   -logic_name => 'genome_reuse_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'inputquery'        => 'SELECT genome_db_id, name FROM species_set JOIN genome_db USING (genome_db_id) WHERE species_set_id = #reuse_ss_id#',
                'fan_branch_code'   => 2,
            },
            -flow_into => {
                '2->A' => [ 'sequence_table_reuse' ],
                'A->1' => [ 'genome_loadfresh_factory' ],
            },
            -meadow_type    => 'LOCAL',
        },


        {   -logic_name => 'sequence_table_reuse',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                            'db_conn'    => $self->o('prev_rel_db'),
                            'inputquery' => 'SELECT s.* FROM sequence s JOIN member USING (sequence_id) WHERE sequence_id<='.$self->o('protein_members_range').' AND genome_db_id = #genome_db_id#',
                            'fan_branch_code' => 2,
            },
            -hive_capacity => $self->o('reuse_capacity'),
            -rc_name => '500Mb_job',
            -flow_into => {
                2 => [ 'mysql:////sequence' ],
                1 => [ 'member_table_reuse' ],
            },
        },

        {   -logic_name => 'member_table_reuse',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::MySQLTransfer',
            -parameters => {
                'src_db_conn'   => $self->o('prev_rel_db'),
                'table'         => 'member',
                'where'         => 'member_id<='.$self->o('protein_members_range').' AND genome_db_id = #genome_db_id#',
                'mode'          => 'insertignore',
            },
            -hive_capacity => $self->o('reuse_capacity'),
            -flow_into => {
                1 => [ 'other_sequence_table_reuse' ],
            },
        },

        {   -logic_name => 'other_sequence_table_reuse',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                            'db_conn'    => $self->o('prev_rel_db'),
                            'inputquery' => 'SELECT s.member_id, s.seq_type, s.length, s.sequence FROM other_member_sequence s JOIN member USING (member_id) WHERE genome_db_id = #genome_db_id# AND seq_type IN ("cds", "exon_bounded") AND member_id <= '.$self->o('protein_members_range'),
                            'fan_branch_code' => 2,
            },
            -hive_capacity => $self->o('reuse_capacity'),
            -rc_name => '1Gb_job',
            -flow_into => {
                2 => [ 'mysql:////other_member_sequence' ],
                1 => [ 'hc_factory_members_per_genome' ],
            },
        },


# ---------------------------------------------[load the rest of members]------------------------------------------------------------

        {   -logic_name => 'genome_loadfresh_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'inputquery'        => 'SELECT genome_db_id, name FROM species_set JOIN genome_db USING (genome_db_id) WHERE species_set_id = #nonreuse_ss_id# AND locator LIKE "Bio::EnsEMBL::DBSQL::DBAdaptor/%"',
                'fan_branch_code'   => 2,
            },
            -flow_into => {
                '2->A' => [ 'load_fresh_members' ],
                '1->A' => [ 'genome_loadfresh_fromfile_factory' ],
                'A->1' => [ 'hc_factory_members_globally' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'genome_loadfresh_fromfile_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'inputquery'        => 'SELECT genome_db_id, name FROM species_set JOIN genome_db USING (genome_db_id) WHERE species_set_id = #nonreuse_ss_id# AND locator NOT LIKE "Bio::EnsEMBL::DBSQL::DBAdaptor/%"',
                'fan_branch_code'   => 2,
            },
            -flow_into => {
                2 => [ 'load_fresh_members_fromfile' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'load_fresh_members',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::LoadMembers',
            -parameters => {
                'store_related_pep_sequences' => 1,
                'allow_pyrrolysine'             => 0,
            },
            -rc_name => '2Gb_job',
            -flow_into => [ 'hc_factory_members_per_genome' ],
        },

        {   -logic_name => 'load_fresh_members_fromfile',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::LoadMembersFromFiles',
            -parameters => {
                -need_cds_seq   => 1,
            },
            -rc_name => '2Gb_job',
            -flow_into => [ 'hc_factory_members_per_genome' ],
        },


# ---------------------------------------------[create and populate blast analyses]--------------------------------------------------

        {   -logic_name => 'paf_reuse_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'force_blast_run'   => $self->o('force_blast_run'),
                'inputquery'        => 'SELECT genome_db_id, name FROM species_set JOIN genome_db USING (genome_db_id) WHERE species_set_id = #reuse_ss_id# AND NOT #force_blast_run#',
                'fan_branch_code'   => 2,
            },
            -flow_into => {
                '2->A' => [ 'paf_table_reuse' ],
                '1->A' => [ 'paf_noreuse_factory' ],
                'A->1' => [ 'blastdb_factory' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'paf_noreuse_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'force_blast_run'   => $self->o('force_blast_run'),
                'inputquery'        => 'SELECT genome_db_id, name FROM species_set JOIN genome_db USING (genome_db_id) WHERE species_set_id = #nonreuse_ss_id# OR #force_blast_run#',
                'fan_branch_code'   => 2,
            },
            -flow_into => {
                2 => [ 'paf_create_empty_table' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'paf_table_reuse',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::MySQLTransfer',
            -parameters => {
                'src_db_conn'   => $self->o('prev_rel_db'),
                'table'         => 'peptide_align_feature_#genome_db_id#',
                'filter_cmd'    => 'sed "s/ENGINE=MyISAM/ENGINE=InnoDB/"',
                'where'         => 'hgenome_db_id IN (#reuse_ss_csv#)',
            },
            -hive_capacity => $self->o('reuse_capacity'),
        },

        {   -logic_name => 'paf_create_empty_table',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SqlCmd',
            -parameters => {
                'sql' => [  'CREATE TABLE IF NOT EXISTS peptide_align_feature_#genome_db_id# LIKE peptide_align_feature',
                            'ALTER TABLE peptide_align_feature_#genome_db_id# DISABLE KEYS, AUTO_INCREMENT=#genome_db_id#00000000',
                ],
            },
            -analysis_capacity => 1,
            -meadow_type    => 'LOCAL',
        },

#----------------------------------------------[classify canonical members based on HMM searches]-----------------------------------
       $self->o('hmm_clustering') ? (
            {
            -logic_name => 'load_models',
             -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::PantherLoadModels',
             -parameters => {
                             'cm_file_or_directory' => $self->o('cm_file_or_directory'),
                             'hmmer_path'           => $self->o('hmmer_path'), # For hmmemit (in case it is necessary to get the consensus for each model to create the blast db)
                             'pantherScore_path'    => $self->o('pantherScore_path'),
                            },
             -flow_into  => {
                             '1->A' => [ 'dump_models' ],
                             'A->1' => [ 'HMMer_factory' ],
                            },

            },

            {
             -logic_name => 'dump_models',
             -module     => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::DumpModels',
             -parameters => {
                             'hmm_library_basedir' => $self->o('hmm_library_basedir'),
                             'blast_bin_dir'       => $self->o('blast_bin_dir'),  ## For creating the blastdb (formatdb or mkblastdb)
                             'pantherScore_path'    => $self->o('pantherScore_path'),
                            },
            },

            {
             -logic_name  => 'HMMer_factory',
             -module      => 'Bio::EnsEMBL::Compara::RunnableDB::ObjectFactory',
             -parameters  => {
                              'call_list'            => [ 'compara_dba', 'get_GenomeDBAdaptor', 'fetch_all' ],
                              'column_names2getters' => { 'genome_db_id' => 'dbID' },
                              'fan_branch_code'      => 2,
                             },
             -flow_into  => {
                             '2->A' => [ 'HMMer_classify' ],
                             'A->1' => [ 'HMM_clusterize' ]
                            },
            },

            {
             -logic_name => 'HMMer_classify',
             -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::HMMClassify',
             -parameters => {
                             'blast_bin_dir'       => $self->o('blast_bin_dir'),
                             'pantherScore_path'   => $self->o('pantherScore_path'),
                             'hmmer_path'          => $self->o('hmmer_path'),
                             'hmm_library_basedir' => $self->o('hmm_library_basedir'),
                             'cluster_dir'         => $self->o('cluster_dir'),
                            },
             -hive_capacity => $self->o('HMMer_classify_capacity'),
             -rc_name => '8Gb_job',
            },

            {
             -logic_name => 'HMM_clusterize',
             -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::HMMClusterize',
             -parameters => {
                             'cluster_dir'        => $self->o('cluster_dir'),
                            },
             -rc_name => '8Gb_job',
             -flow_into => [ 'run_qc_tests' ],
            },

        ) : (), # do not show the hmm analysis if the option is off

# ---------------------------------------------[create and populate blast analyses]--------------------------------------------------

        {   -logic_name => 'blastdb_factory',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ObjectFactory',
            -parameters => {
                'call_list'             => [ 'compara_dba', 'get_GenomeDBAdaptor', 'fetch_all'],
                'column_names2getters'  => { 'genome_db_id' => 'dbID' },

                'fan_branch_code'       => 2,
            },
            -flow_into  => {
                '2->A'  => [ 'dump_canonical_members' ],
                'A->1'  => [ 'blast_species_factory' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'dump_canonical_members',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::DumpMembersIntoFasta',
            -parameters => {
                'only_canonical'            => 1,
                'fasta_dir'                 => $self->o('fasta_dir'),
            },
            -rc_name       => '250Mb_job',
            -hive_capacity => $self->o('reuse_capacity'),
            -flow_into => [ 'make_blastdb' ],
        },

        {   -logic_name => 'make_blastdb',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters => {
                'fasta_dir'     => $self->o('fasta_dir'),
                'blast_bin_dir' => $self->o('blast_bin_dir'),
                'cmd' => '#blast_bin_dir#/makeblastdb -dbtype prot -parse_seqids -logfile #fasta_name#.blastdb_log -in #fasta_name#',
            },
        },

        {   -logic_name => 'blast_species_factory',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ObjectFactory',
            -parameters => {
                'call_list'             => [ 'compara_dba', 'get_GenomeDBAdaptor', 'fetch_all'],
                'column_names2getters'  => { 'genome_db_id' => 'dbID', 'name' => 'name' },

                'fan_branch_code'       => 2,
            },
            -flow_into  => {
                '2'  => [ 'blast_long_member_factory' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'blast_long_member_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'limit_length'          => $self->o('per_species_blast_min_length'),
                'inputquery'            => 'SELECT mp.member_id, gdb.genome_db_id AS target_genome_db_id FROM member mg JOIN member mp ON mg.canonical_member_id = mp.member_id JOIN sequence s ON s.sequence_id = mp.sequence_id JOIN genome_db gdb WHERE mg.genome_db_id = #genome_db_id# AND length >= #limit_length#*1000',
                'fan_branch_code'       => 2,
            },
            -hive_capacity => $self->o('blast_factory_capacity'),
            -flow_into => {
                '2->A' => [ 'blastp_with_reuse' ],
                '1->A' => [ 'blast_short_member_factory' ],
                'A->1' => [ 'hc_factory_pafs' ],
            },
        },

        {   -logic_name => 'blast_short_member_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'limit_length'          => $self->o('per_species_blast_min_length'),
                'inputquery'            => 'SELECT mp.member_id FROM member mg JOIN member mp ON mg.canonical_member_id = mp.member_id JOIN sequence s ON s.sequence_id = mp.sequence_id WHERE mg.genome_db_id = #genome_db_id# AND length < #limit_length#*1000',
                'fan_branch_code'       => 2,
            },
            -hive_capacity => $self->o('blast_factory_capacity'),
            -flow_into => {
                2 => [ 'blastp_with_reuse' ],
            },
        },

        {   -logic_name         => 'blastp_with_reuse',
            -module             => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::BlastpWithReuse',
            -parameters         => {
                'blast_params'              => $self->o('blast_params'),
                'fasta_dir'                 => $self->o('fasta_dir'),
                'blast_bin_dir'             => $self->o('blast_bin_dir'),
                'evalue_limit'              => 1e-10,
                'force_blast_run'           => $self->o('force_blast_run'),
                'allow_same_species_hits'   => 1,
            },
            -batch_size    => 40,
            -rc_name       => '250Mb_job',
            -hive_capacity => $self->o('blastp_capacity'),
        },

# ---------------------------------------------[clustering step]---------------------------------------------------------------------

        {   -logic_name => 'hcluster_dump_factory',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ObjectFactory',
            -parameters => {
                'call_list'             => [ 'compara_dba', 'get_GenomeDBAdaptor', 'fetch_all'],
                'column_names2getters'  => { 'genome_db_id' => 'dbID' },

                'fan_branch_code'       => 2,
            },
            -flow_into  => {
                '2->A' => [ 'hcluster_dump_input_per_genome' ],
                'A->1' => [ 'hcluster_merge_factory' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'hcluster_dump_input_per_genome',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::HclusterPrepare',
            -parameters => {
                'outgroups'     => $self->o('outgroups'),
                'cluster_dir'   => $self->o('cluster_dir'),
            },
            -hive_capacity => $self->o('reuse_capacity'),
        },

        {   -logic_name    => 'hcluster_merge_factory',
            -module         => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -flow_into => {
                '1->A' => {
                    'hcluster_merge_inputs' => [{'ext' => 'txt'}, {'ext' => 'cat'}],
                },
                'A->1' => [ 'hcluster_run' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name    => 'hcluster_merge_inputs',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters    => {
                'cluster_dir'   => $self->o('cluster_dir'),
                'cmd'           => 'cat #cluster_dir#/*.hcluster.#ext# > #cluster_dir#/hcluster.#ext#',
            },
        },

        {   -logic_name    => 'hcluster_run',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters    => {
                'clustering_max_gene_halfcount' => $self->o('clustering_max_gene_halfcount'),
                'cluster_dir'                   => $self->o('cluster_dir'),
                'hcluster_exe'                  => $self->o('hcluster_exe'),
                'cmd'                           => '#hcluster_exe# -m #clustering_max_gene_halfcount# -w 0 -s 0.34 -O -C #cluster_dir#/hcluster.cat -o #cluster_dir#/hcluster.out #cluster_dir#/hcluster.txt',
            },
            -flow_into => {
                1 => [ 'hcluster_parse_output' ],
            },
            -rc_name => 'urgent_hcluster',
        },

        {   -logic_name => 'hcluster_parse_output',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::HclusterParseOutput',
            -parameters => {
                'cluster_dir'               => $self->o('cluster_dir'),
                'additional_clustersets'    => [qw(phyml-aa phyml-nt nj-dn nj-ds nj-mm)],
            },
            -rc_name => '250Mb_job',
            -flow_into => [ 'run_qc_tests' ],
        },

# ---------------------------------------------[Pluggable QC step]----------------------------------------------------------

        {   -logic_name => 'run_qc_tests',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ObjectFactory',
            -parameters => {
                'call_list'             => [ 'compara_dba', 'get_GenomeDBAdaptor', 'fetch_all'],
                'column_names2getters'  => { 'genome_db_id' => 'dbID' },
                'fan_branch_code'       => 2,
            },
            -flow_into => {
                '2->A' => [ 'per_genome_qc' ],
                '1->A' => [ 'overall_qc' ],
                'A->1' => [ 'clusterset_backup' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'overall_qc',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::OverallGroupsetQC',
            -parameters => {
                'reuse_db'                  => $self->o('prev_rel_db'),
                'cluster_dir'               => $self->o('cluster_dir'),
            },
            -hive_capacity  => $self->o('qc_capacity'),
            -failed_job_tolerance => 0,
            -rc_name    => '2Gb_job',
        },

        {   -logic_name => 'per_genome_qc',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::PerGenomeGroupsetQC',
            -parameters => {
                'reuse_db'                  => $self->o('prev_rel_db'),
            },
            -hive_capacity => $self->o('qc_capacity'),
            -failed_job_tolerance => 0,
        },

        {   -logic_name    => 'clusterset_backup',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::SqlCmd',
            -parameters    => {
                'sql'         => 'INSERT INTO protein_tree_backup (member_id, root_id) SELECT member_id, root_id FROM gene_tree_node WHERE member_id IS NOT NULL',
            },
            -analysis_capacity => 1,
            -meadow_type    => 'LOCAL',
        },


# ---------------------------------------------[main tree fan]-------------------------------------------------------------

        {   -logic_name => 'cluster_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'inputquery'        => 'SELECT root_id AS gene_tree_id FROM gene_tree_root JOIN gene_tree_node USING (root_id) WHERE tree_type = "tree" GROUP BY root_id ORDER BY COUNT(*) DESC, root_id ASC',
                'fan_branch_code'   => 2,
            },
            -flow_into  => {
                '2->A' => [ 'msa_chooser' ],
                'A->1' => [ 'hc_factory_global_trees' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'msa_chooser',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::MSAChooser',
            -parameters => {
                'treebreak_gene_count'  => $self->o('treebreak_gene_count'),
                'mafft_gene_count'      => $self->o('mafft_gene_count'),
                'mafft_runtime'         => $self->o('mafft_runtime'),
            },
            -batch_size => 50,
            -hive_capacity => 100,
            -flow_into => {
                '2->A' => [ 'mcoffee' ],
                '3->A' => [ 'mafft' ],
                'A->1' => [ 'split_genes' ],
                '4->B' => [ 'mafft' ],
                'B->5' => [ 'quick_tree_break' ],
            },
        },


# ---------------------------------------------[Pluggable MSA steps]----------------------------------------------------------

        {   -logic_name => 'mcoffee',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::MCoffee',
            -parameters => {
                'method'                => 'cmcoffee',
                'mcoffee_home'          => $self->o('mcoffee_home'),
                'mafft_home'            => $self->o('mafft_home'),
            },
            -hive_capacity        => $self->o('mcoffee_capacity'),
            -rc_name => 'msa',
            -flow_into => {
                1 => [ 'hc_factory_align' ],
               -1 => [ 'mcoffee_himem' ],  # MEMLIMIT
               -2 => [ 'mafft' ],
            },
        },

        {   -logic_name => 'mafft',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::Mafft',
            -parameters => {
                'mafft_home'                 => $self->o('mafft_home'),
            },
            -hive_capacity        => $self->o('mcoffee_capacity'),
            -rc_name => 'msa',
            -flow_into => {
                1 => [ 'hc_factory_align' ],
               -1 => [ 'mafft_himem' ],  # MEMLIMIT
            },
        },

        {   -logic_name => 'mcoffee_himem',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::MCoffee',
            -parameters => {
                'method'                => 'cmcoffee',
                'mcoffee_home'          => $self->o('mcoffee_home'),
                'mafft_home'            => $self->o('mafft_home'),
                'escape_branch'         => -2,
            },
            -hive_capacity        => $self->o('mcoffee_capacity'),
            -rc_name => 'msa_himem',
            -flow_into => {
                1 => [ 'hc_factory_align' ],
               -2 => [ 'mafft_himem' ],
            },
        },

        {   -logic_name => 'mafft_himem',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::Mafft',
            -parameters => {
                'mafft_home'                 => $self->o('mafft_home'),
            },
            -hive_capacity        => $self->o('mcoffee_capacity'),
            -rc_name => 'msa_himem',
            -flow_into => {
                1 => [ 'hc_factory_align' ],
            },
        },

# ---------------------------------------------[main tree creation loop]-------------------------------------------------------------
        {   -logic_name     => 'split_genes',
            -module         => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::FindContiguousSplitGenes',
            -hive_capacity  => $self->o('split_genes_capacity'),
            -rc_name        => '500Mb_job',
            -batch_size     => 20,
            -flow_into      => [ 'njtree_phyml', 'build_HMM_aa', 'build_HMM_cds' ],
        },

        {   -logic_name => 'njtree_phyml',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::NJTREE_PHYML',
            -parameters => {
                'cdna'                      => 1,
                'bootstrap'                 => 1,
                'store_intermediate_trees'  => 1,
                'store_filtered_align'      => 1,
                'use_genomedb_id'           => $self->o('use_genomedb_id'),
                'treebest_exe'              => $self->o('treebest_exe'),
            },
            -hive_capacity        => $self->o('njtree_phyml_capacity'),
            -rc_name => '4Gb_job',
            -flow_into => {
                '1->A' => {
                    'hc_factory_align' => {'gene_tree_id' => '#gene_tree_id#', 'post_treebest' => 1},
                    'hc_factory_trees' => undef,
                },
                'A->1' => [ 'ortho_tree' ],
                 1     => [ 'ktreedist' ],
                '2->B' => [ 'hc_factory_trees' ],
                'B->2' => [ 'ortho_tree_annot' ],
            }
        },

        {   -logic_name => 'ortho_tree',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::OrthoTree',
            -parameters => {
                'use_genomedb_id'   => $self->o('use_genomedb_id'),
                'tag_split_genes'   => 1,
            },
            -hive_capacity      => $self->o('ortho_tree_capacity'),
            -rc_name => '250Mb_job',
            -flow_into  => [ 'hc_factory_tree_attributes', 'hc_factory_homologies' ],
        },

        {   -logic_name    => 'ktreedist',
            -module        => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::Ktreedist',
            -parameters    => {
                               'treebest_exe'  => $self->o('treebest_exe'),
                               'ktreedist_exe' => $self->o('ktreedist_exe'),
                              },
            -hive_capacity => $self->o('ktreedist_capacity'),
            -rc_name       => '2Gb_job',
        },

        {   -logic_name => 'ortho_tree_annot',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::OrthoTree',
            -parameters => {
                'use_genomedb_id'   => $self->o('use_genomedb_id'),
                'tag_split_genes'   => 1,
                'store_homologies'  => 0,
            },
            -hive_capacity        => $self->o('ortho_tree_annot_capacity'),
            -rc_name => '250Mb_job',
            -flow_into  => [ 'hc_factory_tree_attributes' ],
        },

        {   -logic_name => 'build_HMM_aa',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::BuildHMM',
            -parameters => {
                'buildhmm_exe'      => $self->o('buildhmm_exe'),
                'sreformat_exe'     => $self->o('sreformat_exe'),
            },
            -hive_capacity        => $self->o('build_hmm_capacity'),
            -batch_size           => 10,
            -priority             => -10,
            -rc_name => '500Mb_job',
        },

        {   -logic_name => 'build_HMM_cds',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::BuildHMM',
            -parameters => {
                'cdna'              => 1,
                'buildhmm_exe'      => $self->o('buildhmm_exe'),
                'sreformat_exe'     => $self->o('sreformat_exe'),
            },
            -hive_capacity        => $self->o('build_hmm_capacity'),
            -batch_size           => 10,
            -priority             => -10,
            -rc_name => '1Gb_job',
        },

# ---------------------------------------------[Quick tree break steps]-----------------------------------------------------------------------

        {   -logic_name => 'quick_tree_break',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::QuickTreeBreak',
            -parameters => {
                'quicktree_exe'     => $self->o('quicktree_exe'),
                'sreformat_exe'     => $self->o('sreformat_exe'),
                'treebreak_gene_count'  => $self->o('treebreak_gene_count'),
            },
            -hive_capacity        => $self->o('quick_tree_break_capacity'),
            -rc_name   => '1Gb_job',
            -flow_into => [ 'other_paralogs' ],
        },

        {   -logic_name     => 'other_paralogs',
            -module         => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::OtherParalogs',
            -parameters     => {
                'use_genomedb_id'   => $self->o('use_genomedb_id'),
                'dataflow_subclusters' => 1,
            },
            -hive_capacity  => $self->o('other_paralogs_capacity'),
            -rc_name        => '250Mb_job',
            -flow_into => {
                '2->A' => [ 'tree_backup' ],
                'A->2' => [ 'split_genes' ],
            },
        },

        {   -logic_name    => 'tree_backup',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::SqlCmd',
            -parameters    => {
                'sql'         => 'INSERT INTO protein_tree_backup (member_id, root_id) SELECT member_id, root_id FROM gene_tree_node WHERE member_id IS NOT NULL AND root_id = #gene_tree_id#',
            },
            -analysis_capacity => 1,
            -meadow_type    => 'LOCAL',
            -flow_into      => [ 'mafft' ],
        },



# -------------------------------------------[name mapping step]---------------------------------------------------------------------

        {   -logic_name => 'fire_enabled_mappings',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -flow_into  => [
                $self->o('do_stable_id_mapping') ? 'stable_id_mapping' : (),
                $self->o('do_treefam_xref') ? 'treefam_xref_idmap' : (),
            ],
        },

        {
            -logic_name => 'stable_id_mapping',
            -module => 'Bio::EnsEMBL::Compara::RunnableDB::StableIdMapper',
            -parameters => {
                'master_db'     => $self->o('master_db'),
                'prev_rel_db'   => $self->o('prev_rel_db'),
                'release'       => $self->o('release'),
                'prev_release'  => $self->o('prev_release'),
                'type'          => 't',
            },
            -rc_name => '1Gb_job',
        },

        {   -logic_name    => 'treefam_xref_idmap',
            -module        => 'Bio::EnsEMBL::Compara::RunnableDB::TreefamXrefMapper',
            -parameters    => {
                'release'     => $self->o('release'),
                'tf_release'  => 9,
                'tag_prefix'  => '',
            },
            -rc_name => '1Gb_job',
        },

# ---------------------------------------------[homology step]-----------------------------------------------------------------------

        {   -logic_name => 'group_genomes_under_taxa',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::GroupGenomesUnderTaxa',
            -parameters => {
                'taxlevels'             => $self->o('taxlevels'),
                'filter_high_coverage'  => $self->o('filter_high_coverage'),
            },
            -flow_into => {
                2 => [ 'mlss_factory' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'mlss_factory',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::MLSSIDFactory',
            -parameters => {
                'method_link_types'  => ['ENSEMBL_ORTHOLOGUES', 'ENSEMBL_PARALOGUES'],
            },
            -flow_into => {
                2 => [ 'homology_factory' ],
            },
            -meadow_type    => 'LOCAL',
        },

        {   -logic_name => 'homology_factory',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::HomologyGroupingFactory',
            -hive_capacity => $self->o('homology_dNdS_capacity'),
            -flow_into => {
                'A->1' => [ 'threshold_on_dS' ],
                '2->A' => [ 'homology_dNdS' ],
            },
        },

        {   -logic_name => 'homology_dNdS',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::Homology_dNdS',
            -parameters => {
                'codeml_parameters_file'    => $self->o('codeml_parameters_file'),
                'codeml_exe'                => $self->o('codeml_exe'),
            },
            -hive_capacity        => $self->o('homology_dNdS_capacity'),
            -failed_job_tolerance => 2,
            -rc_name => '500Mb_job',
        },

        {   -logic_name => 'threshold_on_dS',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::Threshold_on_dS',
            -hive_capacity => $self->o('homology_dNdS_capacity'),
        },


# --------------------------------------------- [health-checks] -----------------------------------------------------------------------

        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_members_per_genome($self)},
        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_members_globally($self)},
        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_pafs($self)},
        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_alignment($self)},
        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_tree_structure($self)},
        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_tree_attr($self)},
        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_homologies($self)},
        @{Bio::EnsEMBL::Compara::PipeConfig::GeneTreeHealthChecks_conf::analysis_tree_globally($self)},

    ];
}

1;

