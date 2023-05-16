#!/usr/bin/env python3
#
# Merge tables keeping only one header
# Will stop if the files don't have the same header
#
#python3 table-cat.py test*txt
#Error: testA.txt has a different first line than test1.txt
#python3 table-cat.py test[1-3].txt
#a       b
#1       2
#3       4
#x       y


import sys

# Get the list of files to be merged from the command line arguments
file_list = sys.argv[1:]

# Open the first input file for reading
with open(file_list[0], 'r') as first_file:

    # Read the first line of the first input file
    first_line = first_file.readline().strip()

    # Loop through the remaining input files
    for filename in file_list[1:]:

        # Open the current file for reading
        with open(filename, 'r') as infile:

            # Read the first line of the current file
            current_line = infile.readline().strip()

            # Compare the first line of the current file to the first line of the first file
            if current_line != first_line:

                # If they are not identical, print an error message and exit the script
                print(f'Error: {filename} has a different first line than {file_list[0]}')
                sys.exit(1)

# Print the first line of the first file to stdout
    print(first_line)

    # Loop through all the input files
    for filename in file_list:

        # Open the current file for reading
        with open(filename, 'r') as infile:

            # Skip the first line of the current file (since we already printed it to stdout)
            next(infile)

            # Loop through each remaining line in the current file
            for line in infile:

                # Print the line to stdout
                print(line, end='')                
