#!Usr/bin/env/python3

#bam file parser for poly(A) visualization in genome browsers
#
#kindly provided by Ivano Legnini <Ivano.Legnini@mdc-berlin.de>
#originally used in Legnini, I., Alles, J., Karaiskos, N. et al. FLAM-seq: full-length mRNA sequencing reveals principles of poly(A) tail length control. Nat Methods 16, 879–886 (2019). https://doi.org/10.1038/s41592-019-0503-y
#

#usage: python SAMPLE.bam SAMPLE_cleaned_tail_lengths.txt SAMPLE.out.bam
#ARGV[0] and [1] are alignment from Minimap2 and read_name\tpolyA tail length file, optionally output bam
#Note: better use this only with single/primary mapped reads!

# TODO: Check chromosome overflow and adjust polyA length to not go over the ends of chromosomes

import sys
import os
import pysam

if len(sys.argv) < 3:
    print("Please, specify input bam and length of polyA per read")
    exit()

sequences = {} #store polyA file with read names as keys, polyA length as values
with open(sys.argv[2]) as polyAfile:
    for line in polyAfile:
        line = line.rstrip().split("\t")
        sequences[line[0]] = int(round(float(line[1]), 0))

polyAfile.close()

#dict(list(sequences.items())[0:2]) # peak into dict

pysam.view("-H", sys.argv[1], "-o", "tmp.sam", catch_stdout=False) #get bam header
pysam.view(sys.argv[1], "-o", "tmp", catch_stdout=False) #convert bam to sam


alignments = {} #store only linear alignments (flag = 0 or 16) into alignments dictionary
with open('tmp') as bamfile:
    for line in bamfile:
        read = line.split()
        if read[1] == '0' or read[1] == '16':
            alignments.setdefault(read[0], []).append(read)

bamfile.close()

#dict(list(alignments.items())[0:2]) # peak into dict

os.system("rm tmp")

#loop over lengths and change alignments
for keys in alignments:

    #in case we don't have polya length in the set 0
    if keys in sequences and sequences[keys] > 0:
        if alignments[keys][0][1] == '0': #if strand minus
            alignments[keys][0][5] = alignments[keys][0][5] + str(sequences[keys]) + "X" #change CIGAR; we can use "M" but "X" will highlight the added nucleotides
            alignments[keys][0][9] = alignments[keys][0][9] + 'A' * sequences[keys] #append polyA - Note: at some point might be worth to edit this part to get mismatches in Ts aligning to genome
            alignments[keys][0][10] = alignments[keys][0][10] + "?" * sequences[keys] #change quality score
        elif alignments[keys][0][1] == '16': #same for strand plus
            alignments[keys][0][3] = str(int(alignments[keys][0][3]) - sequences[keys]) #change leftmost aligment coordinate
            alignments[keys][0][5] = str(sequences[keys]) + "X" + alignments[keys][0][5] #change cigar
            alignments[keys][0][9] = 'A' * sequences[keys] + alignments[keys][0][9] #append polyA; we should add "T" for reverse-mapped reads but for Gviz visualization we add "A"
            alignments[keys][0][10] = "?" * sequences[keys] + alignments[keys][0][10] #change quality score
    else:
        print(keys + ": " + "read not present in polya file or polya length is bellow 0") # Nanopolish put "-1.00" for reads it failed to load (READ_FAILED_LOAD)

#write sam output
with open('tmp', 'w') as outfile:
    for keys in alignments:
        outfile.write("\t".join(str(x) for x in alignments[keys][0]) + "\n")

outfile.close()

#put sam entries and header together
os.system("cat tmp >> tmp.sam")

#convert to bam, sort, index and remove tmp files
pysam.view("-h", "-Sb", "tmp.sam", "-o", "converted_polyA.bam", catch_stdout=False)
if len(sys.argv) == 4:
    pysam.sort("converted_polyA.bam", "-o", sys.argv[3])
    pysam.index(sys.argv[3])
else:
    pysam.sort("converted_polyA.bam", "-o", "converted_polyA_sorted.bam")
    pysam.index("converted_polyA_sorted.bam")
os.system("rm tmp")
os.system("rm tmp.sam")
os.system("rm converted_polyA.bam")
