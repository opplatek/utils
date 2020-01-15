#!/bin/bash
# converts RNA fastq to DNA fastq 
# converts u/U to t/T on every 4th line starting from 2nd line

if [[ $# -eq 0 ]] ; then
    echo 'Please, enter exactly one argument with RNA (Uu) fastq.gz to convert.'
    exit 0
fi

if [[ $# -eq 1 ]] ; then
	echo 'Converting ${1} to DNA (U->T or u->t)'
	
	zcat $1 | sed '2~4y/uU/tT/' | gzip -c > ${1%.fastq*}.dna.fastq.gz # will fail if it's not a proper 4-line fastq
else
	echo 'Please enter EXACTLY one argument - one RNA (Uu) fastq.gz to be converted to DNA (Tt).'
fi
