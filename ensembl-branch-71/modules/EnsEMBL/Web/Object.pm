# $Id: Object.pm,v 1.96 2012-11-07 11:00:27 sb23 Exp $

package EnsEMBL::Web::Object;

### NAME: EnsEMBL::Web::Object
### Base class - wrapper around a Bio::EnsEMBL API object  

### STATUS: At Risk
### Contains a lot of functionality not directly related to
### manipulation of the underlying API object 

### DESCRIPTION
### All Ensembl web data objects are derived from this class

use strict;

use EnsEMBL::Web::Text::FeatureParser;
use EnsEMBL::Web::TmpFile::Text;
use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Tools::Misc qw(get_url_content);

use base qw(EnsEMBL::Web::Root);

sub new {
  my ($class, $data) = @_;
  my $self = { data => $data };
  bless $self, $class;
  return $self; 
}

sub counts            { return {};        }
sub _counts           { return {};        } # Implemented in plugins
sub availability      { return {};        }
sub can_export        { return 0;         }
sub default_action    { return 'Summary'; }
sub __data            { return $_[0]{'data'};                  }
sub __objecttype      { return $_[0]{'data'}{'_objecttype'};   }
sub Obj               { return $_[0]{'data'}{'_object'};       } # Gets the underlying Ensembl object wrapped by the web object
sub hub               { return $_[0]{'data'}{'_hub'};          }

sub caption           { return ''; }
sub short_caption     { return ''; }

sub species           { return $_[0]->hub->species;               }
sub type              { return $_[0]->hub->type;                  }
sub action            { return $_[0]->hub->action;                }
sub function          { return $_[0]->hub->function;              }
sub script            { return $_[0]->hub->script;                }
sub species_defs      { return shift->hub->species_defs(@_);      }
sub species_path      { return shift->hub->species_path(@_);      }
sub problem           { return shift->hub->problem(@_);           }
sub param             { return shift->hub->param(@_);             }
sub user              { return shift->hub->user(@_);              }
sub database          { return shift->hub->database(@_);          }
sub get_adaptor       { return shift->hub->get_adaptor(@_);       }
sub timer_push        { return shift->hub->timer_push(@_);        }
sub table_info        { return shift->hub->table_info(@_);        }
sub data_species      { return shift->hub->data_species(@_);      }
sub get_imageconfig   { return shift->hub->get_imageconfig(@_);   }
sub get_db            { return shift->hub->get_db(@_);            }

sub DEPRECATED {
  my @caller = caller(1);
  my $warn   = "$caller[3] is deprecated and will be removed in release 62. ";
  my $func   = shift || [split '::', $caller[3]]->[-1];
  $warn     .= "Use EnsEMBL::Web::Hub::$func instead - $caller[1] line $caller[2]\n";
  warn $warn;
}

sub count_alignments {
  my $self       = shift;
  my $cdb        = shift || 'DATABASE_COMPARA';
  my $species    = $self->species;
  my %alignments = $self->species_defs->multi($cdb, 'ALIGNMENTS');
  my $c          = { all => 0, pairwise => 0 };
  
  foreach (grep $_->{'species'}{$species}, values %alignments) {
    $c->{'all'}++ ;
    $c->{'pairwise'}++ if $_->{'class'} =~ /pairwise_alignment/ && scalar keys %{$_->{'species'}} == 2;
  }
  
  $c->{'multi'} = $c->{'all'} - $c->{'pairwise'};
  
  return $c; 
}

sub _availability { 
  my $self = shift;
  
  my $hash = { map { ('database:'. lc(substr $_, 9) => 1) } keys %{$self->species_defs->databases} };
  map { my $key =lc(substr($_,9)); $hash->{"database:$key"} = 1} @{$self->species_defs->compara_like_databases || [] };
  $hash->{'logged_in'} = 1 if $self->user;
  
  return $hash;
}

# Data interface attached to object
sub interface {
  my $self = shift;
  $self->{'interface'} = shift if @_;
  return $self->{'interface'};
}

