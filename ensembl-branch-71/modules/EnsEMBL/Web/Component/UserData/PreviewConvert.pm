package EnsEMBL::Web::Component::UserData::PreviewConvert;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Component::UserData);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $html = qq(<h2>Preview converted file(s)</h2>
<p>The first ten lines of each file are displayed below. Click on the file name to download the complete file</p>
);

  my @files = $object->param('converted');
  my $i = 1;
  foreach my $id (@files) {
    next unless $id;
    my ($file, $name, $gaps) = split(':', $id);

    ## Tidy up user-supplied names
    $name =~ s/ /_/g;
    $name =~ s/\.(\w{1,4})$/.gff/;
    if ($name !~ /\.gff$/i) {
      $name .= '.gff';
    }
    $name = 'converted_'.$name;

    ## Fetch content
    my $tmpfile = EnsEMBL::Web::TmpFile::Text->new(
                    filename => $file, prefix => 'user_upload', extension => 'gff'
    );
    next unless $tmpfile->exists;
    my $data = $tmpfile->retrieve;
    if ($data) {
      my $newname = $name || 'converted_data_'.$i.'.gff';
      $html .= sprintf('<h3>File <a href="/%s/download?file=%s;name=%s;prefix=user_upload;format=gff">%s</a></h3>', $object->species, $file, $newname, $newname);
      my $gaps = $gaps ? $gaps : 0;
      $html .= "<p>This data includes $gaps gaps where the input coordinates could not be mapped directly to the output assembly.</p>";
      $html .= '<pre>';
      my $count = 1;
      foreach my $row ( split /\n/, $data ) {
        $html .= $row."\n";
        $count++;
        last if $count == 10;
      }
      $html .= '</pre>';
      $i++;
    }
  }
  
  return $html;
}

1;
