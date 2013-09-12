# $Id: Ajax.pm,v 1.16 2012-12-12 13:23:31 ds23 Exp $

package EnsEMBL::Web::Controller::Ajax;

use strict;

use Apache2::RequestUtil;
use HTML::Entities qw(decode_entities);
use JSON           qw(from_json);

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Controller);

sub new {
  my $class = shift;
  my $r     = shift || Apache2::RequestUtil->can('request') ? Apache2::RequestUtil->request : undef;
  my $args  = shift || {};
  my $self  = {};
  
  my $hub = EnsEMBL::Web::Hub->new({
    apache_handle  => $r,
    session_cookie => $args->{'session_cookie'},
    user_cookie    => $args->{'user_cookie'},
  });
  
  my $func = $hub->action;
  
  bless $self, $class;
  
  $self->$func($hub) if $self->can($func);
  
  return $self;
}

sub autocomplete {
  my ($self, $hub) = @_;
  my $cache   = $hub->cache;
  my $species = $hub->species;
  my $query   = $hub->param('q');
  my ($key, $results);
  
  if ($cache) {
    $key     = sprintf '::AUTOCOMPLETE::GENE::%s::%s::', $hub->species, $query;
    $results = $cache->get($key);
  }
  
  if (!$results) {
    my $dbh = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub)->db;
    my $sth = $dbh->prepare(sprintf 'select display_label, stable_id, db from gene_autocomplete where species = "%s" and display_label like %s', $species, $dbh->quote("$query%"));
    
    $sth->execute;
    
    $results = $sth->fetchall_arrayref;
    $cache->set($key, $results, undef, 'AUTOCOMPLETE') if $cache;
  }
  
  print $self->jsonify($results);
}

sub track_order {
  my ($self, $hub) = @_;
  my $image_config = $hub->get_imageconfig($hub->param('image_config'));
  my $species      = $image_config->species;
  my $node         = $image_config->get_node('track_order');
  
  $node->set_user($species, { %{$node->get($species) || {}}, $hub->param('track') => $hub->param('order') });
  $image_config->altered = 1;
  $hub->session->store;
}

sub multi_species {
  my ($self, $hub) = @_;
  my %species = map { $_ => $hub->param($_) } $hub->param;
  my %args    = ( type => 'multi_species', code => 'multi_species' );
  my $session = $hub->session;
  
  if (scalar keys %species) {
    $session->set_data(%args, $hub->species => \%species);
  } else {
    my %data = %{$session->get_data(%args)};
    delete $data{$hub->species};
    
    $session->purge_data(%args);
    $session->set_data(%args, %data) if scalar grep $_ !~ /(type|code)/, keys %data;
  }
}

sub nav_config {
  my ($self, $hub) = @_;
  my $session = $hub->session;
  my %args    = ( type => 'nav', code => $hub->param('code') );
  my %data    = %{$session->get_data(%args) || {}};
  my $menu    = $hub->param('menu');
  
  if ($hub->param('state')) {
    $data{$menu} = 1;
  } else {
    delete $data{$menu};
  }
  
  $session->purge_data(%args);
  $session->set_data(%args, %data) if scalar grep $_ !~ /(type|code)/, keys %data;
}

sub data_table_config {
  my ($self, $hub) = @_;
  my $session = $hub->session;
  my $sorting = $hub->param('sorting');
  my $hidden  = $hub->param('hidden_columns');
  my %args    = ( type => 'data_table', code => $hub->param('id') );
  my %data;
  
  $data{'sorting'}        = "[$sorting]" if length $sorting;
  $data{'hidden_columns'} = "[$hidden]"  if length $hidden;
  
  $session->purge_data(%args);
  $session->set_data(%args, %data) if scalar keys %data;
}

sub table_export {
  my ($self, $hub) = @_;
  my $r     = $hub->apache_handle;
  my $data  = from_json($hub->param('data'));
  my $clean = sub {
    my ($str,$opts) = @_;
    # Remove summaries, ugh.
    $str =~ s!<span class="toggle_summary[^"]*">.*?</span>!!g;
    # split multiline columns
    for (2..$opts->{'split_newline'}) {
      unless($str =~ s/<br.*?>/\0/) {
        $str =~ s/$/\0/;
      }
    }
    #
    $str =~ s/<br.*?>/ /g;
    $str =~ s/\xC2\xAD//g;     # Layout codepoint (shy hyphen)
    $str =~ s/\xE2\x80\x8B//g; # Layout codepoint (zero-width space)
    $str = $self->strip_HTML(decode_entities($str));
    $str =~ s/"/""/g; 
    $str =~ s/^\s+//;
    $str =~ s/\s+$//g;
    $str =~ s/\0/","/g;
    return $str;
  };
  
  $r->content_type('application/octet-string');
  $r->headers_out->add('Content-Disposition' => sprintf 'attachment; filename=%s.csv', $hub->param('filename'));

  my $options = from_json($hub->param('expopts')) || (); 
  foreach my $row (@$data) {
    my @row_out;
    my @row_opts = @$options;
    foreach my $col (@$row) {
      my $opt = shift @row_opts;
      push @row_out,sprintf('"%s"',$clean->($col,$opt || {}));
    }
    print join(',',@row_out)."\n";
  }
}

1;
