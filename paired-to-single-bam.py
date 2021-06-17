#!/usr/bin/python3
#
# Take paired-end BAM, get only first-in-pair read and change SAM flags so it looks like it's single-end
#
# https://bioinformatics.stackexchange.com/questions/9228/convert-paired-end-bam-into-a-single-end-bam-and-keep-all-the-reads
#

import pysam

paired =         1
proper_pair =    2
mate_unmapped =  8
mate_reverse =   32
first_in_pair =  64
second_in_pair = 128

ibam = "samples/sc.PARESeq.polya.WT.1/align/reads.1.Aligned.final.bam"
obam = "samples/sc.PARESeq.polya.WT.1/align/reads.1.Aligned.final.SE.bam"

bam_in = pysam.AlignmentFile(ibam, "rb")
bam_out = pysam.AlignmentFile(obam, "wb", template=bam_in)
for line in bam_in:
    if line.flag & second_in_pair:
#        line.pos += line.template_length
        continue
#    line.next_reference_id = 0
#    line.next_reference_start = 0
    line.flag &= ~(paired + proper_pair + mate_unmapped + mate_reverse + first_in_pair + second_in_pair)

    bam_out.write(line)
