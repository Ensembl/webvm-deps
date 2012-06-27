# $Id: Compara_Alignments.pm,v 1.20 2012-01-27 14:43:14 sb23 Exp $

package EnsEMBL::Web::Component::Variation::Compara_Alignments;

use strict;

use base qw(EnsEMBL::Web::Component::Compara_Alignments);

sub get_sequence_data {
  my ($self, $slices, $config) = @_;
  my $hub         = $self->hub;
  my @consequence = $hub->param('consequence_filter');
  my (@sequence, @markup, @temp_slices, @pos);
  
  $config->{'consequence_filter'} = { map { $_ => 1 } @consequence } if join('', @consequence) ne 'off';
  
  foreach my $sl (@$slices) {
    my $mk    = {};
    my $slice = $sl->{'slice'};
    my $name  = $sl->{'name'};
    my $seq   = uc $slice->seq(1);
    
    my ($slice_start, $slice_end, $slice_length, $slice_strand) = ($slice->start, $slice->end, $slice->length, $slice->strand);
    my @variation_seq = map ' ', 1..length $seq;
    
    $config->{'length'} ||= $slice_length;
    
    # Markup inserts on comparisons
    if ($config->{'align'}) {
      while ($seq =~  m/(\-+)[\w\s]/g) {
        my $ins_length = length $1;
        my $ins_end    = pos ($seq) - 1;
        
        $mk->{'comparisons'}->{$ins_end-$_}->{'insert'} = "$ins_length bp" for 1..$ins_length;
      }
    }
    
    # Get variations
    if ($config->{'snp_display'}) {
      my $snps   = [];
      my $u_snps = {};
    
      eval {
        $snps = $slice->get_all_VariationFeatures;
        $snps = [ map { my $snp = $_; grep($config->{'consequence_filter'}{$_}, @{$snp->consequence_type}) || $config->{'v'} eq $snp->variation_name ? $snp : () } @$snps ] if $snps && $config->{'consequence_filter'};
      };
      
      if (scalar @$snps) {
        foreach my $u_slice (@{$sl->{'underlying_slices'}||[]}) {
          next if $u_slice->seq_region_name eq 'GAP';
          
          if (!$u_slice->adaptor) {
            my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor($name, $config->{'db'}, 'slice');
            $u_slice->adaptor($slice_adaptor);
          }
          
          eval {
            map { $u_snps->{$_->variation_name} = $_ } @{$u_slice->get_all_VariationFeatures};
          };
        }
      }
      
      # Put deletes second, so that they will overwrite the markup of other variations in the same location
      my @ordered_snps = map { $_->[1] } sort { $a->[0] <=> $b->[0] } map {[ $_->end < $_->start ? 1 : 0, $_ ]} @$snps;
      
      foreach (@ordered_snps) {
        my $variation_name = $_->variation_name;
        my $var_class      = $_->can('var_class') ? $_->var_class : $_->can('variation') && $_->variation ? $_->variation->var_class : '';
        my $dbID           = $_->dbID;
        my $start          = $_->start;
        my $end            = $_->end;
        my $alleles        = $_->allele_string;
        my $ambigcode      = $var_class =~ /in\-?del|insertion|deletion/ ? '*' : $_->ambig_code;
        my $url            = $hub->url({ species => $name, r => undef, v => $variation_name, vf => $dbID });
        my $var            = $variation_name eq $config->{'v'} ? $ambigcode : qq{<a href="$url">$ambigcode</a>};
        my $snp_type       = $config->{'consequence_filter'} ? lc [ grep $config->{'consequence_filter'}{$_}, @{$_->consequence_type} ]->[0] : undef;
           $snp_type     ||= lc $_->display_consequence;
        
        # If gene is reverse strand we need to reverse parts of allele, i.e AGT/- should become TGA/-
        if ($slice_strand < 0) {
          my @al = split /\//, $alleles;
          
          $alleles  = '';
          $alleles .= reverse($_) . '/' for @al;
          $alleles  =~ s/\/$//;
        }
      
        # If the variation is on reverse strand, flip the bases
        $alleles =~ tr/ACGTacgt/TGCAtgca/ if $_->strand < 0;
        
        # Use the variation from the underlying slice if we have it.
        my $snp = scalar keys %$u_snps ? $u_snps->{$variation_name} : $_;
        
        # Co-ordinates relative to the sequence - used to mark up the variation's position
        my $s = $start - 1;
        my $e = $end   - 1;
        
        # Co-ordinates relative to the region - used to determine if the variation is an insert or delete
        my $seq_region_start = $snp->seq_region_start;
        my $seq_region_end   = $snp->seq_region_end;
        
        if ($var_class =~ /in\-del|insertion|deletion/) {
          ($s, $e)  = ($e, $s) if $s > $e;
        }
        
        $s = 0 if $s < 0;
        $e = $#variation_seq if $e > $#variation_seq;
        
        for ($s..$e) {          
          $mk->{'variations'}->{$_}->{'type'}     = $snp_type;
          $mk->{'variations'}->{$_}->{'v'}        = $variation_name;
          $mk->{'variations'}->{$_}->{'alleles'} .= ($mk->{'variations'}->{$_}->{'alleles'} ? '; ' : '') . $alleles;
          $mk->{'variations'}->{$_}->{'href'}   ||= {
            species     => $name,
            type        => 'ZMenu',
            action      => 'TextSequence',
            factorytype => 'Location'
          };
          
          push @{$mk->{'variations'}->{$_}->{'href'}->{'v'}},  $variation_name;
          push @{$mk->{'variations'}->{$_}->{'href'}->{'vf'}}, $dbID;
          
          $variation_seq[$_] = $var if $ambigcode;
        }
        
        @pos = ($s..$e) if $variation_name eq $config->{'v'};
      }
    }
    
    $mk->{'variations'}->{$_}->{'align'} = 1 for @pos;
    
    if (!$sl->{'no_variations'} && grep /\S/, @variation_seq) {
      push @temp_slices, {};
      push @markup, {};
      push @sequence, [ map {{ letter => $_ }} @variation_seq ];
    }
    
    push @temp_slices, $sl;
    push @markup, $mk;
    push @sequence, [ map {{ letter => $_ }} split //, $seq ];
    
    $config->{'ref_slice_seq'} ||= $sequence[-1];
  }
  
  $config->{'slices'} = \@temp_slices;
  
  return (\@sequence, \@markup);
}

sub markup_variation {
  my $self = shift;
  my ($sequence, $markup, $config) = @_;

  my $hub = $self->hub;
  my ($snps, $inserts, $deletes, $seq, $variation, $ambiguity);
  my $i = 0;

  foreach my $data (@$markup) {
    $seq = $sequence->[$i];
    
    foreach (sort { $a <=> $b } keys %{$data->{'variations'}}) {      
      $variation = $data->{'variations'}->{$_};
      
      $seq->[$_]->{'title'} .= ($seq->[$_]->{'title'} ? '; ' : '') . $variation->{'alleles'};
      $seq->[$_]->{'class'} .= "$variation->{'type'} ";
      $seq->[$_]->{'class'} .= 'bold ' if $variation->{'align'};
      $seq->[$_]->{'class'} .= 'var '  if $config->{'v'} eq $variation->{'v'}; # The page's variation
      $seq->[$_]->{'href'}   = $hub->url($variation->{'href'}) if $variation->{'href'};
      
      $config->{'key'}->{'variations'}->{$variation->{'type'}} = 1 if $variation->{'type'};
    }
    
    $i++;
  }
}

sub markup_conservation {
  my $self = shift;
  my ($sequence, $config) = @_;
  
  my $difference = 0;
  
  for my $i (0..scalar(@$sequence)-1) {
    next unless keys %{$config->{'slices'}->[$i]};
    next if $config->{'slices'}->[$i]->{'no_alignment'};
    
    my $seq = $sequence->[$i];
    
    for (0..$config->{'length'}-1) {
      next if $seq->[$_]->{'letter'} eq $config->{'ref_slice_seq'}->[$_]->{'letter'};
      
      $seq->[$_]->{'class'} .= 'dif ';
      $difference = 1;
    }
  }
  
  $config->{'key'}->{'difference'} = 1 if $difference;
}

sub content {  
  my $self         = shift;
  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species      = $hub->species;
  my $species_defs = $hub->species_defs;
  my $width        = 20;
  my %mappings     = %{$object->variation_feature_mapping}; 
  my $v            = keys %mappings == 1 ? [values %mappings]->[0] : $mappings{$hub->param('vf')};
  
  return $self->_info('Unable to draw SNP neighbourhood', $object->not_unique_location) if $object->not_unique_location;
  
  my $defaults = { 
    snp_display          => 1, 
    title_display        => 1, 
    conservation_display => 1,
    v                    => $hub->param('v')
  };
  
  my $seq_type   = $v->{'type'}; 
  my $seq_region = $v->{'Chr'};
  my $start      = $v->{'start'} - ($width/2);  
  my $end        = $v->{'start'} + abs($v->{'end'} - $v->{'start'}) + ($width / 2);
  
  my $slice   = $hub->get_adaptor('get_SliceAdaptor')->fetch_by_region($seq_type, $seq_region, $start, $end, 1);
  my $align   = $hub->param('align');
  my ($error) = $self->check_for_errors($align, $species);
  
  return $error if $error;
  
  my ($html, $info);
 
  # Get all slices for the gene
  my ($slices, $slice_length) = $self->get_slices($slice, $align, $species);
  
  my @aligned_slices;
  my %non_aligned_slices;
  my %no_variation_slices;  
  my $ancestral_seq;
  
  foreach my $s (@$slices) {
    my $other_species_dbs = $species_defs->get_config($s->{'name'}, 'databases');
    my $name = $species_defs->species_label($s->{'name'});
    
    if ($s->{'name'} eq 'ancestral_sequences') {
      $ancestral_seq = $name;
      $s->{'no_variations'} = 1;
    } else {
      $s->{'no_variations'} = $other_species_dbs && $other_species_dbs->{'DATABASE_VARIATION'} ? 0 : 1;
    }
    
    foreach (@{$s->{'underlying_slices'}}) {
      if ($_->seq_region_name ne 'GAP') {
        $s->{'no_alignment'} = 0;
        last;
      }
      
      $s->{'no_alignment'} = 1;
    }
    
    push @aligned_slices, $s if $ancestral_seq || !$s->{'no_alignment'};
    
    if ($name ne $ancestral_seq) {
      if ($s->{'no_alignment'}) {
        $non_aligned_slices{$name} = 1;
      } elsif ($s->{'no_variations'}) {
        $no_variation_slices{$name} = 1;
      }
    }
  }
  
  my $align_species = $species_defs->multi_hash->{'DATABASE_COMPARA'}->{'ALIGNMENTS'}->{$align}->{'species'};
  my %aligned_names = map { $_->{'name'} => 1 } @aligned_slices;
  
  foreach (keys %$align_species) {
    next if $_ eq 'ancestral_sequences';
    $non_aligned_slices{$species_defs->species_label($_)} = 1 unless $aligned_names{$_};
  }
  
  $no_variation_slices{$ancestral_seq} = 1 if $ancestral_seq;
  
  if (scalar keys %non_aligned_slices) {    
    $info .= sprintf(
      '<p>The following %d species have no alignment in this region:</p><ul><li>%s</li></ul>',
      scalar keys %non_aligned_slices,
      join "</li>\n<li>", sort keys %non_aligned_slices
    );
  }
  
  if (scalar keys %no_variation_slices) {
    $info .= sprintf(
      '<p>The following %d%s species have no variation database:</p><ul><li>%s</li></ul>',
      scalar keys %no_variation_slices,
      (scalar keys %aligned_names != scalar keys %$align_species ? ' displayed' : ''),
      join "</li>\n<li>", sort keys %no_variation_slices
    );
  }
  
  $info = $self->_info('Notes', $info) if $info;  
  
  return $self->content_sub_slice($slice, \@aligned_slices, $info, $defaults);
}

1;
