# $Id: ComparaTree.pm,v 1.62 2012-03-15 12:15:10 sb23 Exp $

package EnsEMBL::Web::Component::Gene::ComparaTree;

use strict;

use Bio::AlignIO;
use IO::Scalar;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::Component::Gene);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
  $self->has_image(1);
}

sub get_details {
  my $self   = shift;
  my $cdb    = shift;
  my $object = $self->object;
  my $member = $object->get_compara_Member($cdb);

  return (undef, '<strong>Gene is not in the compara database</strong>') unless $member;

  my $tree = $object->get_GeneTree($cdb);
  return (undef, '<strong>Gene is not in a compara tree</strong>') unless $tree;

  my $node = $tree->get_leaf_by_Member($member);
  return (undef, '<strong>Gene is not in the compara tree</strong>') unless $node;

  return ($member, $tree, $node);
}

sub content {
  my $self        = shift;
  my $cdb         = shift || 'compara';
  my $hub         = $self->hub;
  my $object      = $self->object;
  my $is_genetree = $object->isa('EnsEMBL::Web::Object::GeneTree') ? 1 : 0;
  my ($gene, $member, $tree, $node);
  
  if ($is_genetree) {
    $tree   = $object->Obj;
    $member = undef;
  } else {
    $gene = $object;
    ($member, $tree, $node) = $self->get_details($cdb);
  }

  return $tree . $self->genomic_alignment_links($cdb) if $hub->param('g') && !$is_genetree && !defined $member;

  my $leaves               = $tree->get_all_leaves;
  my $tree_stable_id       = $tree->tree->stable_id;
  my $highlight_gene       = $hub->param('g1');
  my $highlight_ancestor   = $hub->param('anc');
  my $unhighlight          = $highlight_gene ? $hub->url({ g1 => undef, collapse => $hub->param('collapse') }) : '';
  my $image_width          = $self->image_width       || 800;
  my $colouring            = $hub->param('colouring') || 'background';
  my $collapsability       = $is_genetree ? '' : $hub->param('collapsability');
  my $show_exons           = $hub->param('exons') eq 'on' ? 1 : 0;
  my $image_config         = $hub->get_imageconfig('genetreeview');
  my @hidden_clades        = grep { $_ =~ /^group_/ && $hub->param($_) eq 'hide'     } $hub->param;
  my @collapsed_clades     = grep { $_ =~ /^group_/ && $hub->param($_) eq 'collapse' } $hub->param;
  my @highlights           = $gene && $member ? ($gene->stable_id, $member->genome_db->dbID) : (undef, undef);
  my $hidden_genes_counter = 0;
  my $link                 = $hub->type eq 'GeneTree' ? '' : sprintf ' <a href="%s">%s</a>', $hub->url({ species => 'Multi', type => 'GeneTree', action => undef, gt => $tree_stable_id, __clear => 1 }), $tree_stable_id;
  my ($hidden_genome_db_ids, $highlight_species, $highlight_genome_db_id);
  
  my $html = sprintf('
    <h3>GeneTree%s</h3>
      <dl class="summary">
        <dt style="width:15em">Number of genes</dt>
        <dd>%s</dd>
      </dl>
      <dl class="summary">
        <dt style="width:15em">Number of speciation nodes</dt>
        <dd>%s</dd>
      </dl>
      <dl class="summary">
        <dt style="width:15em">Number of duplication nodes</dt>
        <dd>%s</dd>
      </dl>
      <dl class="summary">
        <dt style="width:15em">Number of ambiguous nodes</dt>
        <dd>%s</dd>
      </dl>
      <dl class="summary">
        <dt style="width:15em">Number of gene split events</dt>
        <dd>%s</dd>
      </dl>
      <p>&nbsp;</p>
    ',
    $link,
    scalar(@$leaves),
    $self->get_num_nodes_with_tag($tree, 'node_type', 'speciation'),
    $self->get_num_nodes_with_tag($tree, 'node_type', 'duplication'),
    $self->get_num_nodes_with_tag($tree, 'node_type', 'dubious'),
    $self->get_num_nodes_with_tag($tree, 'node_type', 'gene_split'),
  );

  if ($highlight_gene) {
    my $highlight_gene_display_label;
    
    foreach my $this_leaf (@$leaves) {
      if ($highlight_gene && $this_leaf->gene_member->stable_id eq $highlight_gene) {
        $highlight_gene_display_label = $this_leaf->gene_member->display_label || $highlight_gene;
        $highlight_species            = $this_leaf->gene_member->genome_db->name;
        $highlight_genome_db_id       = $this_leaf->gene_member->genome_db_id;
        last;
      }
    }

    if ($member && $gene && $highlight_species) {
      $html .= $self->_info('Highlighted genes',
        sprintf(
          'In addition to all <I>%s</I> genes, the %s gene (<I>%s</I>) and its paralogues have been highlighted. <a href="%s">Click here to switch off highlighting</a>.', 
          $member->genome_db->name, $highlight_gene_display_label, $highlight_species, $unhighlight
        )
      );
    } else {
      $html .= $self->_warning('WARNING', "$highlight_gene gene is not in this Gene Tree");
      $highlight_gene = undef;
    }
  }
  
  if (@hidden_clades) {
    $hidden_genome_db_ids = '_';
    
    foreach my $clade (@hidden_clades) {
      my ($clade_name) = $clade =~ /group_([\w\-]+)_display/;
      $hidden_genome_db_ids .= $hub->param("group_${clade_name}_genome_db_ids") . '_';
    }
    
    foreach my $this_leaf (@$leaves) {
      my $genome_db_id = $this_leaf->genome_db_id;
      
      next if $highlight_genome_db_id && $genome_db_id eq $highlight_genome_db_id;
      next if $highlight_gene && $this_leaf->gene_member->stable_id eq $highlight_gene;
      next if $member && $genome_db_id == $member->genome_db_id;
      
      if ($hidden_genome_db_ids =~ /_${genome_db_id}_/) {
        $hidden_genes_counter++;
        $this_leaf->disavow_parent;
        $tree = $tree->minimize_tree;
      }
    }

    $html .= $self->_info('Hidden genes', "There are $hidden_genes_counter hidden genes in the tree. Use the 'configure page' link in the left panel to change the options.") if $hidden_genes_counter;
  }

  $image_config->set_parameters({
    container_width => $image_width,
    image_width     => $image_width,
    slice_number    => '1|1',
    cdb             => $cdb
  });
  
  # Keep track of collapsed nodes
  my $collapsed_nodes = $hub->param('collapse');
  my ($collapsed_to_gene, $collapsed_to_para);
  
  if (!$is_genetree) {
    $collapsed_to_gene = $self->collapsed_nodes($tree, $node, 'gene',     $highlight_genome_db_id, $highlight_gene);
    $collapsed_to_para = $self->collapsed_nodes($tree, $node, 'paralogs', $highlight_genome_db_id, $highlight_gene);
  }
  
  my $collapsed_to_dups = $self->collapsed_nodes($tree, undef, 'duplications', $highlight_genome_db_id, $highlight_gene);

  if (!defined $collapsed_nodes) { # Examine collapsabilty
    $collapsed_nodes = $collapsed_to_gene if $collapsability eq 'gene';
    $collapsed_nodes = $collapsed_to_para if $collapsability eq 'paralogs';
    $collapsed_nodes = $collapsed_to_dups if $collapsability eq 'duplications';
    $collapsed_nodes ||= '';
  }

  if (@collapsed_clades) {
    foreach my $clade (@collapsed_clades) {
      my ($clade_name) = $clade =~ /group_([\w\-]+)_display/;
      my $extra_collapsed_nodes = $self->find_nodes_by_genome_db_ids($tree, [ split '_', $hub->param("group_${clade_name}_genome_db_ids") ], 'internal');
      
      if (%$extra_collapsed_nodes) {
        $collapsed_nodes .= ',' if $collapsed_nodes;
        $collapsed_nodes .= join ',', keys %$extra_collapsed_nodes;
      }
    }
  }

  my $coloured_nodes;
  
  if ($colouring =~ /^(back|fore)ground$/) {
    my $mode   = $1 eq 'back' ? 'bg' : 'fg';
    my @clades = grep { $_ =~ /^group_.+_${mode}colour/ } $hub->param;

    # Get all the genome_db_ids in each clade
    my $genome_db_ids_by_clade;
    
    foreach my $clade (@clades) {
      my ($clade_name) = $clade =~ /group_(.+)_${mode}colour/;
      $genome_db_ids_by_clade->{$clade_name} = [ split '_', $hub->param("group_${clade_name}_genome_db_ids") ];
    }

    # Sort the clades by the number of genome_db_ids. First the largest clades,
    # so they can be overwritten later (see ensembl-draw/modules/Bio/EnsEMBL/GlyphSet/genetree.pm)
    foreach my $clade_name (sort { scalar @{$genome_db_ids_by_clade->{$b}} <=> scalar @{$genome_db_ids_by_clade->{$a}} } keys %$genome_db_ids_by_clade) {
      my $genome_db_ids = $genome_db_ids_by_clade->{$clade_name};
      my $colour        = $hub->param("group_${clade_name}_${mode}colour") || 'magenta';
      my $nodes         = $self->find_nodes_by_genome_db_ids($tree, $genome_db_ids, $mode eq 'fg' ? 'all' : undef);
      
      push @$coloured_nodes, { clade => $clade_name,  colour => $colour, mode => $mode, node_ids => [ keys %$nodes ] } if %$nodes;
    }
  }
  
  push @highlights, $collapsed_nodes        || undef;
  push @highlights, $coloured_nodes         || undef;
  push @highlights, $highlight_genome_db_id || undef;
  push @highlights, $highlight_gene         || undef;
  push @highlights, $highlight_ancestor     || undef;
  push @highlights, $show_exons;

  my $image = $self->new_image($tree, $image_config, \@highlights);
  
  return $html if $self->_export_image($image, 'no_text');

  my $image_id = $gene ? $gene->stable_id : $tree_stable_id;
  my $li_tmpl  = '<li><a href="%s">%s</a></li>';
  my @view_links;
  
  $image->image_type       = 'genetree';
  $image->image_name       = ($hub->param('image_width')) . "-$image_id";
  $image->imagemap         = 'yes';
  $image->{'panel_number'} = 'tree';
  $image->set_button('drag', 'title' => 'Drag to select region');
  
  if ($gene) {
    push @view_links, sprintf $li_tmpl, $hub->url({ collapse => $collapsed_to_gene, g1 => $highlight_gene }), $highlight_gene ? 'View current genes only'        : 'View current gene only';
    push @view_links, sprintf $li_tmpl, $hub->url({ collapse => $collapsed_to_para, g1 => $highlight_gene }), $highlight_gene ? 'View paralogs of current genes' : 'View paralogs of current gene';
  }
  
  push @view_links, sprintf $li_tmpl, $hub->url({ collapse => $collapsed_to_dups, g1 => $highlight_gene }), 'View all duplication nodes';
  push @view_links, sprintf $li_tmpl, $hub->url({ collapse => 'none', g1 => $highlight_gene }), 'View fully expanded tree';
  push @view_links, sprintf $li_tmpl, $unhighlight, 'Switch off highlighting' if $highlight_gene;

  $html .= $image->render;
  $html .= sprintf(qq{
    <div style="margin-top:1em"><b>View options:</b><br/>
    <small><ul>%s</ul></small>
    Use the 'configure page' link in the left panel to set the default. Further options are available from menus on individual tree nodes.</div>
  }, join '', @view_links);
  
  return $html;
}

