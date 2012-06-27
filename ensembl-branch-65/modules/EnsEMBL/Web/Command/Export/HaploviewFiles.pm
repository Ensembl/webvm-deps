package EnsEMBL::Web::Command::Export::HaploviewFiles;

use strict;

use URI::Escape qw(uri_escape);

use EnsEMBL::Web::TmpFile::Tar;
use EnsEMBL::Web::TmpFile::Text;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self   = shift;
  my $hub    = $self->hub;
  my $url    = $hub->url({ action => 'LDFormats', function => $hub->function });
  my $params = { type => 'haploview', %{$self->make_files} };
  
  $self->ajax_redirect($url, $params);
}

sub make_files {
  my $self = shift;
  my $location = $self->object->get_location_object;
  
  my $gen_file   = new EnsEMBL::Web::TmpFile::Text(extension => 'ped', prefix => '');
  my $locus_file = new EnsEMBL::Web::TmpFile::Text(
    filename  => $gen_file->filename,
    extension => 'txt',
    prefix    => ''
  );
  
  my $slice_genotypes = $location->get_all_genotypes; # gets all genotypes in the Slice as a hash. where key is region_name-region_start
  
  my ($family, $locus, $genotype);
  my %ind_genotypes;
  my %individuals;
  my @snps;  
  
  foreach my $vf (@{$location->get_variation_features}) {
    my ($genotypes, $ind_data) = $location->individual_genotypes($vf, $slice_genotypes);
    
    next unless %$genotypes;
    
    my $name = $vf->variation_name;
    my $start = $vf->start;
    
    $locus .= "$name $start\r\n";
    
    push (@snps, $name);
    
    map { $ind_genotypes{$_}->{$name} = $genotypes->{$_} } keys %$genotypes;
    map { $individuals{$_} = $ind_data->{$_} } keys %$ind_data;
  }
  
  foreach my $individual (keys %ind_genotypes) {
    my $i      = $individuals{$individual};
    my $output = join "\t", 'FAM' . $family++, $individual, $i->{'father'}, $i->{'mother'}, $i->{'gender'}, "0\t";
       $output =~ s/ /_/g;
    
    foreach (@snps) {
      my $snp = $ind_genotypes{$individual}->{$_} || '00';
      $snp =~ tr/ACGTN/12340/;
      
      $output .= join ' ', split //, $snp;
      $output .= "\t";
    }
    
    $genotype .= "$output\r\n";
  }
  
  print $gen_file ($genotype || 'No data available');
  print $locus_file ($locus || 'No data available');
  
  $gen_file->save;
  $locus_file->save;
  
  my $tar_file = new EnsEMBL::Web::TmpFile::Tar(
    filename        => $gen_file->filename,
    prefix          => '',
    use_short_names => 1
  );
  
  $tar_file->add_file($gen_file);
  $tar_file->add_file($locus_file);
  $tar_file->save;
  
  return {
    gen_file   => uri_escape($gen_file->URL),
    locus_file => uri_escape($locus_file->URL),
    tar_file   => uri_escape($tar_file->URL)
  };
}

1;
