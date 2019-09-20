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

samfile = pysam.AlignmentFile(args.input, "rb") # in.bam
#samfile = pysam.AlignmentFile("test.sam", "r") # in.sam
outsam = pysam.AlignmentFile(args.output, "w", template=samfile, header=samfile.header, referencenames=samfile.references) # output sam
#outsam = pysam.AlignmentFile("allpaired.bam", "wb", template=samfile, header=samfile.header, referencenames=samfile.references) # output bam
tag_scan = args.tag # "ms"
tag_add = args.newtag # "XP"

# First, make a list of reads and their selected tag value(s)
name_list = [] # Make list of read names with the tag
tag_list = [] # Make list of tags for the read names
for read in samfile.fetch():
	if read.has_tag(tag_scan):
		name_list.append(read.query_name)
		tag_list.append(read.get_tag(tag_scan))

reads = list(Counter(name_list).keys()) # Get read names of keys
tags = list(Counter(name_list).values()) # Get tag values of keys 

# Go through the bam file and if read doesn't have a tag give it value 0 to the new tag if it does but it's in the bam file only once give it a new tag with value 1; if it's there more times check the highest value of the tag and count how many times it was present and assign it to the new tag 
for read in samfile.fetch():
#	print(read.query_name) # Print read name
	if read.has_tag(tag_scan):
		index = reads.index(read.query_name) # Find the read in the list and save position
		if tags[index] > 1:
#		 	print("Does have tag: " + tag_scan + " and is present multiple time.")
			# index = name_list.index(read.query_name) # Only the first occurence
			index = [i for i, x in enumerate(name_list) if x == read.query_name]
			#print(tag_list[index]) # Python cannot do multiple indexes
			tag_list_r = [ tag_list[i] for i in index ]
#			print(read.get_tag('tp', with_value_type=True))
			read.tags += [(tag_add, tag_list_r.count(max(tag_list_r)))]

#			tags_tmp = read.tags # Manually adding the tuple, just for excercise
#			tags_tmp.append(tuple(list((tag_add, 1))))
#			read,tags = tags_tmp

#			print(read.get_tag('tp', with_value_type=True))
			outsam.write(read)
		else:
#		 	print("Does have tag: " + tag_scan + " and is present one time.")
			read.tags += [(tag_add, 1)]
			outsam.write(read)	
	else:
#	 	print("Doesn't have tag: " + tag_scan + ". Adding " + tag_add + ":i:0 by default.")
	 	read.tags += [(tag_add, 0)]
	 	outsam.write(read)

outsam.close()
samfile.close()
