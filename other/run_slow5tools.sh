#!/bin/bash
#
# slow5tools compression of fast5 to blow5 format
# blow5 saves up to 50% of space
# it doesn't store basecalled sequences but neither do new Nanopore tools (MinKNOWN; https://github.com/hasindu2008/slow5tools/issues/76; 04/28/2022)
# it strips some fast5 fields but the basecalled sequences are IDENTICAL (compared original fast5 and fast5->blow5->fast5)
# BE CAREFUL IF YOUR FAST5 HAS SOME SPECIAL FIELDS OR/AND YOU NEED TO STORE THE BASECALLED SEQUENCE
# it removes blank/empty spaces in fast5 and groups fast5 files into bigger blocks
#
# One required argument - input fast5 directory to be compressed (first positional argument)
# One optional argument - output directory. Default is input directory with _blow5 suffix (second positional argument)
#
##################################################################################

# Get slow5tools
#VERSION=v0.4.0
#wget "https://github.com/hasindu2008/slow5tools/releases/download/$VERSION/slow5tools-$VERSION-x86_64-linux-binaries.tar.gz" && tar xvf slow5tools-$VERSION-x86_64-linux-binaries.tar.gz && cd slow5tools-$VERSION/
#./slow5tools
# Also stored on the server at (downloaded on 04/27/2022)
#/home/joppelt/tools/slow5tools-v0.4.0 # decompressed binaries
#/home/joppelt/tools/archive/slow5tools-v0.4.0-x86_64-linux-binaries.tar.gz # complete tar.gz archive

SLOW=/home/joppelt/tools/slow5tools-v0.4.0/slow5tools

threads=8

$SLOW --version

mode=$3

if [ -z $1 ]; then
	echo "Error: You must specify at least two arguments - first positional argument is the mode - \"comp\" for compression (fast5->blow5) or \"decomp\" for decompression (blow5->fast5). Second positional argument is the input fast5 directory to be compressed/blow5 to be decompressed. Optionaly, you can specify name of the output blow5 compressed/fast5 decompressed directory (third positional argument). Default output directory name is input dir name with \"_blow5\"/\"_fast5\" suffix. Exiting."
	exit 1
else
	mode=$1
fi

if [ -z $2 ]; then
	echo "Error: You must specify input directory to be compressed/decompressed. Exiting."
	exit 2
else
	indir=$2
fi

if [ -z $3 ]; then
	outdir=${indir}
	if [ "$mode" == "comp" ]; then
		outdir=${outdir}_blow5
	elif [ "$mode" == "decomp" ]; then
		outdir=${outdir}_fast5
	fi
else
        outdir=$3
fi

if [ "$mode" == "comp" ]; then
	# Fast5 to Blow5
	echo "Compressing input fast5 directory ${indir} to blow5 directory ${outdir}."
	$SLOW f2s -p $threads $indir -d $outdir
elif [ "$mode" == "decomp" ]; then
	# Blow5 to Fast5
        echo "Decompressing input blow5 directory ${indir} to fast5 directory ${outdir}."
	$SLOW s2f -p $threads $indir -d $outdir
else
	echo "Error: Doesn't understand the mode. Please use \"comp\" for fast5->blow5 compression or \"decomp\" for blow5->fast5 decompression. Exiting."
	exit 3
fi
