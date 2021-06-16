#!/usr/bin/env Rscript
#
# Fix gtf - renames duplicates transcript names and adds missing biotypes
# Designed to fix NCBI sc3 gtf annotation
#

library("optparse")
suppressPackageStartupMessages(library("dplyr"))
suppressPackageStartupMessages(library("rtracklayer"))

# Read command line options and arguments
option_list <- list(
  make_option(
    c("-i", "--input"),
    type = "character",
    help = "Gene annotation in GTF to fix. Can be gzipped.", metavar = "File"
  ),
  make_option(
    c("-o", "--output"),
    type = "character", default="stdout",
    help = "Fixed GTF (with renamed duplicated transcript_ids and added missing biotypes). Default: stdout.", metavar = "File"
  )
)
opt <- parse_args(OptionParser(option_list = option_list))

### TESTING VARIABLES ###
#print("USING TESTING VARIABLES!!!")
#opt<-NULL
#opt$input<-"/home/joppelt/projects/rna_degradation/data/sc3/GCF_000146045.2_R64_genomic.gtf.gz"
#opt$output<-"/home/joppelt/projects/rna_degradation/data/sc3/GCF_000146045.2_R64_genomic.fixed.gtf"
#print("USING TESTING VARIABLES!!!")
### TESTING VARIABLES ###

if(opt$input=="stdin"){
  gtf <- import(stdin(), format="gtf")
}else{
  gtf <- import(opt$input, format="gtf")
}

### Fix duplicated transcript names
# Get duplicated transcripts names
dupls <- gtf %>%
  as.data.frame() %>%
  select(gene_id, transcript_id) %>%
  filter(!is.na(transcript_id)) %>%
  distinct() %>%
  group_by(transcript_id) %>%
  summarise(counts = n()) %>%
  filter(counts > 1)

dupls <- gtf %>%
  as.data.frame() %>%
  select(gene_id, transcript_id) %>%
  distinct() %>%
  filter(transcript_id %in% dupls$transcript_id)

# Get new duplicated transcript name
dupls<-dupls %>%
  group_by(transcript_id) %>%
  mutate(seqs=seq(1, n(),by=1)) %>%
  mutate(transcript_id_repl=paste(transcript_id, seqs, sep="_"))

# Rename duplicated transcript_ids
df <- as.data.frame(gtf)
df <- df %>%
  left_join(dupls)

index<-!is.na(df$transcript_id_repl)
gtf$transcript_id[index]<-df$transcript_id_repl[index]

### Fix missing gene biotypes
biotypes <- gtf %>%
  as.data.frame() %>%
  select(gene_id, gene_biotype) %>%
  filter(!is.na(gene_biotype)) %>%
  distinct()

df <- as.data.frame(gtf)
df <- df %>%
  select(-gene_biotype) %>%
  left_join(biotypes)

gtf$gene_biotype<-df$gene_biotype

### Fix missing transcript_biotypes
# IMPORTANT: We cannot make up transcript biotypes, we can only do the same as for gene biotypes - copy biotype if it exists in some lines but not in the other
if("transcript_biotype" %in% names(gtf@elementMetadata)){
  biotypes <- gtf %>%
    as.data.frame() %>%
    select(gene_id, transcript_biotype) %>%
    filter(!is.na(transcript_biotype)) %>%
    distinct()

  df <- as.data.frame(gtf)
  df <- df %>%
    select(-transcript_biotype) %>%
    left_join(biotypes)

  gtf$transcript_biotype<-df$transcript_biotype
}

if(opt$output=="stdout"){
  export(gtf, stdout(), format = "gtf")
}else{
  export(gtf, opt$output, format = "gtf")
}

