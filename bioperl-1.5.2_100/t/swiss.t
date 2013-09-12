# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $Id: swiss.t,v 1.3.4.4 2006/11/09 00:40:53 cjfields Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

my $error = 0;

use strict;

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test::More; };
    if( $@ ) {
        use lib 't/lib';
    }

    use Test::More;
    plan tests => 239;
}

if( $error == 1 ) {
    exit(0);
}

END {
   unlink(qw (swiss_unk.dat test.swiss));
}

use_ok('Bio::SeqIO');
use_ok('Bio::Root::IO');
my $verbose = $ENV{'BIOPERLDEBUG'};

my $seqio = new Bio::SeqIO( -verbose => $verbose,
                                     -format => 'swiss',
                                     -file   => Bio::Root::IO->catfile('t','data', 
                                                    'test.swiss'));

isa_ok($seqio, 'Bio::SeqIO');
my $seq = $seqio->next_seq;
my @gns = $seq->annotation->get_Annotations('gene_name');

$seqio = new Bio::SeqIO( -verbose => $verbose,
                                 -format => 'swiss',
                                 -file   => Bio::Root::IO->catfile
                                 ('>test.swiss'));

$seqio->write_seq($seq);

# reads it in once again
$seqio = new Bio::SeqIO( -verbose => $verbose,
                                 -format => 'swiss',
                                 -file => Bio::Root::IO->catfile('test.swiss'));
    
$seq = $seqio->next_seq;
isa_ok($seq->species, 'Bio::Taxon');
is($seq->species->ncbi_taxid, 6239);

# version, seq_update, dates (5 tests)
is($seq->version, 40);
my ($ann) = $seq->get_Annotations('seq_update');
is($ann, 35);
my @dates = $seq->get_dates;
my @date_check = qw(01-NOV-1997 01-NOV-1997 16-OCT-2001);
for my $date (@dates) {
    is($date, shift @date_check);
}

my @gns2 = $seq->annotation->get_Annotations('gene_name');
# check gene name is preserved (was losing suffix in worm gene names)
ok($#gns2 == 0 && $gns[0]->value eq $gns2[0]->value);

# test swissprot multiple RP lines
my $str = Bio::SeqIO->new(-file => Bio::Root::IO->catfile
                                  (qw(t data P33897) ));
$seq = $str->next_seq;
isa_ok($seq, 'Bio::Seq::RichSeqI');
my @refs = $seq->annotation->get_Annotations('reference');
is( @refs, 23);
is($refs[20]->rp, 'VARIANTS X-ALD LEU-98; ASP-99; GLU-217; GLN-518; ASP-608; ILE-633 AND PRO-660, AND VARIANT THR-13.');

# version, seq_update, dates (5 tests)
is($seq->version, 44);
($ann) = $seq->get_Annotations('seq_update');
is($ann, 28);
@dates = $seq->get_dates;
@date_check = qw(01-FEB-1994 01-FEB-1994 15-JUN-2004);
for my $date (@dates) {
    is($date, shift @date_check);
}

my $ast = Bio::SeqIO->new(-verbose => $verbose,
                                  -format => 'swiss' ,
                                  -file => Bio::Root::IO->catfile("t","data","roa1.swiss"));
my $as = $ast->next_seq();

ok defined $as->seq;
is($as->id, 'ROA1_HUMAN', "id is ".$as->id);
like($as->primary_id, qr(Bio::PrimarySeq));
is($as->length, 371);
is($as->alphabet, 'protein');
is($as->division, 'HUMAN');
is(scalar $as->all_SeqFeatures(), 16);
is(scalar $as->annotation->get_Annotations('reference'), 11);

# version, seq_update, dates (5 tests)
is($as->version, 35);
($ann) = $as->get_Annotations('seq_update');
is($ann, 15);
@dates = $as->get_dates;
@date_check = qw(01-MAR-1989 01-AUG-1990 01-NOV-1997);
for my $date (@dates) {
    is($date, shift @date_check);
}

my ($ent,$out) = undef;
($as,$seq) = undef;

$seqio = Bio::SeqIO->new(-format => 'swiss' ,
                                 -verbose => $verbose,
                                 -file => Bio::Root::IO->catfile
                                 ("t","data","swiss.dat"));
$seq = $seqio->next_seq;
isa_ok($seq, 'Bio::Seq::RichSeqI');

# more tests to verify we are actually parsing correctly
like($seq->primary_id, qr(Bio::PrimarySeq));
is($seq->display_id, 'MA32_HUMAN');
is($seq->length, 282);
is($seq->division, 'HUMAN');
is($seq->alphabet, 'protein');
my @f = $seq->all_SeqFeatures();
is(@f, 2);
is($f[1]->primary_tag, 'CHAIN');
is(($f[1]->get_tag_values('description'))[0], 'COMPLEMENT COMPONENT 1, Q SUBCOMPONENT BINDING PROTEIN');

# version, seq_update, dates (5 tests)
is($seq->version, 40);
($ann) = $seq->get_Annotations('seq_update');
is($ann, 31);
@dates = $seq->get_dates;
@date_check = qw(01-FEB-1995 01-FEB-1995 01-OCT-2000);
for my $date (@dates) {
    is($date, shift @date_check);
}

my @genenames = qw(GC1QBP HABP1 SF2P32 C1QBP);
($ann) = $seq->annotation->get_Annotations('gene_name');
foreach my $gn ( $ann->get_all_values() ) {
    ok ($gn, shift(@genenames));
}
ok($ann->value(-joins => [" AND "," OR "]), "GC1QBP OR HABP1 OR SF2P32 OR C1QBP");

# test for feature locations like ?..N
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));
is($seq->display_id, 'ACON_CAEEL');
is($seq->length, 788);
is($seq->division, 'CAEEL');
is($seq->alphabet, 'protein');
is(scalar $seq->all_SeqFeatures(), 5);