sub collapsed_nodes {
  # Takes the ProteinTree and node related to this gene and a view action
  # ('gene', 'paralogs', 'duplications' ) and returns the list of
  # tree nodes that should be collapsed according to the view action.
  # TODO: Move to Object::Gene, as the code is shared by the ajax menus
  my $self                   = shift;
  my $tree                   = shift;
  my $node                   = shift;
  my $action                 = shift;
  my $highlight_genome_db_id = shift;
  my $highlight_gene         = shift;
  
  die "Need a GeneTreeNode, not a $tree" unless $tree->isa('Bio::EnsEMBL::Compara::GeneTreeNode');
  die "Need an GeneTreeMember, not a $node" if $node && !$node->isa('Bio::EnsEMBL::Compara::GeneTreeMember');

  my %collapsed_nodes;
  my %expanded_nodes;
  
  # View current gene
  if ($action eq 'gene') {
    $collapsed_nodes{$_->node_id} = $_ for @{$node->get_all_adjacent_subtrees};
    
    if ($highlight_gene) {
      $expanded_nodes{$_->node_id} = $_ for @{$node->get_all_ancestors};
      
      foreach my $leaf (@{$tree->get_all_leaves}) {
        $collapsed_nodes{$_->node_id} = $_ for @{$leaf->get_all_adjacent_subtrees};
        
        if ($leaf->gene_member->stable_id eq $highlight_gene) {
          $expanded_nodes{$_->node_id} = $_ for @{$leaf->get_all_ancestors};
          last;
        }
      }
    }
  } elsif ($action eq 'paralogs') { # View all paralogs
    my $gdb_id = $node->genome_db_id;
    
    foreach my $leaf (@{$tree->get_all_leaves}) {
      if ($leaf->genome_db_id == $gdb_id || ($highlight_genome_db_id && $leaf->genome_db_id == $highlight_genome_db_id)) {
        $expanded_nodes{$_->node_id}  = $_ for @{$leaf->get_all_ancestors};
        $collapsed_nodes{$_->node_id} = $_ for @{$leaf->get_all_adjacent_subtrees};
      }
    }
  } elsif ($action eq 'duplications') { # View all duplications
    foreach my $tnode(@{$tree->get_all_nodes}) {
      next if $tnode->is_leaf;
      
      if ($tnode->get_tagvalue('node_type', '') ne 'duplication') {
        $collapsed_nodes{$tnode->node_id} = $tnode;
        next;
      }
      
      $expanded_nodes{$tnode->node_id} = $tnode;
      $expanded_nodes{$_->node_id}     = $_ for @{$tnode->get_all_ancestors};
    }
  }
  
  return join ',', grep !$expanded_nodes{$_}, keys %collapsed_nodes;
}

