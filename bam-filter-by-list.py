#!/usr/bin/env python3
#
# Filter SAM/BAM by specific field and list
# For example, filter reads mapped to a list of chromosomes
# Most of the existing tools can filter only by a single chromosome
#	and/or accept a short list
# This script takes a short list of chromosomes (or any other SAM field)
#	as well as a input file (one feature per line) as an input
#

import argparse
import sys

parser = argparse.ArgumentParser(description='Filter SAM file by a list in a file.')
parser.add_argument("-i", "--input", 
					help="Input SAM file. Default: stdin.")
parser.add_argument("-o", "--output", 
				 help="Output SAM file. Default: stdout.")
parser.add_argument("-l", "--list", type=str, 
				help="File with a list of features to filter. One by line.")
parser.add_argument("-f", "--field", type=str, default='rname',
                help="SAM field to filter by. Defaulr: rname (referece name).")
parser.add_argument("-e", "--exclude", action='store_true', default=False,
				help="Exclude the features in the list instead of include/keep. Default: include.")

args = parser.parse_args()

sam_input = args.input
sam_output = args.output
sub_list = args.list
filt_field = args.field
exclude = args.exclude

#sam_input = "/home/joppelt/projects/rna_degradation/samples/hsa.PARESeq.HAP1.N4BP2KO.1/align/test.sam"
#sam_output = "/home/joppelt/projects/rna_degradation/samples/hsa.PARESeq.HAP1.N4BP2KO.1/align/test.out.sam"
#sub_list = "/home/joppelt/projects/rna_degradation/samples/hsa.PARESeq.HAP1.N4BP2KO.1/align/list.txt"
#filt_field = "rname"
#exclude = True

# https://samtools.github.io/hts-specs/SAMv1.pdf
if filt_field == 'qname':
    filt_field = int(0)
elif filt_field == 'flag':
    filt_field = int(1)
elif filt_field == 'rname':
    filt_field = int(2)
elif filt_field == 'pos':
    filt_field = int(3)
elif filt_field == 'mapq':
    filt_field = int(4)
elif filt_field == 'cigar':
    filt_field = int(5)
elif filt_field == 'rnext':
    filt_field = int(6)
elif filt_field == 'pnext':
    filt_field = int(7)
elif filt_field == 'tlen':
    filt_field = int(8)
elif filt_field == 'seq':
    filt_field = int(9)
elif filt_field == 'qual':
    filt_field = int(10)
else:
    sys.exit('Do not know the name of the field, choose any SAM field and put it in lower-case in --sam_field')

# Read the list of subsets
with open(sub_list, 'r') as f:
    file_content = f.read().strip() # Read whole file in the file_content string
f.close()

# Get output
if sam_output:
    fout=open(sam_output, "w")
else:
    fout=sys.stdout

# Read input
if sam_input:
    fin=open(sam_input, "r")
else:
    fin=sys.stdin

for lines in fin:
    line=lines.strip('\n').strip()

    if line.split('\t')[0] in ['@HD','@SQ','@RG','@PG','@CO']:
       fout.write(line + '\n')
    elif exclude:
        if line.split('\t')[filt_field] not in file_content:
            fout.write(line + '\n')
    else:
        if line.split('\t')[filt_field] in file_content:
            fout.write(line + '\n')
            
if sam_output:
    fout.close()
    
if sam_input:
    fin.close()
