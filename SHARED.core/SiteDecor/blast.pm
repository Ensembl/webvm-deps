#########
# Author: kg1
#
package SiteDecor::blast;
use strict;
use warnings;
use base qw(SiteDecor);

sub html_headers {
  my $self = shift;

  #########
  # fix up stylesheets (+css), javascript
  #
  my (@st);
  my $s    = $self->stylesheet();
  my $c    = $self->css();

  if($c) {
    if(ref $c) {
      push @st, @{$c};
    } else {
      push @st, $c;
    }
  }

  if($s) {
    if(ref $s) {
      push @st, @{$s};
    } else {
      push @st, $s;
    }
  }

  $self->stylesheet(\@st);
  return $self->SUPER::html_headers();
}

sub site_headers {
  my $self = shift;
  my $header = q(
    <div id="header"><div id="logo">
      <a href="/"><img src="http://www.sanger.ac.uk/s-inst/gfx/sanger-logo.png" alt="Wellcome Trust Sanger Institute"></a>
    </div></div>
  );
  $header .= $self->tabs1;
  $header .= $self->tabs2;
  $header .= $self->wrap_top;
  if(defined $self->{'banner'}) {
    my $banner = q();
    if($self->{'bannercase'} eq 'uc') {
      $banner = uc $self->{'banner'};

    } elsif($self->{'bannercase'} eq 'ucfirst') {
      $banner = ucfirst $self->{'banner'};

    } elsif($self->{'bannercase'} eq 'none') {
      $banner = $self->{'banner'};

    } else {
      $banner = lc $self->{'banner'};
    }
    $header .= "<h2>$banner</h2>";
  }
  return $header;
}

sub site_footers {
  my $self = shift;
  my $footer = $self->wrap_bottom;
  $footer .= q(
    <div id="footer">
      <ul id="footer_links">
        <li>
          <a href="http://www.sanger.ac.uk/help/">Help</a>
        </li>
        <li>|
        </li>
        <li>
          <a href="http://www.sanger.ac.uk/about/contact/">Contact us</a>
        </li>
        <li>|
        </li>
        <li>
          <a href="http://www.sanger.ac.uk/legal/">Legal</a>
        </li>
        <li>|
        </li>
        <li>
          <a href="http://www.sanger.ac.uk/datasharing/">Data sharing</a>
        </li>
        <li>|
        </li>
        <li>
          <a href="http://www.sanger.ac.uk/legal/cookiespolicy.html">Cookie Policy</a>
        </li>
      </ul><br>
      Wellcome Trust Sanger Institute, Genome Research Limited (reg no. 2742969) is a charity registered in England with number 1021457<br>
    </div>
  );
  return $footer;
}

sub active_tab1_cat {
  my $self = shift;
  return 'Resources';
}

sub tabs1_cats {
  my $self = shift;
  my $hash = [
    ['Home' => qq(<li><a href="http://www.sanger.ac.uk/index.html">Home</a></li>)],
    ['Research' => qq(<li><a href="http://www.sanger.ac.uk/research/">Research</a></li>)],
    ['Resources' => qq(<li><a href="http://www.sanger.ac.uk/resources/">Scientific resources</a></li>)],
    ['Work' => qq(<li><a href="http://www.sanger.ac.uk/workstudy/">Work &amp; study</a></li>)],
    ['About' => qq(<li><a href="http://www.sanger.ac.uk/about/">About us</a></li>)],
  ];
  return $hash;
}

sub tabs1 {
  my $self = shift;
  my $tabs = q{
<div id="navTabs">
  <ul id="navLeft" style="margin:0;padding:0">
  };
  foreach my $ent (@{$self->tabs1_cats}){
    my $t = $ent->[1];
    $t=~ s/<li>/<li class="active">/mx if $ent->[0] eq $self->active_tab1_cat;
    $tabs .= "$t\n";
  }
  $tabs .= q{
  </ul>
</div>
  };
  return $tabs;
}

sub active_tab2_cat {
  my $self = shift;
  return 'Software';
}

sub tabs2_cats{
  my $self = shift;
  my $hash = [
    [ 'Mouse'        => qq(<li><a href="http://www.sanger.ac.uk/resources/mouse/">Mouse</a></li>) ],
    [ 'Zebrafish'    => qq(<li><a href="http://www.sanger.ac.uk/resources/zebrafish/">Zebrafish</a></li>) ],
    [ 'Data'         => qq(<li><a href="http://www.sanger.ac.uk/resources/downloads/">Data</a></li>) ],
    [ 'Software'     => qq(<li><a href="http://www.sanger.ac.uk/resources/software/">Software</a></li>) ],
    [ 'Databases'    => qq(<li><a href="http://www.sanger.ac.uk/resources/databases/">Databases</a></li>) ],
    [ 'Technologies' => qq(<li><a href="http://www.sanger.ac.uk/resources/technologies/">Technologies</a></li>) ],
    [ 'Talks'        => qq(<li><a href="http://www.sanger.ac.uk/resources/talksandtraining/">Talks &amp; training</a></li>) ],
  ];
  return $hash;
}

sub tabs2 {
  my $self = shift;
  my $tabs = q{
<div id="NavTabs2">
  <ul id="Tabs2">
  };
  foreach my $ent (@{$self->tabs2_cats}){
    my $t = $ent->[1];
    $t=~ s/<li>/<li class="active">/mx if $ent->[0] eq $self->active_tab2_cat;
    $tabs .= "$t\n";
  }
  $tabs .= q{
  </ul>
</div>
  };
  return $tabs;
}

sub wrap_top {
  return q{
<div id="wrapT">
  <div id="wrapTL"></div>
  <div id="wrapTR"></div>
</div>
<div id="wrap">
  <div id="feature" class="cb">
    <div class="bt">
      <div></div>
    </div>
    <div class="i1">
      <div class="i2">
        <div class="i3">
  };
}

sub wrap_bottom {
  return q{
        </div>
      </div>
    </div>
    <div class="bb">
      <div></div>
    </div>
  </div>
</div>
<div id="wrapB">
  <div id="wrapBL"></div>
  <div id="wrapBR"></div>
</div>
  };
}
1;
