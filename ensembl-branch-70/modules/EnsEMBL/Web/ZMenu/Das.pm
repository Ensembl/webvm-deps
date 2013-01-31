# $Id: Das.pm,v 1.15 2012-11-07 11:00:35 sb23 Exp $

package EnsEMBL::Web::ZMenu::Das;

use strict;

use HTML::Entities qw(encode_entities decode_entities);
use XHTML::Validator;

use EnsEMBL::Web::Tools::Misc qw(champion);
use Bio::EnsEMBL::ExternalData::DAS::Coordinator;

use base qw(EnsEMBL::Web::ZMenu);

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $species_defs = $hub->species_defs;
  my $logic_name   = $hub->param('logic_name') || die 'No logic name in params';
  my $feature_id   = $hub->param('feature_id');
  my $group_id     = $hub->param('group_id');
  my $start        = $hub->param('start');
  my $end          = $hub->param('end');
  my $strand       = $hub->param('strand');
  my $click_start  = $hub->param('click_start');
  my $click_end    = $hub->param('click_end');
  my %das          = %{$hub->get_all_das($hub->species)};
  my $slice        = $self->object->slice;
  my %strand_map   = ( 1 => '+', -1 => '-' );
  
  my $coordinator = Bio::EnsEMBL::ExternalData::DAS::Coordinator->new(
    -sources => [ $das{$logic_name} ],
    -proxy   => $species_defs->ENSEMBL_WWW_PROXY,
    -noproxy => $species_defs->ENSEMBL_NO_PROXY,
    -timeout => $species_defs->ENSEMBL_DAS_TIMEOUT
  );
 
  my $features = $coordinator->fetch_Features($slice, ( feature => $feature_id, group => $group_id ));
  
  return unless $features && $features->{$logic_name};
  
  my $validator = XHTML::Validator->new('extended');
  my $id        = $feature_id || $group_id || 'default';
  
  $strand = $strand_map{$strand};
  
  $self->caption($hub->param('label'));
  
  foreach (keys %{$features->{$logic_name}->{'features'}}) {
    my $objects = $features->{$logic_name}->{'features'}->{$_}->{'objects'};
    
    next unless scalar @$objects;
    
    my (@feat, $nearest_feature);
    
    if ($group_id) {
      $nearest_feature = 1;    # Initialise so it exists
      my $nearest = 1e12; # Arbitrary large number
      my ($left, $right, $min);

      foreach (@$objects) {
        $left  = $_->seq_region_start - $click_start;
        $right = $click_end - $_->seq_region_end;
        
        # If both are 0 or positive, feature is inside the click region.
        # If both are negative, click is inside the feature.
        if (($left >= 0 && $right >= 0) || ($left < 0 && $right < 0)) {
          push @feat, $_;
          
          $nearest_feature = undef;
        } elsif ($nearest_feature) {
          $min = [ sort { $a <=> $b } abs($left), abs($right) ]->[0];
          
          if ($min < $nearest) {
            $nearest_feature = $_;
            $nearest = $min;
          }
        }
      }
      
      # Return the nearest feature if it's inside two click widths
      push @feat, $nearest_feature if $nearest_feature && $nearest < 2 * ($click_end - $click_start);
    } else {
      # not grouped
      # extracts closest feature
      @feat = (champion {
        -(abs($_->seq_region_start - $hub->param('start')) +
         abs($_->seq_region_end - $hub->param('end'))) * 2 -
        ($_->strand != $hub->param('strand'))
      } @$objects);
    }
    
    foreach (@feat) {
      my $method = $_->method_label; 
      my $score  = $_->score;
      
      $self->add_subheader(($nearest_feature ? 'Nearest feature: ' : '') . $_->display_label) if ($_->display_id ne $id && $_->display_id ne $self->caption) || scalar @feat > 1;
      
      $self->add_entry({ type => 'Type:',   label_html => $_->type_label });
      $self->add_entry({ type => 'Method:', label_html => $method }) if $method;
      $self->add_entry({ type => 'Start:',  label_html => $_->seq_region_start });
      $self->add_entry({ type => 'End:',    label_html => $_->seq_region_end });
      $self->add_entry({ type => 'Strand:', label_html => $strand }) if $strand;
      $self->add_entry({ type => 'Score:',  label_html => $score })  if $score;
      
      $self->add_entry({ label_html => $_->{'txt'}, link => decode_entities($_->{'href'}), extra => { external => ($_->{'href'} !~ /^http:\/\/www.ensembl.org/) } }) for @{$_->links};
      
      foreach (map decode_entities($_), @{$_->notes}) {
        my $note = $validator->validate($_) ? encode_entities($_) : $_;
        
        if ($note =~ /: /) {
          my ($type, $label_html) = split /: /, $note, 2;
          $self->add_entry({ type => $type, label_html => $label_html });
        } else {
          $self->add_entry({ label_html => $note });
        }
      }
    }
  }
}

1;
