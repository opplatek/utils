#!/usr/bin/env python3
#
# Change bases in fasta based on positions in pos.txt https://www.biostars.org/p/265811/
# Format: 
#	head1 1 T
#
# Must linearize the fasta before using this:
#	perl -pe '$. > 1 and /^>/ ? print "\n" : chomp' $fasta > ${fasta%.*}.linear.fa
#	or something else https://www.biostars.org/p/9262/ 
#

import argparse
from collections import defaultdict


parser = argparse.ArgumentParser(description='Get a count of the maximum value of a specified SAM tag and output the count to a new tag.')
parser.add_argument("-i", "--input", 
					help="Input FASTA file (linearized).")
parser.add_argument("-o", "--output", 
				 help="Input FASTA file with modifications")
parser.add_argument("-l", "--list", 
				help="List of changes to change the FASTA in format: chr\tposition\tchange")


args = parser.parse_args()

with open(args.list, 'r') as f:
    pos = defaultdict(list)
    for line in f:
        pos[line.strip().split('\t')[0]].append((int(line.strip().split('\t')[1]), line.strip().split('\t')[2]))

with open(args.input, 'r') as fasta:
    with open(args.output, 'w') as out:
        for line in fasta:
            if line.startswith(">"):
                h = line.strip().split('>')[1]
                s = list(next(fasta).strip())
                if h in pos:
                    for n in pos[h]:
                        s[n[0]-1] = n[1]
                    out.write('>' + h + '\n' + ''.join(s) + '\n')
                else:
                    out.write('>' + h + '\n' + ''.join(s) + '\n')
