#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2006-10-10
# Last Modified: $Date: 2007/01/11 11:25:34 $
#
package Website::StopWords;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw($STOPWORDS);
our $VERSION   = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $STOPWORDS = [qw(roulette
		     poker
		     blackjack
		     xanax
		     viagra
		     hydrocodone
		     porn
		     phenteramine
		     phentermine
		     blogspot
		     blogshot
		     ringtone
		     80days.com
		     cialis
		     paxil
		     275mb.com
		     0moola.com)];

1;
