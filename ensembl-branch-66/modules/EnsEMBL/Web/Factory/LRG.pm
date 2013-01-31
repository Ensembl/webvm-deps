# $Id: LRG.pm,v 1.6 2011-11-28 13:56:47 ap5 Exp $

package EnsEMBL::Web::Factory::LRG;

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Factory);

sub createObjects { 
  my $self       = shift;
  my $db         = $self->param('db') || 'core'; 
  my $db_adaptor = $self->database($db);
  
  return $self->problem('fatal', 'Database Error', $self->_help("Could not connect to the $db database.")) unless $db_adaptor; 
	
  my $adaptor = $db_adaptor->get_SliceAdaptor;
  my $identifier;
  
  if ($identifier = $self->param('lrg')) {
    my $slice;
    
    eval { $slice = $adaptor->fetch_by_region('LRG', $identifier); }; ## Get the slice
    
    if ($slice) {
      $self->DataObjects($self->new_object('LRG', $slice, $self->__data));
    } else {
      $self->delete_param('lrg');
    }
  }
  elsif (!$self->hub->param('lrg') && $self->hub->action ne 'Genome') {
    return $self->problem('fatal', 'LRG ID required', $self->_help('An LRG ID is required to build this page.'))
  }
}

sub _help {
  my ($self, $string) = @_;
  my $help_text = $string ? sprintf '<p>%s</p>', encode_entities($string) : '';
  my $url       = $self->hub->url({ __clear => 1, action => 'Summary', lrg => 'LRG_1' });

  $help_text .= sprintf('
    <p>
      This view requires a LRG identifier in the URL. For example:
    </p>
    <blockquote class="space-below"><a href="%s">%s</a></blockquote>',
    encode_entities($url),
    encode_entities($self->species_defs->ENSEMBL_BASE_URL . $url)
  );

  return $help_text;
}

1;