foreach my $gn ( $seq->annotation->get_Annotations('gene_name') ) {
    ok ($gn->value, 'F54H12.1');
}

# test species in swissprot -- this can be a n:n nightmare
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));
my @sec_acc = $seq->get_secondary_accessions();
is($sec_acc[0], 'P29360');
is($sec_acc[1], 'Q63631');
is($seq->accession_number, 'P42655');
my @kw = $seq->get_keywords;
is( $kw[0], 'Brain');
is( $kw[1], 'Neurone');
is($kw[3], 'Multigene family');
is($seq->display_id, '143E_HUMAN');
is($seq->species->binomial, "Homo sapiens");
is($seq->species->common_name, "Human");
is($seq->species->ncbi_taxid, 9606);

$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));
is($seq->species->binomial, "Bos taurus");
is($seq->species->common_name, "Bovine");
is($seq->species->ncbi_taxid, 9913);

# multiple genes in swissprot
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));

($ann) = $seq->annotation->get_Annotations("gene_name");
@genenames = qw(CALM1 CAM1 CALM CAM CALM2 CAM2 CAMB CALM3 CAM3 CAMC);
my $flatnames = "(CALM1 OR CAM1 OR CALM OR CAM) AND (CALM2 OR CAM2 OR CAMB) AND (CALM3 OR CAM3 OR CAMC)";

my @names = @genenames; # copy array
my @ann_names = $ann->get_all_values();

is(scalar(@ann_names), scalar(@names));
foreach my $gn (@ann_names) {
    is($gn, shift(@names));
}
is($ann->value(-joins => [" AND "," OR "]), $flatnames);

# same entry as before, but with the new gene names format
$seqio = Bio::SeqIO->new(-format => 'swiss',
                                 -verbose => $verbose,
                         -file => Bio::Root::IO->catfile
                                 ("t","data","calm.swiss"));
$seq = $seqio->next_seq();
isa_ok($seq, 'Bio::Seq::RichSeqI');
like($seq->primary_id, qr(Bio::PrimarySeq));
($ann) = $seq->annotation->get_Annotations("gene_name");
my @ann_names2 = $ann->get_all_values();
@names = @genenames; # copy array
is(scalar(@ann_names2), scalar(@names));
foreach my $gn (@ann_names2) {
    is($gn, shift(@names));
}
is($ann->value(-joins => [" AND "," OR "]), $flatnames);

# test proper parsing of references
my @litrefs = $seq->annotation->get_Annotations('reference');
is(scalar(@litrefs), 17);

my @titles = (
    '"Complete amino acid sequence of human brain calmodulin."',
    '"Multiple divergent mRNAs code for a single human calmodulin."',
    '"Molecular analysis of human and rat calmodulin complementary DNA clones. Evidence for additional active genes in these species."',
    '"Isolation and nucleotide sequence of a cDNA encoding human calmodulin."',
    '"Structure of the human CALM1 calmodulin gene and identification of two CALM1-related pseudogenes CALM1P1 and CALM1P2."',
    undef,
    '"Characterization of the human CALM2 calmodulin gene and comparison of the transcriptional activity of CALM1, CALM2 and CALM3."',
    '"Cloning of human full-length CDSs in BD Creator(TM) system donor vector."',
    '"The DNA sequence and analysis of human chromosome 14."',
    '"Generation and initial analysis of more than 15,000 full-length human and mouse cDNA sequences."',
    '"Alpha-helix nucleation by a calcium-binding peptide loop."',
    '"Solution structure of Ca(2+)-calmodulin reveals flexible hand-like properties of its domains."',
    '"Calmodulin structure refined at 1.7 A resolution."',
    '"Drug binding by calmodulin: crystal structure of a calmodulin-trifluoperazine complex."',
    '"Structural basis for the activation of anthrax adenylyl cyclase exotoxin by calmodulin."',
    '"Physiological calcium concentrations regulate calmodulin binding and catalysis of adenylyl cyclase exotoxins."',
    '"Crystal structure of a MARCKS peptide containing the calmodulin-binding domain in complex with Ca2+-calmodulin."',
);

