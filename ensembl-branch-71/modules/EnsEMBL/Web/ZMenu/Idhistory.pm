# $Id: Idhistory.pm,v 1.7 2011-03-04 15:04:31 bp1 Exp $

package EnsEMBL::Web::ZMenu::Idhistory;

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;

use base qw(EnsEMBL::Web::ZMenu);

sub content {}

sub archive_adaptor {
  my $self = shift;
  my $hub  = $self->hub;
  return $hub->database($hub->param('db') || 'core')->get_ArchiveStableIdAdaptor;
}

sub archive_link {
  my ($self, $archive, $release) = @_;
  
  my $hub = $self->hub;
  
  return '' unless ($release || $archive->release) > $self->object->get_earliest_archive;
  
  my $type    = $archive->type eq 'Translation' ? 'peptide' : lc $archive->type;
  my $name    = $archive->stable_id . '.' . $archive->version;
  my $current = $hub->species_defs->ENSEMBL_VERSION;
  my $view    = "${type}view";
  my ($action, $p, $url);
  
  if ($type eq 'peptide') {
    $view = 'protview';
  } elsif ($type eq 'transcript') {
    $view = 'transview';
  }
  
  # Set parameters for new style URLs post release 50
  if ($archive->release >= 51) {
    if ($type eq 'gene') {
      $type = 'Gene';
      $p = 'g';
      $action = 'Summary';
    } elsif ($type eq 'transcript') {
      $type = 'Transcript';
      $p = 't';
      $action = 'Summary';
    } else {
      $type = 'Transcript';
      $p = 'p';
      $action = 'ProteinSummary';
    }
  }
  
  if ($archive->release == $current) {
     $url = $hub->url({ type => $type, action => $action, $p => $name });
  } else {
    my $release_id   = $archive->release;
    my $adaptor = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub);
    my $release = $adaptor->fetch_release($release_id); 
    my $archive_site = $release ? $release->{'archive'} : '';
    
    if ($archive_site) {
      $url = "http://$archive_site.archive.ensembl.org";
      
      if ($archive->release >= 51) {
        $url .= $hub->url({ type => $type, action => $action, $p => $name });
      } else {
        $url .= $hub->species_path . "/$view?$type=$name";
      }
    }
  }
  
  return $url;
}

1;