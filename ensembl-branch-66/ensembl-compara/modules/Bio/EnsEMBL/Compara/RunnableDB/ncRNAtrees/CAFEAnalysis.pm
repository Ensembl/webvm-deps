=head1 LICENSE

  Copyright (c) 1999-2012 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

    http://www.ensembl.org/info/about/code_licence.html

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=cut

=head1 NAME

Bio::EnsEMBL::Compara::RunnableDB::ncRNAtrees::CAFEAnalysis

=head1 SYNOPSIS

=head1 DESCRIPTION

This RunnableDB calculates the dynamics of a ncRNA family (based on the tree obtained and the CAFE software) in terms of gains losses per branch tree. It needs a CAFE-compliant species tree.

=head1 INHERITANCE TREE

Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with an underscore (_)

=cut

package Bio::EnsEMBL::Compara::RunnableDB::ncRNAtrees::CAFEAnalysis;

use strict;
use Data::Dumper;

use Bio::EnsEMBL::Compara::CAFETreeNode;
use Bio::EnsEMBL::Compara::Graph::NewickParser;

use base ('Bio::EnsEMBL::Compara::RunnableDB::BaseRunnable');

sub param_defaults {
    return {
            'pvalue_lim' => 0.05,
           };
}

=head2 fetch_input

    Title     : fetch_input
    Usage     : $self->fetch_input
    Function  : Fetches input data from database
    Returns   : none
    Args      : none

=cut

sub fetch_input {
    my ($self) = @_;

    unless ( $self->param('cafe_tree_string') ) {
        die ('cafe_species_tree can not be found');
    }

    unless ( $self->param('cafe_table_file') ) {
        die ('cafe_table_file must be set');
    }

    unless ( $self->param('mlss_id') ) {
        die ('mlss_id must be set')
    }

#    my $nctree_Adaptor = $self->compara_dba->get_NCTreeAdaptor;
#    $self->param('nctree_Adaptor', $nctree_Adaptor);

    my $cafetree_Adaptor = $self->compara_dba->get_CAFETreeAdaptor;
    $self->param('cafeTree_Adaptor', $cafetree_Adaptor);

    my $genomeDB_Adaptor = $self->compara_dba->get_GenomeDBAdaptor;
    $self->param('genomeDB_Adaptor', $genomeDB_Adaptor);

    # cafe_shell, mlss_id, cafe_lambdas and cafe_struct_tree_str are also defined parameters

    return;
}

sub run {
    my ($self) = @_;
    $self->run_cafe_script;
    $self->parse_cafe_output;
}

sub write_output {
    my ($self) = @_;
#    $self->store_expansion_contraction();
#    $self->store_cafe_tree();

    my $lambda = $self->param('lambda');
    $self->dataflow_output_id ( {
                                 'cafe_lambda' => $self->param('lambda'),
                                 'cafe_table_file' => $self->param('work_dir') . "/" . $self->param('cafe_table_file'),
                                 'cafe_tree_string' => $self->param('cafe_tree_string'),
                                }, 3);

}

###########################################
## Internal methods #######################
###########################################

sub run_cafe_script {
    my ($self) = @_;

    my $mlss_id = $self->param('mlss_id');
    my $pval_lim = $self->param('pvalue_lim');
    my $cafe_out_file = $self->worker_temp_directory() . "cafe_${mlss_id}.out";
    print STDERR "CAFE results will be written into [$cafe_out_file]\n";
    my $script_file = $self->worker_temp_directory() . "cafe_${mlss_id}.sh";
    open my $sf, ">", $script_file or die $!;
    print STDERR "Script file is [$script_file]\n" if ($self->debug());

    my $cafe_shell = $self->param('cafe_shell');
    my $cafe_tree_str = $self->param('cafe_tree_string');
    chop($cafe_tree_str); #remove final semicolon
    $cafe_tree_str =~ s/:\d+$//; # remove last branch length

    my $cafe_table_file = $self->param('work_dir') . "/" . $self->param('cafe_table_file');
    my $cafe_lambdas = $self->param('cafe_lambdas');
    my $cafe_struct_tree = $self->param('cafe_struct_tree_str');

    print $sf '#!' . $cafe_shell . "\n\n";
    print $sf "tree $cafe_tree_str\n\n";
    print $sf "load -p ${pval_lim} -i $cafe_table_file\n\n";
    print $sf "lambda ";
    print $sf $cafe_lambdas ? "-l $cafe_lambdas -t $cafe_struct_tree\n\n" : " -s\n\n";
    print $sf "report $cafe_out_file\n\n";
    close ($sf);

    print STDERR "CAFE output in [$cafe_out_file]\n" if ($self->debug());

    $self->param('cafe_out_file', $cafe_out_file);

    chmod 0755, $script_file;

    $self->compara_dba->dbc->disconnect_when_inactive(0);
    unless ((my $err = system($script_file)) == 4096) {
        print STDERR "CAFE returning error $err\n";
#         for my $f (glob "$cafe_out_file*") {
#             system(`head $f >> /lustre/scratch101/ensembl/mp12/kkkk`);
#         }
        # It seems that CAFE doesn't exit with error code 0 never (usually 4096?)
#        $self->throw("problem running script $cafe_out_file: $err\n");
    }
    $self->compara_dba->dbc->disconnect_when_inactive(1);
    return;
}

