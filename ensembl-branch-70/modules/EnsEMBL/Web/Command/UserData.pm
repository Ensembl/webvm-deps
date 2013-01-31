# $Id: UserData.pm,v 1.13.2.2 2013-01-15 15:47:31 hr5 Exp $

package EnsEMBL::Web::Command::UserData;

use strict;

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::TmpFile::Text;
use EnsEMBL::Web::Tools::Misc qw(get_url_content);

use base qw(EnsEMBL::Web::Command);

sub upload {
## Separate out the upload, to make code reuse easier
  my ($self, $method, $type) = @_;
  my $hub       = $self->hub;
  my $params    = {};
  my @orig_path = split '/', $hub->param($method);
  my $filename  = $orig_path[-1];
  my $name      = $hub->param('name');
  my $f_param   = $hub->param('format');
  my ($error, $format, $full_ext, %args);
  
  ## Need the filename (for handling zipped files)
  if ($method eq 'text') {
    $name = 'Data' unless $name;
  } else {
    my @orig_path = split('/', $hub->param($method));
    $args{'filename'} = $orig_path[-1];
    $name ||= $args{'filename'};
  }
  
  $params->{'name'} = $name;

  ## Has the user specified a format?
  if ($f_param) {
    $format = $f_param;
  } elsif ($method ne 'text') {
    ## Try to guess the format from the extension
    my @parts       = split('\.', $filename);
    my $ext         = $parts[-1] =~ /gz|zip/i ? $parts[-2] : $parts[-1];
    my $format_info = $hub->species_defs->DATA_FORMAT_INFO;
    my $extensions;
    
    foreach (@{$hub->species_defs->UPLOAD_FILE_FORMATS}) {
      $format = uc $ext if $format_info->{lc($_)}{'ext'} =~ /$ext/i;
    }
  }
  
  $params->{'format'} = $format;

  ## Set up parameters for file-writing
  if ($method eq 'url') {
    my $url = $hub->param('url');
    $url    =~ s/^\s+//;
    $url    =~ s/\s+$//;

    ## Needs full URL to work, including protocol
    unless ($url =~ /^http/ || $url =~ /^ftp:/) {
      $url = ($url =~ /^ftp/) ? "ftp://$url" : "http://$url";
    }
    my $response = get_url_content($url);
    
    $error           = $response->{'error'};
    $args{'content'} = $response->{'content'};
  } elsif ($method eq 'text') {
    my $text = $hub->param('text');
    if ($type eq 'coords') {
      $text =~ s/\s/\n/g;
    }
    $args{'content'} = $text;
  } else {
    $args{'tmp_filename'} = $hub->input->tmpFileName($hub->param($method));
  }

  ## Add upload to session
  if ($error) {
    $params->{'filter_module'} = 'Data';
    $params->{'filter_code'}   = 'no_response';
  } else {
    my $file = EnsEMBL::Web::TmpFile::Text->new(prefix => 'user_upload', %args);
  
    if ($file->content) {
      if ($file->save) {
        my $session = $hub->session;
        my $code    = join '_', $file->md5, $session->session_id;
        my $format  = $hub->param('format');
           $format  = 'BED' if $format =~ /bedgraph/i;
        my %inputs  = map $_->[1] ? @$_ : (), map [ $_, $hub->param($_) ], qw(filetype ftype style assembly nonpositional);
        
        $inputs{'format'}    = $format if $format;
        $params->{'species'} = $hub->param('species') || $hub->species;
        
        ## Attach data species to session
        my $data = $session->add_data(
          type      => 'upload',
          filename  => $file->filename,
          filesize  => length($file->content),
          code      => $code,
          md5       => $file->md5,
          name      => $name,
          species   => $params->{'species'},
          format    => $format,
          timestamp => time,
          %inputs
        );
        
        $session->configure_user_data('upload', $data);
        
        $params->{'code'} = $code;
      } else {
        $params->{'filter_module'} = 'Data';
        $params->{'filter_code'}   = 'no_save';
      }
    } else {
      $params->{'filter_module'} = 'Data';
      $params->{'filter_code'}   = 'empty';
    }
  }
  
  return $params;
}

sub file_uploaded {
  my ($self, $url_params) = @_;
  
  my $url = encode_entities($self->hub->url($url_params));
 
  $self->r->content_type('text/html; charset=utf-8');
  
  print qq{
    <html>
    <head>
      <script type="text/javascript">
        if (!window.parent.Ensembl.EventManager.trigger('modalOpen', { href: '$url', title: 'File uploaded', rel: 'modal_user_data' })) {
          window.parent.location = '$url';
        }
      </script>
    </head>
    <body><p>UP</p></body>
    </html>
  };
}

1;