sub get_num_nodes_with_tag {
  my ($self, $tree, $tag, $test_value, $exclusion_tag_array) = @_;
  my $count = 0;

  OUTER: foreach my $tnode(@{$tree->get_all_nodes}) {
    my $tag_value = $tnode->get_tagvalue($tag);
    #Accept if the test value was not defined but got a value from the node
    #or if we had a tag value and it was equal to the test
    if( (! $test_value && $tag_value) || ($test_value && $tag_value eq $test_value) ) {
      
      #If we had an exclusion array then check & skip if it found anything
      if($exclusion_tag_array) {
        foreach my $exclusion (@{$exclusion_tag_array}) {
          my $exclusion_value = $tnode->get_tagvalue($exclusion);
          if($exclusion_value) {
            next OUTER;
          }
        }
      }
      $count++;
    }
  }

  return $count;
}

sub find_nodes_by_genome_db_ids {
  my ($self, $tree, $genome_db_ids, $mode) = @_;
  my $node_ids = {};

  if ($tree->is_leaf) {
    my $genome_db_id = $tree->genome_db_id;
    
    if (grep $_ eq $genome_db_id, @$genome_db_ids) {
      $node_ids->{$tree->node_id} = 1;
    }
  } else {
    my $tag = 1;
    
    foreach my $this_child (@{$tree->children}) {
      my $these_node_ids = $self->find_nodes_by_genome_db_ids($this_child, $genome_db_ids, $mode);
      
      foreach my $node_id (keys %$these_node_ids) {
        $node_ids->{$node_id} = 1;
      }
      
      $tag = 0 unless $node_ids->{$this_child->node_id};
    }
    
    if ($mode eq 'internal') {
      foreach my $this_child (@{$tree->children}) {
        delete $node_ids->{$this_child->node_id} if $this_child->is_leaf;
      }
    }
    
    if ($tag) {
      if ($mode ne 'all') {
        foreach my $this_child (@{$tree->children}) {
          delete $node_ids->{$this_child->node_id};
        }
      }
      
      $node_ids->{$tree->node_id} = 1;
    }
  }
  
  return $node_ids;
}

