#!/usr/local/bin/perl

use strict;
use warnings;
use lib "../../";
use Website::Utilities::Template;
use Test::More;

$ENV{'QUERY_STRING'} = 'a=1;b=2;c=3';
$ENV{'PATH_INFO'}    = '/path/info';
$ENV{'SCRIPT_NAME'}  = '/cgi-bin/templatetest';

my $t   = Website::Utilities::Template->new();
my $ref = [
	   # Plain tests
	   ['XXX_foo_XXX',
	    'test',
	    'test',
	    '1 scalar'],

	   # Environment interpolation tests
	   ['XXX_QUERY_STRING_XXX',
	    '',
	    'a=1;b=2;c=3',
	    'QUERY_STRING environment'],
	   ['XXX_PATH_INFO_XXX',
	    '',
	    '/path/info',
	    'PATH_INFO environment'],
	   ['XXX_SCRIPT_NAME_XXX',
	    '',
	    '/cgi-bin/templatetest',
	    'SCRIPT_NAME environment'],

	   # sprintf tests
	   ['XXX_%e_foo_XXX',
	    'test & more test',
	    'test &amp; more test',
	    '%e CGI::escapeHTML'],
	   ['XXX_%6w_foo_XXX',
	    'test & more tests foo', # hmm, not quite right - bug in Text::Wrap?
	    "test &\nmore\ntests",
	    '%w Text::Wrap'],
	   ['XXX_%d_foo_XXX',
	    '1234',
	    '1234',
	    '%d sprintf'],
	   ['XXX_%06d_foo_XXX',
	    '1234',
	    '001234',
	    '%6d sprintf'],
	   ['XXX_%s_foo_XXX',
	    'bla',
	    'bla',
	    '%s sprintf'],
	   ['XXX_%6s_foo_XXX',
	    'bla',
	    '   bla',
	    '%6s sprintf'],
	   ['XXX_%-6s_foo_XXX',
	    'bla',
	    'bla   ',
	    '%-6s sprintf'],
	   ['XXX_%f_foo_XXX',
	    0.2345025097,
	    '0.234503',
	    '%f sprintf'],
	   ['XXX_%.4f_foo_XXX',
	    0.2345025097,
	    '0.2345',
	    '%.4f sprintf'],

	   # Terniary tests
	   ['XXX_foo_?true?_foo_:false?_foo_XXX',
	    0,
	    'false',
	    '0 false terniary'],
	   ['XXX_foo_?true?_foo_:false?_foo_XXX',
	    '',
	    'false',
	    '"" false terniary'],
	   ['XXX_foo_?true?_foo_:false?_foo_XXX',
	    [],
	    'false',
	    '[] false terniary'],
	   ['XXX_foo_?true?_foo_:false?_foo_XXX',
	    {},
	    'false',
	    '{} false terniary'],
	   ['XXX_foo_?true?_foo_:false?_foo_XXX',
	    1,
	    'true',
	    'scalar true terniary'],
	   ['XXX_foo_?true?_foo_:false?_foo_XXX',
	    [1],
	    'true',
	    '[] true terniary'],
	   ['XXX_foo_?true?_foo_:false?_foo_XXX',
	    {1=>1},
	    'true',
	    '{} true terniary'],

	   # Array tests
	   ['XXX_foo_[XXX_0_XXX XXX_1_XXX]_foo_XXX',
	    [['one','two']],
	    'one two',
	    '1x2 array'],
	   ['XXX_foo_[XXX_0_XXX:]_foo_XXX',
	    [['one'],['two']],
	    'one:two:',
	    '2x1 array'],
	   ['XXX_foo_[XXX_0_XXX XXX_1_XXX:]_foo_XXX',
	    [['one','two'],['three','four']],
	    'one two:three four:',
	    '2x2 array'],
	   ['XXX_foo_[XXX_x_XXX XXX_y_XXX:]_foo_XXX',
	    [{x=>10,y=>20},{x=>100,y=>200}],
	    '10 20:100 200:',
	    'array of hashes'],
	  ];

plan tests => scalar @$ref;

for my $row (@{$ref}) {
  is($t->generate({'foo' => $row->[1]}, $row->[0]), $row->[2], $row->[3]);
}

