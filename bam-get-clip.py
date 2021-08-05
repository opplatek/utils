#!/usr/bin/env python3
#
# Get number of soft(hard)clipped bases for both sides of the read
#

import argparse
import sys
import pysam
import re

parser = argparse.ArgumentParser(description='Get counts of softclipped bases for both read sides. Mapping strand NOT considered!')
parser.add_argument("-i", "--input", metavar='FILE', 
					help="Input file (SAM/BAM).")
parser.add_argument("-o", "--output", 
				 help="Output file. Default: stdout")
parser.add_argument("-b", "--bam", action='store_true', default='false',
				 help="Force output to be BAM and not in SAM. Default: False.")
parser.add_argument("-t", "--table", action='store_true', default='false',
                 help="Output basic read information + added tags in tsv format instead of SAM/BAM.")
parser.add_argument("-d", "--hardclip", action='store_true', default='false',
                 help="Output number of hardclipped bases instead of softclipped. Default: False.")
parser.add_argument("-c", "--clipL", type=str, default="CL", metavar='CLIPLEFT TAG', 
                help="New SAM tag which holds number of softclipped bases from the left side of the read (mapping strand NOT considered). Default: CL.")
parser.add_argument("-c2", "--clipR", type=str, default="CR", metavar='CLIPRIGHT TAG', 
				help="Tag name to add the count of maximum value of --tag. Can be 0 for no value, any number for number of max values. Default: CR.")

args = parser.parse_args()

"""
### TESTING
infile = pysam.AlignmentFile("test.bam", "r")
outfile = pysam.AlignmentFile("out.bam", "wb", template=infile)
outfile = pysam.AlignmentFile("out.sam", "w", template=infile)
### TESTING
"""

# Read input
#if args.input:
infile = pysam.AlignmentFile(args.input, "r")
#else:
#    infile = pysam.AlignmentFile("-", "r")

# Get output
if args.output:
    if args.table == True:
        outfile = open(args.output, "w")
    elif args.bam == True:
        outfile = pysam.AlignmentFile(args.output, "wb", template=infile)
    else:
        outfile = pysam.AlignmentFile(args.output, "w", template=infile)
else:
    if args.table == True:
        outfile = sys.stdout
    elif args.bam == True:
        outfile = pysam.AlignmentFile(sys.stdout, "wb", template=infile)
    else:
        outfile = pysam.AlignmentFile(sys.stdout, "w", template=infile)

# Softclip (4) or hardclip (5)?
if args.hardclip == True:
    clipcode = 5
else:
    clipcode = 4

# if args.table:
#     pass
# else:
#     print(infile.get_reference_name) # Include header in sam/bam output

for s in infile.fetch():
#    print(s.cigarstring)
#    print(s.cigar) # CIGAR in numeric; 4 = softclip; 5 = hardclip

    if s.cigar[0][0] == int(clipcode):
        s.tags += [(args.clipL, s.cigar[0][1])]
    else:
        s.tags += [(args.clipL, 0)]

    if s.cigar[len(s.cigar)-1][0] == int(clipcode):        
        s.tags += [(args.clipR, s.cigar[len(s.cigar)-1][1])]
    else:
        s.tags += [(args.clipR, 0)]

    if args.table == True:
 #       # Has problem with the reference_name
 #       s = '\t'.join(list(str(s).split("\t"))[0:10]) + "\t" + args.clipL + ":" + \
 #       str(s.get_tag(args.clipL)) + "\t" + args.clipR + ":" + str(s.get_tag(args.clipR)) + "\t" + list(str(s).split("\t"))[11] + '\n'
 
        # https://pysam.readthedocs.io/en/latest/release.html#release-0-8-1 
        if type(s.next_reference_start) is None:
            next_ref = s.next_reference_start
        else:
            next_ref = str(s.next_reference_start + 1)

        if type(s.query_sequence) is None:
            seque = s.query_sequence
        else:
            seque = str(s.query_sequence)

        if type(s.query_qualities) is None:
            qual = s.query_qualities
        else:
            qual = str(s.query_qualities)

        if type(s.next_reference_id) is int:
            next_ref_id = str("*")
        else:
            next_ref_id = s.next_reference_id

        s = s.query_name + '\t' + str(s.flag) + '\t' + s.reference_name + '\t' + \
        str(s.reference_start + 1) + '\t' + str(s.mapping_quality) + '\t' + s.cigarstring + \
        '\t' + next_ref_id + '\t' + next_ref + '\t' + str(s.template_length) + \
        '\t' + seque + '\t' + args.clipL + ":" + str(s.get_tag(args.clipL)) + \
        "\t" + args.clipR + ":" + str(s.get_tag(args.clipR)) + '\t' + '\t'.join(str(v) for v in s.tags) + '\n'
        # For some reason s.reference_start is at the end 1 less than in SAM file
#'\t' + seque + '\t' + qual + '\t' + args.clipL

    outfile.write(s)

outfile.close()
infile.close()