sub content_align {
  my $self = shift;
  my $cdb  = shift || 'compara';
  my $hub  = $self->hub;
  
  # Get the ProteinTree object
  my ($member, $tree, $node) = $self->get_details($cdb);
  
  return $tree . $self->genomic_alignment_links($cdb) unless defined $member;
  
  # Determine the format
  my %formats = EnsEMBL::Web::Constants::ALIGNMENT_FORMATS;
  my $mode    = $hub->param('text_format');
  $mode       = 'fasta' unless $formats{$mode};

  my $formatted; # Variable to hold the formatted alignment string
  my $fh  = new IO::Scalar(\$formatted);
  my $aio = new Bio::AlignIO( -format => $mode, -fh => $fh );
  
  $aio->write_aln($tree->get_SimpleAlign);

  return $self->format eq 'Text' ? $formatted : sprintf(q{
    <p>Multiple sequence alignment in "<i>%s</i>" format:</p>
    <p>The sequence alignment format can be configured using the
    'configure page' link in the left panel.<p>
    <pre>%s</pre>
  }, $formats{$mode} || $mode, $formatted);
}

sub content_text {
  my $self = shift;
  my $cdb  = shift || 'compara';
  my $hub  = $self->hub;

  # Get the ProteinTree object
  my ($member, $tree, $node) = $self->get_details($cdb);
  
  return $tree . $self->genomic_alignment_links($cdb) unless defined $member;

  # Return the text representation of the tree
  my %formats = EnsEMBL::Web::Constants::TREE_FORMATS;
  my $mode    = $hub->param('tree_format');
  $mode       = 'newick' unless $formats{$mode};
  my $fn      = $formats{$mode}{'method'};
  my @params  = map $hub->param($_), @{$formats{$mode}{'parameters'} || []};
  my $string  = $tree->$fn(@params);
  
  if ($formats{$mode}{'split'} && $self->format ne 'Text') {
    my $reg = '([' . quotemeta($formats{$mode}{'split'}) . '])';
    $string =~ s/$reg/$1\n/g;
  }

  return $self->format eq 'Text' ? $string : sprintf(q{
    <p>The following is a representation of the tree in "<i>%s</i>" format</p>
    <p>The tree representation can be configured using the
    'configure page' link in the left panel.<p>
    <pre>%s</pre>
  }, $formats{$mode}{'caption'} || $mode, $string);
}