my @locs = (
    "Biochemistry 21:2565-2569(1982).",
    "J. Biol. Chem. 263:17055-17062(1988).",
    "J. Biol. Chem. 262:16663-16670(1987).",
    "Biochem. Int. 9:177-185(1984).",
    "Eur. J. Biochem. 225:71-82(1994).",
    "Submitted (FEB-1995) to the EMBL/GenBank/DDBJ databases.",
    "Cell Calcium 23:323-338(1998).",
    "Submitted (MAY-2003) to the EMBL/GenBank/DDBJ databases.",
    "Nature 421:601-607(2003).",
    "Proc. Natl. Acad. Sci. U.S.A. 99:16899-16903(2002).",
    "Proc. Natl. Acad. Sci. U.S.A. 96:903-908(1999).",
    "Nat. Struct. Biol. 8:990-997(2001).",
    "J. Mol. Biol. 228:1177-1192(1992).",
    "Biochemistry 33:15259-15265(1994).",
    "Nature 415:396-402(2002).",
    "EMBO J. 21:6721-6732(2002).",
    "Nat. Struct. Biol. 10:226-231(2003).",
);

my @positions = (
     undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    undef, undef,
    94, 103,
    1, 76,
    undef, undef,
    undef, undef,
    5, 148,
    1, 148,
    undef, undef,
);

foreach my $litref (@litrefs) {
    is($litref->title, shift(@titles));
    is($litref->location, shift(@locs));
    is($litref->start, shift(@positions));
    is($litref->end, shift(@positions));
}

# format parsing changes (pre-rel 9.0)

$seqio = new Bio::SeqIO( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => Bio::Root::IO->catfile('t','data', 
                                                       'pre_rel9.swiss'));

ok($seqio);
$seq = $seqio->next_seq;
isa_ok($seq->species, 'Bio::Taxon');
is($seq->species->ncbi_taxid, "6239");

# version, seq_update, dates (5 tests)
is($seq->version, 44);
($ann) = $seq->get_Annotations('seq_update');
is($ann, 1);
@dates = $seq->get_dates;
@date_check = qw(01-NOV-1997 01-NOV-1996 30-MAY-2006 );
for my $date (@dates) {
    is($date, shift @date_check);
}

my @idcheck = qw(Z66513 T22647 Cel.30446 Q06319 Q20772 F54D5.7 WBGene00010052
		 F54D5.7 GO:0005515 IPR006089 IPR006091 IPR006090
		 IPR006092 IPR009075 IPR009100 IPR013764 PF00441
		 PF02770 PF02771 PS00072 PS00073);

for my $dblink ( $seq->annotation->get_Annotations('dblink') ) {
    is($dblink->primary_id, shift @idcheck);
}

$seqio = new Bio::SeqIO( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => Bio::Root::IO->catfile('t','data', 
                                                       'pre_rel9.swiss'));

my @namespaces = qw(Swiss-Prot TrEMBL TrEMBL);

while (my $seq = $seqio->next_seq) {
    is($seq->namespace, shift @namespaces);
}

# format parsing changes (rel 9.0, Oct 2006)

$seqio = new Bio::SeqIO( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => Bio::Root::IO->catfile('t','data', 
                                                       'rel9.swiss'));

ok($seqio);
$seq = $seqio->next_seq;
isa_ok($seq->species, 'Bio::Taxon');
is($seq->species->ncbi_taxid, 6239);

is($seq->version, 47);
($ann) = $seq->get_Annotations('seq_update');
is($ann, 1);
@dates = $seq->get_dates;
@date_check = qw(01-NOV-1997 01-NOV-1996 31-OCT-2006 );
for my $date (@dates) {
    is($date, shift @date_check);
}

@idcheck = qw(Z66513 T22647 Cel.30446 Q06319 Q20772 F54D5.7 cel:F54D5.7
         WBGene00010052 F54D5.7 GO:0005515 IPR006089 IPR006091 IPR006090
         IPR006092 IPR009075 IPR013786 IPR009100 IPR013764 PF00441 PF02770
         PF02771 PS00072 PS00073 );

for my $dblink ( $seq->annotation->get_Annotations('dblink') ) {
    is($dblink->primary_id, shift @idcheck);
}

$seqio = new Bio::SeqIO( -verbose => $verbose,
                         -format => 'swiss',
                         -file   => Bio::Root::IO->catfile('t','data', 
                                                       'rel9.swiss'));

@namespaces = qw(Swiss-Prot TrEMBL TrEMBL);

while (my $seq = $seqio->next_seq) {
    is($seq->namespace, shift @namespaces);
}