sub parse_cafe_output {
    my ($self) = @_;
    my $fmt = '%{-n}%{":"o}';

    my $cafeTree_Adaptor = $self->param('cafeTree_Adaptor');
    my $mlss_id = $self->param('mlss_id');
    my $pvalue_lim = $self->param('pvalue_lim');
    my $cafe_out_file = $self->param('cafe_out_file') . ".cafe";
    my $genomeDB_Adaptor = $self->param('genomeDB_Adaptor');

    print STDERR "CAFE OUT FILE [$cafe_out_file]\n" if ($self->debug);

    open my $fh, "<". $cafe_out_file or die $!;

    my $tree_line = <$fh>;
    my $tree_str = substr($tree_line, 5, length($tree_line) - 6);
    $tree_str .= ";";
    my $tree = Bio::EnsEMBL::Compara::Graph::NewickParser::parse_newick_into_tree($tree_str, "Bio::EnsEMBL::Compara::CAFETreeNode");
    print STDERR "CAFE TREE: $tree_str\n" if ($self->debug);

    my $lambda_line = <$fh>;
    my $lambda = substr($lambda_line, 8, length($lambda_line) - 9);
    print STDERR "CAFE LAMBDAS: $lambda\n" if ($self->debug);

    my $ids_line = <$fh>;
    my $ids_tree_str = substr($ids_line, 15, length($ids_line) - 16);
    $ids_tree_str =~ s/<(\d+)>/:$1/g;
    $ids_tree_str .= ";";
    print STDERR "CAFE IDsTREE: $ids_tree_str\n" if ($self->debug);

    my $idsTree = Bio::EnsEMBL::Compara::Graph::NewickParser::parse_newick_into_tree($ids_tree_str);
    print STDERR $idsTree->newick_format('ryo', '%{-n}%{":"d}'), "\n" if ($self->debug);

    my %cafeIDs2nodeIDs = ();
    for my $node (@{$idsTree->get_all_nodes()}) {
        $cafeIDs2nodeIDs{$node->distance_to_parent()} = $node->node_id;
    }

    my $format_ids_line = <$fh>;
    my ($formats_ids) = (split /:/, $format_ids_line)[2];
    $formats_ids =~ s/^\s+//;
    $formats_ids =~ s/\s+$//;
    my @format_pairs_cafeIDs = split /\s+/, $formats_ids;
    my @format_pairs_nodeIDs = map {my ($fst,$snd) = $_ =~ /\((\d+),(\d+)\)/; [($cafeIDs2nodeIDs{$fst}, $cafeIDs2nodeIDs{$snd})]} @format_pairs_cafeIDs;


# Store the tree
    $tree->method_link_species_set_id($mlss_id);
    $tree->species_tree($ids_tree_str);
    $tree->lambdas($lambda);

    $cafeTree_Adaptor->store($tree);

    while (<$fh>) {
        last if $. == 10; # We skip several lines and go directly to the family information.
# Is it always 10??
    }

    while (my $fam_line = <$fh>) {
        my @flds = split/\s+/, $fam_line;
        my $fam_id = $flds[0];
        my $fam_tree_str = $flds[1];
        my $avg_pvalue = $flds[2];
        my $pvalue_pairs = $flds[3];

        #print "FAM_PVALUE:$avg_pvalue VS PVALUE_LIM:$pvalue_lim\n";

        next if ($avg_pvalue >= $pvalue_lim);
        print STDERR "FAM_ID:$fam_id\n";

        my $fam_tree = Bio::EnsEMBL::Compara::Graph::NewickParser::parse_newick_into_tree($fam_tree_str . ";");

        my %info_by_nodes;
        for my $node (@{$fam_tree->get_all_nodes()}) {
            my $name = $node->name();
            my ($n_members) = $name =~ /_(\d+)/;
            $name =~ s/_\d+//;
            $name =~ s/\./_/g;
            $info_by_nodes{$name}{'gene_tree_root_id'} = $fam_id;
            $info_by_nodes{$name}{'n_members'} = $n_members;

            my $taxon_id;
            if (! $node->is_leaf()) {
                $taxon_id = $name;
            } else {
                my $genomeDB = $genomeDB_Adaptor->_fetch_by_name($name);
                $taxon_id = $genomeDB->taxon_id();
            }

            $info_by_nodes{$name}{'taxon_id'} = $taxon_id;
        }

        $pvalue_pairs =~ tr/(/[/;
        $pvalue_pairs =~ tr/)/]/;
        $pvalue_pairs = eval $pvalue_pairs;

        die "Problem processing the $pvalue_pairs\n" if (ref $pvalue_pairs ne "ARRAY");

        for (my $i=0; $i<scalar(@$pvalue_pairs); $i++) {
            my ($val_fst, $val_snd) = @{$pvalue_pairs->[$i]};
            my ($id_fst, $id_snd) = @{$format_pairs_nodeIDs[$i]};
            my $name1 = $idsTree->find_node_by_node_id($id_fst)->name();
            my $name2 = $idsTree->find_node_by_node_id($id_snd)->name();
            $name1 =~ s/\./_/g;
            $name2 =~ s/\./_/g;

            $info_by_nodes{$name1}{'p_value'} = $val_fst;
            $info_by_nodes{$name2}{'p_value'} = $val_snd;

        }

        $tree->print_tree(0.2) if ($self->debug());

        # We store the attributes
#        $tree->store_tag("p_value", $avg_pvalue);
        for my $node (@{$tree->get_all_nodes()}) {
            my $n = $node->name();
            $n =~ s/\./_/g;

            my $fam_id = $info_by_nodes{$n}{gene_tree_root_id};
#            $node->store_tag("gene_tree_root_id", $fam_id);

            my $taxon_id = $info_by_nodes{$n}{taxon_id};
#            $node->store_tag("taxon_id", $taxon_id);

            my $n_members = $info_by_nodes{$n}{n_members};
#            $node->store_tag("n_members", $n_members);

            my $p_value = $info_by_nodes{$n}{p_value};
#            $node->store_tag("p_value", $p_value);
            $cafeTree_Adaptor->store_tagvalues($node, $fam_id, $taxon_id, $n_members, $p_value, $avg_pvalue);
        }
#         print STDERR "INFO BY NODES:\n";
#         print STDERR Dumper \%info_by_nodes;
#         print STDERR Dumper \%info_by_nodes if ($self->debug);

    }
    return
}