sub genomic_alignment_links {
  my $self          = shift;
  my $hub           = $self->hub;
  my $cdb           = shift || $hub->param('cdb') || 'compara';
  (my $ckey = $cdb) =~ s/compara//;
  my $species_defs  = $hub->species_defs;
  my $alignments    = $species_defs->multi_hash->{$ckey}{'ALIGNMENTS'}||{};
  my $species       = $hub->species;
  my $url           = $hub->url({ action => "Compara_Alignments$ckey", align => undef });
  my (%species_hash, $list);
  
  foreach my $row_key (grep $alignments->{$_}{'class'} !~ /pairwise/, keys %$alignments) {
    my $row = $alignments->{$row_key};
    
    next unless $row->{'species'}->{$species};
    
    $row->{'name'} =~ s/_/ /g;
    
    $list .= qq{<li><a href="$url;align=$row_key">$row->{'name'}</a></li>};
  }
  
  foreach my $i (grep $alignments->{$_}{'class'} =~ /pairwise/, keys %$alignments) {
    foreach (keys %{$alignments->{$i}->{'species'}}) {
      if ($alignments->{$i}->{'species'}->{$species} && $_ ne $species) {
        my $type = lc $alignments->{$i}->{'type'};
        
        $type =~ s/_net//;
        $type =~ s/_/ /g;
        
        $species_hash{$species_defs->species_label($_) . "###$type"} = $i;
      }
    } 
  }
  
  foreach (sort { $a cmp $b } keys %species_hash) {
    my ($name, $type) = split /###/, $_;
    
    $list .= qq{<li><a href="$url;align=$species_hash{$_}">$name - $type</a></li>};
  }
  
  return qq{<div class="alignment_list"><p>View genomic alignments for this gene</p><ul>$list</ul></div>};
}

1;
