#!/usr/bin/env perl

BEGIN {
    use strict;
    die "Old version of strict module\n" unless strict->VERSION >= 1.0;
    use warnings;
    die "Old version of warnings module\n" unless warnings->VERSION >= 1.1;
    use Getopt::Long;
    die "Old version of Getopt::Long module\n" unless Getopt::Long->VERSION >= 2.45;
}

use strict;
use warnings;
use Getopt::Long;

my $metadata = '';
my $metadata2 = '';
my $output = '';
my $noheader = 0;
my $nthreads = 1;
GetOptions ("metadata=s" => \$metadata,
            "metadata2=s" => \$metadata2,
            "output=s" => \$output,
            "noheader" => \$noheader,
            "nthreads=i" => \$nthreads)
or die("Error in command line arguments\n");

my $half_matrix = 1;
my $source_dir = '';
my @source = ();
my $target_dir = '';
my @target = ();

if (scalar @ARGV == 0) {
    print STDERR 'At least one directory with sketches is needed';
    exit;
} else {
    $source_dir = shift @ARGV;
    @source = glob($source_dir . '/*.bdsh');
}
if (scalar @ARGV == 0) {
    $half_matrix = 1;
    $target_dir = $source_dir;
    @target = @source;
} else {
    $half_matrix = 0;
    $target_dir = shift @ARGV;
    @target = glob($target_dir . '/*.bdsh');
}

my $tmp_met = 'tmp_met.tsv';
if ($metadata2 eq '') {
    system("cat $metadata > $tmp_met");
} else {
    system("tail -n+2 $metadata2 | cat $metadata - > $tmp_met");
}

my $src_idx = 0;
my $trg_idx = 0;
my @command = ();
for my $src (@source) {
    $src_idx++;
    for my $trg (@target) {
        $trg_idx++;
        next if ($half_matrix && ($trg_idx < $src_idx));
        if ($src_idx == 1 && $trg_idx == 1) {
            if ($noheader) {
                system("bindash dist $src $trg --nthreads=$nthreads | bin/bindash_parse_dist_output.py -l $tmp_met --noheader| gzip > $output");
            } else {
                system("bindash dist $src $trg --nthreads=$nthreads | bin/bindash_parse_dist_output.py -l $tmp_met | gzip > $output");
            }
        } else {
            system("bindash dist $src $trg --nthreads=$nthreads | bin/bindash_parse_dist_output.py -l $tmp_met --noheader| gzip >> $output");
        }
    }
    $trg_idx = 0;
}

system("rm $tmp_met");
