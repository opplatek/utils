#!/usr/bin/env python3
#
# Translate FASTA within BED regions and output BED with codons and aminoacids abbreviation (name column)
# Translates only in-frame codons on plus strand
#
# Inputs are FASTA file, BED file (with CDS start and stop coords, for example), and optional True/False for spliting the FASTA name on any whitespace (default: True)
# Output is translated BED file
#

import sys

def translate_fasta(fasta_path, bed_path, split_fasta_name=True):
    # Define the genetic code lookup table
    genetic_code = {
        'ATA':'I', 'ATC':'I', 'ATT':'I', 
        'ATG':'M',
        'ACA':'T', 'ACC':'T', 'ACG':'T', 'ACT':'T',
        'AAC':'N', 'AAT':'N', 
        'AAA':'K', 'AAG':'K',
        'AGC':'S', 'AGT':'S', 'TCA':'S', 'TCC':'S', 'TCG':'S', 'TCT':'S',
        'AGA':'R', 'AGG':'R',                
        'CTA':'L', 'CTC':'L', 'CTG':'L', 'CTT':'L', 'TTA':'L', 'TTG':'L',
        'CCA':'P', 'CCC':'P', 'CCG':'P', 'CCT':'P',
        'CAC':'H', 'CAT':'H', 
        'CAA':'Q', 'CAG':'Q',
        'CGA':'R', 'CGC':'R', 'CGG':'R', 'CGT':'R',
        'GTA':'V', 'GTC':'V', 'GTG':'V', 'GTT':'V',
        'GCA':'A', 'GCC':'A', 'GCG':'A', 'GCT':'A',
        'GAC':'D', 'GAT':'D', 
        'GAA':'E', 'GAG':'E',
        'GGA':'G', 'GGC':'G', 'GGG':'G', 'GGT':'G',
        'TTC':'F', 'TTT':'F', 
        'TAC':'Y', 'TAT':'Y', 
        'TAA':'*', 'TAG':'*', 'TGA':'*',
        'TGC':'C', 'TGT':'C', 
        'TGG':'W',
    }
    
    # Parse the BED file and extract the regions of interest
#    regions = {}
    regions = []
    with open(bed_path) as f:
        for line in f:
            fields = line.strip().split()
            chrom, start, end = fields[0], int(fields[1]), int(fields[2])
    #        regions[chrom] = (start, end)
            regions.append((chrom, start, end))
    
    # Parse the input FASTA file and extract the DNA sequences
    with open(fasta_path) as f:
        lines = f.readlines()
        
    sequences = []
    current_sequence = ''
    
    for line in lines:
        if line.startswith('>'):
            if current_sequence:
                sequences.append((header, current_sequence))
                current_sequence = ''
            header = line.strip()[1:]
#            if split_fasta_name == "True":
            if split_fasta_name is True:
                header = header.split()[0]
        else:
            current_sequence += line.strip()
            
    # Handle the last sequence in the file
    if current_sequence:
        sequences.append((header, current_sequence))
    
    # Translate only the regions of the input sequences that overlap with the regions specified in the BED file
    protein_seqs = []
    for header, dna_seq in sequences:
        protein_seq = ''
        for chrom, start, end in regions:
            if chrom != header:
                continue
            start = max(start, 0)
            end = min(end, len(dna_seq))
            if start >= end:
                continue
            for i in range(start, end, 3):
#                codon = dna_seq[start:end]
                codon = dna_seq[i:i+3]
                amino_acid = genetic_code.get(codon.upper().replace("U", "T"), 'X')
                protein_seq += amino_acid
                
                print(header, str(i), str(i+3), codon + "_" + amino_acid, str(0), "+", sep = "\t")

#        protein_seqs.append((header, protein_seq))

    for header, protein_seq in protein_seqs:
        if(len(protein_seq) > 0):
            print(">" + header + "\n" + protein_seq)
        

fasta_path = sys.argv[1]
bed_path = sys.argv[2]
if len(sys.argv) > 2:
    split_fasta_name = bool(sys.argv[3])
else:
    split_fasta_name = True

#fasta_path="/home/jan/projects/mourelatos11/projects/rna_degradation/analysis/rel-codon-distro/src/Python/test.fasta"
#bed_path="/home/jan/projects/mourelatos11/projects/rna_degradation/analysis/rel-codon-distro/src/Python/test.bed"

print(sys.argv)

translate_fasta(fasta_path, bed_path, split_fasta_name)
#print(seq_name, str(i), str(i+3), codon + "_" + amino_acid, str(0), ".", sep = "\t")
