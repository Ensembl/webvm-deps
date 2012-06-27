package EnsEMBL::Web::Command::UserData::MapIDs;

use strict;
use warnings;

use EnsEMBL::Web::Document::SpreadSheet;
use EnsEMBL::Web::TmpFile;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub = $self->hub;
  my $object = $self->object;
  my $url = $object->species_path($object->data_species).'/UserData/PreviewConvertIDs';
  my $param;
  ## Set these separately, or they cause an error if undef
  $param->{'_time'} = $object->param('_time');
  my @files = ($object->param('convert_file'));
  $param->{'species'} = $object->param('species');
  my $output;
  my $temp_files = [];  
  my $size_limit =  $object->param('id_limit');

  foreach my $file_name (@files) {
    next unless $file_name;
    my ($file, $name) = split(':', $file_name);
    my $data = $hub->fetch_userdata_by_id($file);
    my ($ids, $unmapped) = @{$object->get_stable_id_history_data($file, $size_limit)};
    $output .= process_data($ids); 
    $output .= $self->add_unmapped($unmapped);

    ## Output new data to temp file
    my $temp_file = EnsEMBL::Web::TmpFile::Text->new(
        extension => 'txt',
        prefix => 'export',
        content_type => 'text/plain; charset=utf-8',
    );

    $temp_file->print($output);
    my $converted = $temp_file->filename.':'.$name;
    push @$temp_files, $converted;
  }
  $param->{'converted'} = $temp_files;

  $self->ajax_redirect($url, $param);
}

sub process_data {
  my ($ids) = @_; 
  my %stable_ids = %$ids;
  my $table = new EnsEMBL::Web::Document::SpreadSheet( [], [], {'margin' => '1em 0px' } );
  $table->add_option('triangular',1);
  $table->add_columns(
    { 'key' => 'request', 'align'=>'left', 'title' => 'Requested ID'},
    { 'key' => 'match', 'align'=>'left', 'title' => 'Matched ID(s)' },
    { 'key' => 'rel', 'align'=>'left', 'title' => 'Releases:' },
  );

  foreach my $req_id (sort keys %stable_ids) {
    my $matches = {};
    foreach my $a_id (@{ $stable_ids{$req_id}->[1]->get_all_ArchiveStableIds }) {
      $matches->{$a_id->stable_id}->{$a_id->release} = $a_id->release .':'. $a_id->version;
    }
    my %release_match_string;
    foreach my $st_id ( sort keys  %$matches) {
      my %release_data = %{$matches->{$st_id}};
      my @rel;
      foreach (sort keys %release_data){
        push (@rel, $release_data{$_});
      }
      my $release_string = join ',', @rel;
      $release_match_string{$st_id} =  $release_string; 
    }       

    # self matches
    $table->add_row({
      'request' => $req_id,
      'match'   => $req_id,
      'rel'     => $release_match_string{$req_id},
    });
    # other matches
    foreach my $a_id (sort keys %$matches) {
      next if ($a_id eq $req_id);

      $table->add_row({
        'request' => '',
        'match'   => $a_id,
        'rel'     => $release_match_string{$a_id},
      });
    }
  } 

  return $table->render_Text;
}
 
sub add_unmapped {
  my ($self, $unmapped) = @_;
  return unless (scalar keys %$unmapped > 0);
  my $text = "\n\nNo ID history was found for the following identifiers:\n";
  foreach my $id ( sort keys %$unmapped ){
    $text .= $id."\n";
  }
  return $text;
}

1;
