# $Id: Movie.pm,v 1.18 2011-01-05 16:30:06 sb23 Exp $

package EnsEMBL::Web::Component::Help::Movie;

use strict;

use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Document::HTML::MovieList;

use base qw(EnsEMBL::Web::Component::Help);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
  $self->configurable(0);
}

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $adaptor = new EnsEMBL::Web::DBSQL::WebsiteAdaptor($hub);
  my @ids     = $hub->param('id') || $hub->param('feedback');
  my $html;
  my @movies;
  
  if (scalar @ids && $ids[0]) {
    @movies = @{$adaptor->fetch_help_by_ids(\@ids)};
  } else {
    @movies = @{$adaptor->fetch_movies};
  }

  if (scalar @movies == 1 && $movies[0]) {
    my $movie = $movies[0];
    
    $html .= $self->embed_movie($movie);

    ## Feedback
    my $style = 'text-align:right;margin-right:2em';
    
    if ($hub->param('feedback')) {
      $html .= qq{<p style="$style">Thank you for your feedback.</p>};
    } else {
      ## Feedback form
      $html .= $self->help_feedback($style, $movie->{'id'}, return_url => '/Help/Movie', type => 'Movie');

      ## Link to movie-specific feedback form
      $html .= qq{
        <div class="info-box" style="float:right;width:50%;padding:10px;margin:5px">
          If you have problems viewing this movie, we would be grateful if you could <a href="/Help/MovieFeedback?title=$movie->{'title'}" class="popup">provide feedback</a> that will help us improve our service. Thank you.
        </div>
      };
    }
    
    $html .= '</td></tr></table>';
  } elsif (scalar @movies > 0 && $movies[0]) {
    $html .= EnsEMBL::Web::Document::HTML::MovieList::render;
  } else {
    $html .= '<p>Sorry, we have no video tutorials at the moment, as they are being updated for the new site design. Please try again after the next release.</p>';
  }

  return $html;
}

1;
