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

#samfile = pysam.AlignmentFile(args.input, "rb") # in.bam
samfile = pysam.AlignmentFile(args.input, "rb") # in.sam
outsam = pysam.AlignmentFile(args.output, "w", template=samfile, header=samfile.header, referencenames=samfile.references) # output sam
#outsam = pysam.AlignmentFile("allpaired.bam", "wb", template=samfile, header=samfile.header, referencenames=samfile.references) # output bam
tag_scan = args.tag # "ms"
tag_add = args.newtag # "XP"

print("Getting the read occurence.")
# First, make a list of reads and their selected tag value(s)
name_list = [] # Make list of read names with the tag
tag_list = [] # Make list of tags for the read names
for read in samfile.fetch():
	if read.has_tag(tag_scan):
		name_list.append(read.query_name)
		tag_list.append(read.get_tag(tag_scan))

reads = list(Counter(name_list).keys()) # Get read names of keys
tags = list(Counter(name_list).values()) # Get tag values of keys 

print("Adding the sam tag.")
# Go through the bam file and if read doesn't have a tag give it value 0 to the new tag if it does but it's in the bam file only once give it a new tag with value 1; if it's there more times check the highest value of the tag and count how many times it was present and assign it to the new tag 
counter = 1
t0 = time.time()

max_vals = {} # Make empty dictionary of the max tag values
for read in samfile.fetch():
	if (counter % 1000) == 0:
		print("Processed read no. " + str(counter))
	counter += 1
	if read.has_tag(tag_scan):
		if read.query_name in max_vals: # if we already have the value of max value for the read directly fill it out
			read.tags += [(tag_add, max_vals.get(read.query_name))]
			outsam.write(read)
		else:
			index = reads.index(read.query_name) # Find the read in the list and save position
			if tags[index] > 1:
				# index = name_list.index(read.query_name) # Only the first occurence
				index = [i for i, x in enumerate(name_list) if x == read.query_name] # Make an index of all the possitions of the current read in the list
				tag_list_r = [ tag_list[i] for i in index ] # Get the tag values of all the read lines
	#			print(read.get_tag('tp', with_value_type=True)) # Get tag and it's value
				max_val = tag_list_r.count(max(tag_list_r)) # Get the count of the max values for the read
				read.tags += [(tag_add, max_val)] # Add the new tag
				max_vals[read.query_name] = max_val # store the max value to a dictionary for the next time
	#			tags_tmp = read.tags # Manually adding the tuple, just for excercise
	#			tags_tmp.append(tuple(list((tag_add, 1))))
	#			read,tags = tags_tmp
				outsam.write(read)
			else:
				read.tags += [(tag_add, 1)]
				outsam.write(read)	
	else: # If a read doesn't have a tag, write it out right away with 0 - not a fool proof solution but ok for now
		read.tags += [(tag_add, 0)]
		outsam.write(read)

t1 = time.time()
total = t1-t0

print("It took :" + str(total))

outsam.close()
samfile.close()

