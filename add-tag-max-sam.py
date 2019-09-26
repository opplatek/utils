#!/usr/bin/env python3
#
# Get the max tag value for a single read and add to all the corresponding reads
# Initially designed for adding count of primary alignments to XP:i tag for Minimap2 alignments based on read name and a value of ms:i tag
#
# Input is indexed bam file, output is sam file
#

import argparse
import sys
import pysam
from collections import Counter
import time

parser = argparse.ArgumentParser(description='Get a count of the maximum value of a specified SAM tag and output the count to a new tag.')
parser.add_argument("-i", "--input", type=argparse.FileType('r'), 
					help="Input BAM file (must be indexed)")
parser.add_argument("-o", "--output", type=argparse.FileType('w'), default=sys.stdout, 
				 help="Output SAM file. Default: stdout")
parser.add_argument("-t", "--tag", type=str, default="ms", 
				help="Tag name to get the maximum from. Default: ms.")
parser.add_argument("-n", "--newtag", type=str, default="XP", 
				help="Tag name to add the count of maximum value of --tag. Default: XP.")

args = parser.parse_args()

samfile = pysam.AlignmentFile(args.input, "rb") # in.sam
outsam = pysam.AlignmentFile(args.output, "w", template=samfile, header=samfile.header, referencenames=samfile.references) # output sam; "wb" for bam
tag_scan = args.tag # "ms"
tag_add = args.newtag # "XP"

t0 = time.time()

print("Getting the read occurence.")
# First, make a list of reads and their selected tag value(s)
names_all = []
reads_tag = []
reads_out = []
name_list = [] # Make list of read names with the tag
tag_list = [] # Make list of tags for the read names
for read in samfile.fetch():
	if read.has_tag(tag_scan):
		name_list.append(read.query_name)
		tag_list.append(read.get_tag(tag_scan))
		reads_tag.append(read) # Make a big list of reads (~hash)
	else: # If a read doesn't have a tag, write it out right away with 0 - not a fool proof solution but ok for now
		read.tags += [(tag_add, 0)]
#		outsam.write(read) # write the read imidiately
		reads_out.append(read)

# Save reads with no tag and empty list to save some memory
for read in reads_out:
	outsam.write(read)
reads_out = []	

reads = list(Counter(name_list).keys()) # Get read names of keys
tags = list(Counter(name_list).values()) # Get tag values of keys 

index = [i for i, x in enumerate(tags) if x > 1] # Get positions or reads present more than once
reads_multi = [ reads[i] for i in index ] # Get their names

max_vals = {} # Make empty dictionary of the max tag values
for read_name in reads_multi:
	index = [i for i, x in enumerate(name_list) if x == read_name] # Get positions or reads present more than once in the full read name list
	reads_tag_in = [ reads_tag[i] for i in index ] # Get their reads
	for read in reads_tag_in:
		if read.query_name in max_vals:
			read.tags += [(tag_add, max_vals.get(read.query_name))]
			reads_out.append(read)
		else:
			tag_list_r = [ tag_list[i] for i in index ] # get all tag values
			max_val = tag_list_r.count(max(tag_list_r)) # find occurence of the highest
			max_vals[read.query_name] = max_val # save to dictionary for the future
			read.tags += [(tag_add, max_val)] # Add the new tag to the read
			reads_out.append(read)

# Save multi and empty list to save some memory
for read in reads_out:
	outsam.write(read)
reads_out = []

# get reads having the tag but present only once
index = [i for i, x in enumerate(tags) if x == 1] # Get positions or reads present more than once
reads_solo = [ reads[i] for i in index ] # Get their names

for read_name in reads_solo:
	index = [i for i, x in enumerate(name_list) if x == read_name] # Get positions or reads present more than once in the full read name list
	reads_tag_in = [ reads_tag[i] for i in index ] # Get their reads
	for read in reads_tag_in:
		read.tags += [(tag_add, 1)]
		reads_out.append(read)

# Save singles
for read in reads_out:
	outsam.write(read)

t1 = time.time()
total = t1-t0
print("version 2 took :" + str(total))

outsam.close()
samfile.close()

