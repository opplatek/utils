#!/bin/bash
#
# Basecalling using guppy on GPU
#
# If guppy cannot find your gpu first check CUDA and nvida drivers are ready
# $ nvidia-smi $ nvidia drivers installation
# $nvcc -V # CUDA installation
#
# If both are working tell guppy to find your GPU card, most likely at "channel" 0 adding
# -x "cuda:0"
# to the guppy command
#

QC=TRUE # [TRUE,FALSE] Do you want to run MinIONQC QC?
threads=6
GUPPY="/home/jan/tools/guppy-3.3.2-1/opt/ont/guppy/bin/guppy_basecaller"
MINQC="/home/jan/tools/MinIONQC-aa1481a/MinIONQC.R" # MinIONQC.R.bckp is the stored original, we just added a few additional plots (and saved as MinIONQC.mod.R and soft-linked to MinIONQC.R)

start=`date +%s` # Measure time of the command - start

echo "Guppy basecalling - RTA trimming off (default, suitable for Nanopolish)"
# List supported flowcells and kits:
#guppy_basecaller --print_workflows

mkdir -p guppy
$GUPPY --version > guppy/guppy-version.log

$GUPPY \
	-x "auto" \
	--flowcell FLO-MIN106 \
 	--kit SQK-RNA002 \
 	--hp_correct on \
 	--records_per_fastq 0 \
 	--u_substitution off \
	--trim_strategy none \
 	--input_path raw/ \
	--save_path guppy/ \
 	--recursive \
 	--compress_fastq \
 	--fast5_out # if we want the fast5 output as well
#	-x "cuda:0"
# --trim_strategy none # Turn off trimming by guppy; we can also --trim_strategy rna or --trim_strategy dna to remove adapters specific to rna or dna
# --reverse_sequence true # Already in the RNA basecalling model config

end=`date +%s` # Measure time of the command - end
runtime=$((end-start)) # Get the runtime
echo "Basecalling took $runtime seconds"

# Merge all fastq files from separate workers.
#zcat guppy/fastq_runid_*.fastq.gz | gzip > guppy/reads.fastq.gz # Original command
cat $(ls guppy/fastq_runid_*.fastq.gz) > guppy/reads.fastq.gz # Should work as well

# Run QC if we want to
if [ $QC = "TRUE" ]; then
	Rscript $MINQC -i guppy -o guppy/qc -p $threads

	# Merge all pngs to one pdf
	# If you get erro "convert: not authorized `MinIONQC.pdf' @ error/constitute.c/WriteImage/1028." you might need to change PDF permissions at /etc/ImageMagick-6/policy.xml to read|write
	convert $(ls guppy/qc/guppy/*.png) guppy/qc/MinIONQC.pdf

#	fastqc -o guppy/qc guppy/reads.fastq.gz
fi

exit

###
###
start=`date +%s` # Measure time of the command - start

echo "Guppy basecalling - RTA trimming on (--trim_strategy rna)"

mkdir -p guppy/RTAtrim
$GUPPY --version > guppy/RTAtrim/guppy-version.log

$GUPPY \
	-x "auto" \
	--flowcell FLO-MIN106 \
 	--kit SQK-RNA002 \
 	--hp_correct on \
 	--records_per_fastq 0 \
 	--u_substitution off \
	--trim_strategy rna \
 	--input_path raw/ \
	--save_path guppy/RTAtrim/ \
 	--recursive \
 	--compress_fastq
# \	--fast5_out # if we want the fast5 output as well
#	-x "cuda:0"
# --trim_strategy none # Turn off trimming by guppy; we can also --trim_strategy rna or --trim_strategy dna to remove adapters specific to rna or dna
# --reverse_sequence true # Already in the RNA basecalling model config

end=`date +%s` # Measure time of the command - end
runtime=$((end-start)) # Get the runtime
echo "Basecalling took $runtime seconds"

# Merge all fastq files from separate workers.
#zcat guppy/fastq_runid_*.fastq.gz | gzip > guppy/reads.fastq.gz # Original command
cat $(ls guppy/RTAtrim/fastq_runid_*.fastq.gz) > guppy/RTAtrim/reads.fastq.gz # Should work as well

# Run QC if we want to
if [ $QC = "TRUE" ]; then
	Rscript $MINQC -i guppy/RTAtrim -o guppy/RTAtrim/qc -p $threads

	# Merge all pngs to one pdf
	# If you get erro "convert: not authorized `MinIONQC.pdf' @ error/constitute.c/WriteImage/1028." you might need to change PDF permissions at /etc/ImageMagick-6/policy.xml to read|write
	convert $(ls guppy/RTAtrim/qc/RTAtrim/*.png) guppy/RTAtrim/qc/MinIONQC.pdf

#	fastqc -o guppy/RTAtrim/qc guppy/RTAtrim/reads.fastq.gz
fi
