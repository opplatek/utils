#!/usr/bin/env python2
#
# Add flag YS:i:xxx with alignment end to the SAM file (with header). Output BAM.
# http://seqanswers.com/forums/showthread.php?t=51162
#

import pysam
import sys

insam= sys.argv[1]
samfile = pysam.AlignmentFile(insam, "rb")
outfile = pysam.AlignmentFile("-", "wb", template=samfile)

for aln in samfile:
    ys= aln.reference_end
    if not ys:
        ys= -1
    aln.setTag('YS', ys)
    outfile.write(aln)

samfile.close()
outfile.close()
sys.exit()
