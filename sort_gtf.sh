#!/bin/bash
#
# Sort GTF (for example for IGV or bedtools)
# https://silico-sciences.com/2015/11/sort-gtf/
#

IN_GTF=$1

if [ -f $IN_GTF ] ; then
    case $IN_GTF in
       *.gtf)   (grep "^#" $IN_GTF; grep -v "^#" $IN_GTF | sort -k1,1 -k4,4n) > ${IN_GTF%.gtf}.sorted.gtf    ;;
       *.gtf.gz)   (zgrep "^#" $IN_GTF; zgrep -v "^#" $IN_GTF | sort -k1,1 -k4,4n) | gzip > ${IN_GTF%.gtf.gz}.sorted.gtf.gz    ;;
       *)           echo "don't know how to extract '$IN_GTF'..." ;;
    esac
else
    echo "'$1' is not a valid file!"
fi

# Sort uncompressed GTF
#(grep "^#" $IN_GTF; grep -v "^#" $IN_GTF | sort -k1,1 -k4,4n) > ${IN_GTF%.gtf}.sorted.gtf

# Sort compressed GTF
#(zgrep "^#" $IN_GTF; zgrep -v "^#" $IN_GTF | sort -k1,1 -k4,4n) | gzip > ${IN_GTF%.gtf}.sorted.gtf.gz
