#!/usr/bin/python

'''-----------------------------------
Tool to split tab/BED files per chromosome
Based on https://gist.github.com/basielw/e51786595c1c2fefffccd11e11caa688
-----------------------------------'''

#import modules
import os,sys,re
from optparse import OptionParser

class bcolors:
    FAIL = '\033[91m'
    ENDC = '\033[0m'

def main():
    usage = "\n%prog  [options]"
    parser = OptionParser(usage)
    parser.add_option("-b","--bed_file",action="store",dest="bed_file",help="Original BED file that should be split per chromosome.")
    parser.add_option("-c","--chr_col",action="store",dest="chr_col",default=1,type="int",help="Column number which stores chromosome names. Default: 1 (BED).")
    parser.add_option("-r","--header",action="store_true",dest="header",default=False,help="The file contains header.")
    parser.add_option("-d","--directory",action="store",dest="directory",default="./",help="Directory where the BED files per chromosome should be created. Default = current directory")
    #parser.add_option("-s", "--split",action="store_true",dest="split_strand",default=False,help="Additionally split each file per strand.")

    (options,args)=parser.parse_args()

    #"fix" column number to be 0-based
    options.chr_col = options.chr_col - 1

    #check if bed_file was given
    if not options.bed_file:
        print >>sys.stderr, bcolors.FAIL + "\nError: no BED file defined\n" + bcolors.ENDC
        parser.print_help()
        sys.exit(0)

    #check if directory was given and if not, use current directory
    if not options.directory:
        options.directory = "./"

    #check if directory ends with / and if not, add it
    if options.directory[-1] != "/":
        options.directory = options.directory + "/"

    #check if directory exists and if not, make it
    if not os.path.exists(options.directory):
        os.makedirs(options.directory)

    #get name of the BED file
    bed_name = os.path.basename(options.bed_file)
    bed_suffix = bed_name.split(".")[-1]
    bed_name = re.sub(bed_suffix + "$", "", bed_name)

    #this is where the magic happens
    file_list = {}
    count = 0
    bed_file = open(options.bed_file)

    if options.header is True:
        print "skipping header"
        header_line = next(bed_file) # .rstrip()

    for line in bed_file:
        count +=1
        fields = line.split()

        file_name = str(options.directory + str(bed_name) + '_' + str(fields[options.chr_col]))
        
    #    #add strand name when splitting by strand
    #    if split_strand is True:
    #        if fields[5] == '+':
    #        file_name = str(file_name + '_' + 'pos')
    #        if fields[5] == '-':
    #        file_name = str(file_name + '_' + 'neg')

        #check if chromosome file already exists and if not, make it
        if file_name not in file_list:
    #        file = open('%s.bed' % file_name, 'w+')
            file = open(file_name + "." + bed_suffix, 'w+')
            file_list[file_name] = file
            file_list[file_name].write(header_line)
        
        #write lines to the correct chromosome file
        file_list[file_name].write(line)

        #show gene count to not fall asleep
        print >>sys.stderr, "%d lines finished\r" % count,

    #close all the files
    for key, value in file_list.iteritems():
        value.close
    bed_file.close

if __name__ == '__main__':
    main()