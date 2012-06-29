#########
# Author:  jc3
# Created: 2006
# Last Modified: $Date: 2007/04/27 08:39:46 $
# Maintainer :$Author: jc3 $
# $Revision: 1.12 $ - $Source: /repos/cvs/webcore/SHARED_docs/lib/core/Website/portlet/linkclipboard_ajax.pm,v $

package Website::portlet::linkclipboard_ajax;
use strict;
use warnings;
use base qw(Website::portlet);
use Template;

our $VERSION = '1.1';

sub run {
  my $self  = shift;
  my $links = q{};
  $self->{'clip_data'}->{'env'} = $ENV{'dev'} || q{};
  
  if($self->{'username'}) {
    my $userconfig = $self->{'userconfig'};
    my $data       = $userconfig->get('portlet_linkclipboard') || [];
    if(scalar @{$data}) {
      my $id = 1;
      for my $item (sort @{$data}){
        my ($str, $href) = split q(:), $item, 2;
        push @{$self->{'clip_data'}->{'links'}}, [$str,$href,$id];
      $id++;
      }
    }
  }

  #########
  # render content & return
  #
  my $output = q{};
  my $tt = Template->new;
  $tt->process(\*DATA,{'data'   => $self->{'clip_data'},
                       'display' => $self },\$output) or die $tt->error();
  return $output;
}

1;

__DATA__

<div class="portlet" id="portlet_linkclipboard_ajax">
  <div class="portlethead">Link Clipboard 2</div>

  <div class="portletitem">
    <ul id="linkclipboard">
      [% IF data.links %]
        [% FOREACH link IN data.links.sort %]
      <li><a href="http://www[% data.env %].sanger.ac.uk/cgi-bin/utils/linkclipboard?action=delete;id=[% link.2 %]" onClick="return submit_link([% link.2 %])" title="Click here to delete this link." style="float:right"><img src="/icons/silk/cross.png" alt="x" title="delete"/></a><a href="[% link.1 %]">[% link.0 %]</a></li>
        [% END %]
      [% ELSE %]
      <li>Use the form below to add new links</li>
      [% END %]
    </ul>
  </div>

  <div class="portlethead" id="clip_editor_head">Add a Link</div>
  <div class="portletitem" id="clipboardeditor">
    <form method="post" action="http://www[% data.env %].sanger.ac.uk/cgi-bin/utils/linkclipboard" onSubmit="return submit_link();">
      <ul>
        <li>
         <label style="float:left;width:35px" for="str">NAME:</label>
         <input style="margin-left:10px;" type="text" name="str" size="14" id="str" />
        </li>
        <li>
         <label style="float:left;width:35px" for="href">URL:</label>
         <input style="margin-left:10px;" type="text" name="href" size="14" id="href" />
        </li>
        <li><input type="submit" name="action" value="add"/></li>
      </ul>
    </form>
  </div>
  <script type="text/javascript" src="http://js[% data.env %].sanger.ac.uk/linkclip.js" ></script>
  <script type="text/javascript" src="http://js[% data.env %].sanger.ac.uk/dojo-0.4.1-kitchen_sink/dojo.js" ></script>
</div>

