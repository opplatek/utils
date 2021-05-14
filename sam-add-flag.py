#!/usr/bin/env python3
#
# Add SAM flag to rows where this flag is not set
# 

import argparse
import sys
import re

# Function to test SAM flag
def checksamflag(checkflag, samflag):
    "Return True of False is checked flag is in sam flag"
    return str(format(int(checkflag), "b"))[::-1].find(str(1)) in [m.start() for m in re.finditer(str(1), str(format(int(samflag), "b")[::-1]))]

parser = argparse.ArgumentParser(description='Count number of mappings per read.')
parser.add_argument("-i", "--input", 
					help="Input SAM file. Default: stdin")
parser.add_argument("-o", "--output", 
				 help="Output SAM file. Default: stdout")
parser.add_argument("-f", "--flag", type=int, default=1024, 
				help="SAM flag to be added. Default: 1024 (PCR duplicate).")

args = parser.parse_args()

## Variables
input = args.input
#input = "test.sam"

output = args.output
#output = "out.sam"

flag = args.flag # "1024"

## Input & Output
# Read input
if input:
    f=open(input, "r").read()
else:
    f=sys.stdin.read()

lines=f.split('\n')

# Get output
if output:
    fout=open(output, "w")
else:
    fout=sys.stdout

for line in range (len(lines)):
#    print(lines[line])
    if lines[line].startswith('@'): # Header save
#        print("It's a header!")
        fout.write(lines[line] + '\n')
    else:
        if not lines[line].strip(): # Skip empty lines
            continue
        elif checksamflag(4, lines[line].split('\t')[1]) or checksamflag(flag, lines[line].split('\t')[1]): # Skip if read is unmapped, or already has the flag paired
#            print("Read unmapped, or already has the flag, skipping.")
            fout.write(lines[line] + '\n')
        else:
            fout.write(lines[line].split("\t")[0] + '\t' + str(int(lines[line].split("\t")[1]) + flag) + '\t' + '\t'.join(lines[line].split("\t")[2:]) + '\n')

if output:
    fout.close()