# Command object attached to proxy object
sub command {
  my $self = shift;
  $self->{'command'} = shift if (@_);
  return $self->{'command'};
}

# The highlights array is passed between web-requests to highlight selected items (e.g. Gene around
# which contigview had been rendered. If any data is passed this is stored in the highlights array
# and an arrayref of (unique) elements is returned.
sub highlights {
  my $self = shift;
  
  if (!exists( $self->{'data'}{'_highlights'})) {
    my %highlights = map { ($_ =~ /^(URL|BLAST_NEW):/ ? $_ : lc $_) => 1 } grep $_, map { split /\|/, $_ } $self->param('h'), $self->param('highlights');
    
    $self->{'data'}{'_highlights'} = [ grep $_, keys %highlights ];
  }
  
  if (@_) {
    my %highlights = map { ($_ =~ /^(URL|BLAST_NEW):/ ? $_ : lc $_) => 1 } @{$self->{'data'}{'_highlights'}||[]}, map { split /\|/, $_ } @_;
    
    $self->{'data'}{'_highlights'} = [ grep $_, keys %highlights ];
  }
  
  return $self->{'data'}{'_highlights'};
}

sub highlights_string { return join '|', @{$_[0]->highlights}; } # Returns the highlights area as a | separated list for passing in URLs.

# Returns the type of seq_region in "human readable form" (in this case just first letter captialised)
sub seq_region_type_human_readable {
  my $self = shift;
  
  if (!$self->can('seq_region_type')) {
    $self->{'data'}->{'_drop_through_'} = 1;
    return;
  }
  
  return ucfirst $self->seq_region_type;
}

# Returns the type/name of seq_region in human readable form - if the coord system type is part of the name this is dropped.
sub seq_region_type_and_name {
  my $self = shift;
  
  if (!$self->can('seq_region_name')) {
    $self->{'data'}->{'_drop_through_'} = 1;
    return;
  }
  
  my $coord = $self->seq_region_type_human_readable;
  my $name  = $self->seq_region_name;
  
  if ($name =~ /^$coord/i) {
    return $name;
  } else {
    return "$coord $name";
  }
}

sub gene_description {
  my $self = shift;
  my $gene = shift || $self->gene;
  my %description_by_type = ('bacterial_contaminant' => 'Probable bacterial contaminant');
  
  if ($gene) {
    return $gene->description || $description_by_type{$gene->biotype} || 'No description';
  } else {
    return 'No description';
  }
}

# There may be occassions when a script needs to work with features of
# more than one type. in this case we create a new {{EnsEMBL::Web::Proxy::Factory}}
# object for the alternative data type and retrieves the data (based on the standard URL
# parameters for the new factory) attach it to the universal datahash {{__data}}
sub alternative_object_from_factory {
  my ($self, $type) = @_;
  
  my $t_fact = $self->new_factory($type, $self->__data);
  
  if ($t_fact->can('createObjects')) {
    $t_fact->createObjects;
    $self->__data->{lc $type}  = $t_fact->DataObjects;
    $self->__data->{'objects'} = $t_fact->__data->{'objects'};
  }
}

sub slice {
  my $self = shift;
  return 1 unless $self->Obj->can('feature_Slice');
  my $slice = $self->Obj->feature_Slice;
  my ($flank5, $flank3) = map $self->param($_), qw(flank5_display flank3_display);
  return $flank5 || $flank3 ? $slice->expand($flank5, $flank3) : $slice;
}

sub long_caption {
  my $self = shift;
  
  my $dxr   = $self->Obj->can('display_xref') ? $self->Obj->display_xref : undef;
  my $label = $dxr ? ' (' . $dxr->display_id . ')' : '';
  
  return $self->stable_id . $label;
}

# method required for ID history views, applies to several web objects

sub get_earliest_archive { 
  my $self = shift;
  
  my $adaptor = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($self->hub);
  my $releases = $adaptor->fetch_releases();
  foreach my $r (@$releases){ 
    return $r->{'id'} if $r->{'online'} eq 'Y';
  }
}
1;

