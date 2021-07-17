#!/usr/bin/python3
#
# Take paired-end BAM, get only first|second in a pair (not both!) read and change SAM flags so it looks like it's single-end
#
# https://bioinformatics.stackexchange.com/questions/9228/convert-paired-end-bam-into-a-single-end-bam-and-keep-all-the-reads
#
# First argument "first"|"second" - which read to keep
# Second argument - input bam
# Third argument - outpu bam
#

import sys
import pysam

paired =         1
proper_pair =    2
mate_unmapped =  8
mate_reverse =   32
first_in_pair =  64
second_in_pair = 128

pair = sys.argv[1] # first|second in a pair to preserve
ibam = sys.argv[2] # Input bam
obam = sys.argv[3] # Output bam

if pair == "first":
    keep = first_in_pair
elif pair == "second":
    keep = second_in_pair
else:
    print("Please, use \"first\" or \"second\" as first argument to select which read of the pair to keep in the output.")
    sys.exit()

bam_in = pysam.AlignmentFile(ibam, "rb")
bam_out = pysam.AlignmentFile(obam, "wb", template=bam_in)
for line in bam_in:
#    if line.flag & second_in_pair: # This was in the original script but I am not sure what was the reason for this
#        line.pos += line.template_length
    if line.flag & keep:
#        line.next_reference_id = 0 # Set ref to "*" (=no ref)
        line.next_reference_name = "*" # Set ref to "*" (=no ref)
        line.next_reference_start = -1 # Set mate start pos to unset (=0)
        line.template_length = -1 # Set template length to unset (=0)
        line.flag &= ~(paired + proper_pair + mate_unmapped + mate_reverse + first_in_pair + second_in_pair) # Remove all these flags if present

        bam_out.write(line)
