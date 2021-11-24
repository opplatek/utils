#!/bin/bash
#
# Convert gtf/gtf.gz to bed(6) using BEDOPS convert2bed
#   https://bedops.readthedocs.io/en/latest/content/reference/file-management/conversion/convert2bed.html
#
# Each line (with 'gene_id' and 'transcript_id' in the desc. part of GTF) gets
#   converted separately! If you want to merge all exons from individual transcripts and merge
#   them to one long feature use gtf2bed from ea-utils
#   https://github.com/ExpressionAnalysis/ea-utils/blob/master/clipper/gtf2bed
#
# Either use gtf/gtf.gz as firt and the only argument or you pipe (in that case use '-'
#   as argument). Output is to stdout
#

if [ ${1} == "-" ]; then
    convert2bed --input=gtf --output=bed - | sort -T . -k1,1 -k2,2n | uniq
else
    if [ ${1##*.} == "gz" ]; then
        zcat $1 | convert2bed --input=gtf --output=bed - | sort -T . -k1,1 -k2,2n | uniq
    else
        cat $1 | convert2bed --input=gtf --output=bed - | sort -T .  -k1,1 -k2,2n | uniq
    fi
fi
