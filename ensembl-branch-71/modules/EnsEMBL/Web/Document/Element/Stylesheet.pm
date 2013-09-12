# $Id: Stylesheet.pm,v 1.5 2011-07-11 14:54:35 sb23 Exp $

package EnsEMBL::Web::Document::Element::Stylesheet;

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub new {
  return shift->SUPER::new({
    %{$_[0]},
    media       => {},
    media_order => [],
    conditional => {}
  });
}

sub add_sheet {
  my ($self, $media, $css, $condition) = @_;
  
  push @{$self->{'media_order'}}, $media unless $self->{'media'}{$media};
  push @{$self->{'media'}{$media}}, $css;
  $self->{'conditional'}->{$css} = $condition if $condition;
}

sub content {
  my $self          = shift;
  my $static_server = $self->static_server;
  my $content;
  
  foreach my $media (@{$self->{'media_order'}}) {
    foreach (@{$self->{'media'}{$media}}) {
      my $href = "$static_server$_";
      
      if ($self->{'conditional'}->{$_}) {
        $content .= qq{  <!--[if $self->{'conditional'}->{$_}]><link rel="stylesheet" type="text/css" media="$media" href="$href" /><![endif]-->\n};
      } else {
        $content .= qq{  <link rel="stylesheet" type="text/css" media="$media" href="$href" />\n};
      }
    }
  }
  
  return $content;
}

sub init {
  my $self         = shift;
  my $controller   = shift;
  my $species_defs = $self->species_defs;
  
  $self->add_sheet('all', sprintf '/%s/%s.css', $species_defs->ENSEMBL_JSCSS_TYPE, $species_defs->ENSEMBL_CSS_NAME);
  
  if ($controller->request eq 'ssi') {
    my $head = $controller->content =~ /<head>(.*?)<\/head>/sm ? $1 : '';
    
    while ($head =~ s/<style(.*?)>(.*?)<\/style>//sm) {
      my ($attr, $cont) = ($1, $2);
      
      next unless $attr =~ /text\/css/;
      
      my $media = $attr =~ /media="(.*?)"/ ? $1 : 'all';
      
      if ($attr =~ /src="(.*?)"/) {
        $self->add_sheet($media, $1);
      } else {
        $self->add_sheet($media, $cont);
      }
    }
    
    while ($head =~ s/<link (.*?)\s*\/>//sm) {
      my %attrs = map { s/"//g; split '=' } split ' ', $1;
      next unless $attrs{'rel'} eq 'stylesheet';
      $self->add_sheet($attrs{'media'} || 'all', $attrs{'href'}) if $attrs{'href'};
    }
  }
}

1;
