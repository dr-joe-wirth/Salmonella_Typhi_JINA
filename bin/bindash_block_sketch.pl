#!/usr/bin/env perl

BEGIN {
    use strict;
    die "Old version of strict module\n" unless strict->VERSION >= 1.0;
    use warnings;
    die "Old version of warnings module\n" unless warnings->VERSION >= 1.1;
    use Getopt::Long;
    die "Old version of Getopt::Long module\n" unless Getopt::Long->VERSION >= 2.45;
    use File::Basename;
    die "Old version of File::Basename module\n" unless File::Basename->VERSION >= 2.85;
}

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

my $fofn = '';
my $outdir = '';
my $blocksize = 128;
my $kmerlen = 21;
my $exact = '';
my $sketchsize = 32;
my $sketchseed = 41;
my $nthreads = 1;
GetOptions ("fofn=s" => \$fofn,
            "outdir=s" => \$outdir,
            "blocksize=i" => \$blocksize,
            "kmerlen=i" => \$kmerlen,
            "exact" => \$exact,
            "sketchsize=i" => \$sketchsize,
            "sketchseed=i" => \$sketchseed,
            "nthreads=i" => \$nthreads)
or die("Error in command line arguments\n");

system("mkdir -p $outdir");

my @block_lst = ();
my $block_idx = 1;
my $basename = '';
my $block_file = '';
my $sketchfile = '';
open my $FOFN_IN, '<', $fofn or die "Unable to read from $fofn: $!\n";
while (my $fname = <$FOFN_IN>) {
    chomp $fname;
    next if ($fname eq '');
    push(@block_lst, $fname);
    if (scalar @block_lst == $blocksize) {
        $basename = basename($outdir);
        $block_file = $outdir . '/' . $basename . '.' . $block_idx . '.fofn';
        $sketchfile = $outdir . '/' . $basename . '.' . $block_idx . '.bdsh';
        open my $FOFN_OUT, '>', $block_file or die "Unable to write to $block_file: $!\n";
        for my $f (@block_lst) {
            print $FOFN_OUT "$f\n";
        }

        if ($exact) {
            system("bindash sketch --minhashtype=-1 --listfname=$block_file --outfname=$sketchfile --sketchsize64=$sketchsize --randseed=$sketchseed --kmerlen=$kmerlen --nthreads=$nthreads");
        } else {
            system("bindash sketch --listfname=$block_file --outfname=$sketchfile --sketchsize64=$sketchsize --randseed=$sketchseed --kmerlen=$kmerlen --nthreads=nthreads");
        }
        @block_lst = ();
        $block_idx++;
    }
}
close $FOFN_IN;

# The last block of sequences must still be processed
if (scalar @block_lst > 0) {
    $basename = basename($outdir);
    $block_file = $outdir . '/' . $basename . '.' . $block_idx . '.fofn';
    $sketchfile = $outdir . '/' . $basename . '.' . $block_idx . '.bdsh';
    open my $FOFN_OUT, '>', $block_file or die "Unable to write to $block_file: $!\n";
    for my $f (@block_lst) {
        print $FOFN_OUT "$f\n";
    }

    if ($exact) {
        system("bindash sketch --minhashtype=-1 --listfname=$block_file --outfname=$sketchfile --sketchsize64=$sketchsize --randseed=$sketchseed --kmerlen=$kmerlen --nthreads=$nthreads");
    } else {
        system("bindash sketch --listfname=$block_file --outfname=$sketchfile --sketchsize64=$sketchsize --randseed=$sketchseed --kmerlen=$kmerlen --nthreads=$nthreads");
    }
}
