#!/bin/bash
#
# Change particular bases in fasta based on position
#

pos=58.txt
fasta=201801758.assembly.fa

# linearize
perl -pe '$. > 1 and /^>/ ? print "\n" : chomp' $fasta > ${fasta%.*}.linear.fa

# modify
python3 change_bases_fasta.py --list $pos --input ${fasta%.*}.linear.fa --output ${fasta%.*}.fix.fa
rm ${fasta%.*}.linear.fa

########
pos=67.txt
fasta=201801167.assembly.fa

# linearize
perl -pe '$. > 1 and /^>/ ? print "\n" : chomp' $fasta > ${fasta%.*}.linear.fa

# modify
python3 change_bases_fasta.py --list $pos --input ${fasta%.*}.linear.fa --output ${fasta%.*}.fix.fa
rm ${fasta%.*}.linear.fa
