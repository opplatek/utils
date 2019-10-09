#!/usr/bin/env python3
#
# Get the max tag value for a single read and add to all the corresponding reads
# Initially designed for adding count of primary alignments to XP:i tag for Minimap2 alignments based on read name and a value of ms:i tag
#
# Input is sam file, output is sam file (unsorted)
#

import argparse
import sys
import time
from collections import defaultdict

parser = argparse.ArgumentParser(description='Get a count of the maximum value of a specified SAM tag and output the count to a new tag.')
parser.add_argument("-i", "--input", 
					help="Input SAM file. Default: stdin")
parser.add_argument("-o", "--output", 
				 help="Output SAM file. Default: stdout")
parser.add_argument("-t", "--tag", type=str, default="ms", 
				help="Tag name to get the maximum from. Default: ms.")
parser.add_argument("-n", "--newtag", type=str, default="XP", 
				help="Tag name to add the count of maximum value of --tag. Default: XP.")

args = parser.parse_args()

tag_scan = args.tag # "ms"
tag_add = args.newtag # "XP"

t0 = time.time()

# Read input
if args.input:
    f=open(args.input, "r").read()
else:
    f=sys.stdin.read()
lines=f.split('\n')

# Get output
if args.output:
    fout=open(args.output, "w")
else:
    fout=sys.stdout

reads = defaultdict(list)
values = defaultdict(list)
read_notag = []
read_singletag = []
read_multitag = []

# Get line number (index) of reads w/wo tag and for those with a tag get the values
for line in range (len(lines)):
    if lines[line].startswith('@'):
 #       print("It's a header!")
        fout.write(lines[line] + '\n')
    elif [i for i in lines[line].split('\t')[11:] if i.startswith(tag_scan+":")]:
#        print("Found it!")
        reads[lines[line].split('\t')[0]].append(line) # Get index of reads
        values[lines[line].split('\t')[0]].append([i for i in lines[line].split('\t')[11:] if i.startswith(tag_scan+":")][0].rsplit(':', 1)[1]) # Get read tag values
    else:
#        print("Didn't find it")
        if not lines[line].strip(): # Skip empty lines
            continue
        else:
            read_notag.append(line) # Get index of reads with no tag

reads_l = [v for k,v in reads.items()] # get only values from the dictinary
values_l = [v for k,v in values.items()] # get only values from the dictinary

read_multitag = [i for i, x in enumerate([len(x) for x in reads_l]) if x > 1] # Get read with tags more than once https://stackoverflow.com/questions/6294179/how-to-find-all-occurrences-of-an-element-in-a-list
read_singletag = [i for i, x in enumerate([len(x) for x in reads_l]) if x == 1] # Get read with only one tag

for x in read_multitag:
	max_val = values_l[x].count(max(values_l[x]))
	for i in reads_l[x]:
		fout.write(lines[i] + '\t' + tag_add + ':i:' + str(max_val) + '\n')

flat_list_single = [item for sublist in [reads_l[i] for i in read_singletag] for item in sublist] # Unlist the stupid list https://stackoverflow.com/questions/952914/how-to-make-a-flat-list-out-of-list-of-lists

for i in flat_list_single:
	fout.write(lines[i] + '\t' + tag_add + ':i:1' + '\n')
for i in read_notag:
	fout.write(lines[i] + '\t' + tag_add + ':i:0' + '\n')

if args.output:
    fout.close()

print("Don't forget to resort the SAM!")