# sub store_cafe_tree {
#     my ($self) = @_;

#     my $cafe_tree = new Bio::EnsEMBL::Compara::CAFETreeNode;
# }

# Not used anymore for now
# sub store_expansion_contraction {
#     my ($self) = @_;
#     my $cafe_out_file = $self->param('cafe_out_file');
#     my $nctree_Adaptor = $self->param('nctree_Adaptor');

#     open my $fh, "<", $cafe_out_file.".cafe" or die $!;
# #     my $tree_line = <$fh>;
# #     my $lambda_line = <$fh>;
# #     my $ids_line = <$fh>;

# ## WARNI1NG: if the lambda tree is provided, 1 more line in the output file will be present.

#     while (my $fam_line = <$fh>) {
#         if ($fam_line =~ /^Lambda:\s(\d+\.\d+)/) {
#             $self->param('lambda', $1);
#             next;
#         }
#         next unless $fam_line =~ /^\d+/;
#         chomp $fam_line;
#         my @flds = split /\s+/, $fam_line;
#         my ($node_id, $avg_expansion) = @flds[0,2];
#         my $nc_tree = $nctree_Adaptor->fetch_node_by_node_id($node_id);
#         $nc_tree->store_tag('average_expansion', $avg_expansion);
#     }

#     return;
# }

1;
