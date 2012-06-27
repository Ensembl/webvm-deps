# $Id: Messages.pm,v 1.7 2011-05-19 10:56:14 sb23 Exp $

package EnsEMBL::Web::Component::Messages;

### Module to output messages from session, etc

use strict;

use EnsEMBL::Web::Constants;

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  my $hub = $self->hub;
  
  return unless $hub->can('session');
  
  my $session  = $hub->session;
  my @priority = EnsEMBL::Web::Constants::MESSAGE_PRIORITY;
  my %messages;
  my $html;
  
  # Group messages by type
  push @{$messages{$_->{'function'} || '_info'}}, $_->{'message'} for $session->get_data(type => 'message');
  
  $session->purge_data(type => 'message');
  
  foreach (@priority) {
    next unless $messages{$_};
    
    my $func    = $self->can($_) ? $_ : '_info';
    my $caption = $func eq '_info' ? 'Information' : ucfirst substr $func, 1, length $func;   
    my $msg     = join '</li><li>', @{$messages{$_}};
       $msg     = "<ul><li>$msg</li></ul>" if scalar @{$messages{$_}} > 1;
    
    $html .= $self->$func($caption, $msg);
    $html .= '<br />';
  }
  
  return qq{<div id="messages">$html</div>};
}

1;
