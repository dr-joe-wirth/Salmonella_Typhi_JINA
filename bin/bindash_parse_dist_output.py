#!/usr/bin/env python3

import os
import sys
import argparse

parser = argparse.ArgumentParser(
    description='Parse bindash results file')
parser.add_argument('input', nargs='?', type=argparse.FileType('r'),
                    default=sys.stdin,
                    help='bindash output file')
parser.add_argument('output', nargs='?', type=argparse.FileType('w'),
                    default=sys.stdout,
                    help='processed bindash results')
parser.add_argument('-l', '--lengths', type=argparse.FileType('r'),
                    required=True,
                    help='file with genome lengths')
parser.add_argument('-n', '--noheader', action='store_false',
                    default=True,
                    help='write header to output')
parser.add_argument('--version', action='version', version='%(prog)s 1.0')
args = parser.parse_args()

size_1M = {}
header = next(args.lengths)
for line in args.lengths:
    line = line.strip()
    if line == '':
        continue
    fields = line.split("\t")
    size_1M[fields[1]] = int(fields[4]) / 1000000

if args.noheader:
    args.output.write("\t".join(('Ref-ID', 'Qry-ID', 'Mut-distance', 'P-value', 'Hashes', 'JI', 'GLD_1M')) + "\n")
for line in args.input:
    line = line.strip()
    if line == '':
        continue
    fields = line.split("\t")
    (numer, denom) = fields[4].split('/')
    ji = int(numer) / int(denom)
    gld_1M = abs(size_1M[fields[1]] - size_1M[fields[0]])
    args.output.write("\t".join((fields[0], fields[1], fields[2], fields[3], fields[4], '{:.6g}'.format(ji), '{:.6g}'.format(gld_1M))) + "\n")
