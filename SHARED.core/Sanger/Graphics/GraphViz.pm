# Sanger::Graphics::GraphViz.pm
# A subclass of GraphViz.pm to add extra functionality that GraphViz provides
# but which GraphViz.pm doesn't allow access to.
#
# Currently adds two extra graph creation parameters:
# - label: provides a name for a graph, which is output in an image map
# - outputorder: can be one of "breadthfirst","nodesfirst","edgesfirst" and 
# defaults to "breadthfirst".  "edgesfirst" makes sure edges are drawn under
# nodes.
#
# See http://www.graphviz.org/doc/info/attrs.html
# 
# Author:        jws
# Maintainer:    jws
# Created:       2008-04-02
#
package Sanger::Graphics::GraphViz;
use vars qw(@ISA);
use GraphViz;

use strict;
use warnings;


@ISA = qw(GraphViz);

sub new {
    my $proto = shift;
    my $config = shift;

    # Cope with the old hashref format
    if (ref($config) ne 'HASH') {
      my %config;
      %config = ($config, @_) if @_;
      $config = \%config;
    }

    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new($config);

    $self->{LABEL} = $config->{label} if (exists $config->{label});
    $self->{OUTPUTORDER} = $config->{outputorder} if (exists $config->{outputorder});
    return $self;
}


sub _as_debug {
    my $self = shift;

    my $dot = $self->SUPER::_as_debug();
    if ($self->{LABEL}){
	my $label = $self->{LABEL};
	$dot =~ s/test {\n/$label {\n/;
    }
    if ($self->{OUTPUTORDER}){
	my $order = $self->{OUTPUTORDER};
	$dot =~ s/{\n/{\n\toutputorder="$order";\n/;
    }

    #open (my $fh, ">/tmp/dotfile") or die "Can't open /tmp/dotfile";
    #print $fh $dot;
    #close $fh;

    return $dot;
}
