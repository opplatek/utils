#!/bin/bash
#
# Sort GTF (for example for IGV or bedtools)
# https://silico-sciences.com/2015/11/sort-gtf/
#
# First argument is input gtf, second (optional) is number of threads; output is the same as input but with suffix "sorted.gtf"
#

in_gtf=$1

if [ -z "$2" ]; then
	echo "Second argument (no. of threads) wasn't speficied, using 1 (default)"
    threads=1
else
	threads=$2
	echo "Using $threads threads to sort."
fi

if [ -f $in_gtf ] ; then
    case $in_gtf in
       *.gtf)   (grep "^#" $in_gtf; grep -v "^#" $in_gtf | sort --parallel=$threads -T $(dirname $in_gtf) -k1,1 -k4,4n) > ${in_gtf%.gtf}.sorted.gtf    ;;
       *.gtf.gz)   (zgrep "^#" $in_gtf; zgrep -v "^#" $in_gtf | sort --parallel=$threads -T $(dirname $in_gtf) -k1,1 -k4,4n) | gzip > ${in_gtf%.gtf.gz}.sorted.gtf.gz    ;;
       *)           echo "don't know how to extract '$in_gtf'..." ;;
    esac
else
    echo "'$1' is not a valid file!"
fi

# Sort uncompressed GTF
#(grep "^#" $in_gtf; grep -v "^#" $in_gtf | sort -k1,1 -k4,4n) > ${in_gtf%.gtf}.sorted.gtf

# Sort compressed GTF
#(zgrep "^#" $in_gtf; zgrep -v "^#" $in_gtf | sort -k1,1 -k4,4n) | gzip > ${in_gtf%.gtf}.sorted.gtf.gz
