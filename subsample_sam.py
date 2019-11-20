#!/usr/bin/env python3
#
# Subsample SAM file by list of reads
# https://bioinformatics.stackexchange.com/questions/3380/how-to-subset-a-bam-by-a-list-of-qnames (wjv)
#
# Run as: samtools view input.bam | python3 subsample_sam.py qnames.txt
#

import sys

with open(sys.argv[1], 'r') as indexfile:
    ids = set(l.rstrip('\r\n') for l in indexfile)

for line in sys.stdin:
    qname, _ = line.split('\t', 1)
    if qname in ids:
        sys.stdout.write(line)
