#!/usr/bin/env Rscript
#
# Fix gtf - renames duplicates transcript names; adds missing biotypes; remove semicolon
#   in description fields; removes CDS/codons (start, stop) which are not covered by exons (assuming exons
#   are correct and CDS/codons might not be - not extending/making new exons to cover CDS if missing)
#
# Designed to fix NCBI sc3 gtf annotation
#
# TODO: Check if there are more than one CDS per exon and if so merge them to one (like NM_001179028.4)
#         if they are correct
# TODO: Fix stop codons to be the last codons of CDS (fix above might do)
# NOTE: Right now the problems above are exported to a separate file which can be 'fixed' manually
#         In yeast, the CDSs in question are usually split by 2nt so I assume they should be merged
#
#2: In .find_exon_cds(exons, cds) :
#  The following transcripts have exons that contain more than one CDS
#  (only the first CDS was kept for each exon): NM_001178666.2,
#  NM_001179028.4, NM_001179050.4, NM_001180048.2, NM_001180050.2,
#  NM_001180056.2, NM_001180862.2, NM_001181431.2, NM_001181434.4,
#  NM_001181546.3, NM_001181685.2, NM_001181687.2, NM_001182397.2,
#  NM_001182402.2, NM_001182542.2, NM_001182547.2, NM_001183658.6,
#  NM_001183866.4, NM_001184306.2, NM_001184379.4, NM_001184381.2,
#  NM_001184384.2, NM_001184386.2, NM_001184388.4, NM_001184390.4,
#  NM_001184392.2, NM_001184394.2, NM_001184396.2, NM_001184398.2,
#  NM_001184400.4, NM_001184402.2, NM_001184404.2, NM_001184406.2,
#  NM_001184408.2, NM_001184411.4, NM_001184415.2, NM_001184417.2,
#  NM_001184419.4, NM_001184421.2, NM_001184423.4, NM_001184425.2,
#  NM_001184427.2, NM_001184432.2, NM_001184434.2, NM_001184436.2,
#  NM_001281536.2, NM_001305015.2
#3: In .reject_transcripts(bad_tx, because) :
#  The following transcripts were rejected because they have incompatible
#  CDS and stop codons: NM_001178666.2, NM_001180048.2, NM_001180050.2,
#  NM_001180056.2, NM_001180862.2, NM_001181434.4, NM_001181546.3,
#  NM_001181685.2, NM_001181687.2, NM_001182397.2, NM_001182402.2,
#  NM_001183658.6, NM_001183866.4, NM_001184381.2, NM_001184384.2,
#  NM_001184386.2, NM_001184390.4, NM_001184392.2, NM_001184398.2,
#  NM_001184402.2, NM_001184404.2, NM_001184408.2, NM_001184411.4,
#  NM_001184419.4, NM_001184423.4, NM_001184425.2, NM_001184427.2,
#  NM_001184432.2, NM_001281536.2
#

library("optparse")
suppressPackageStartupMessages(library("dplyr"))
#suppressPackageStartupMessages(library("GenomicRanges")) # loaded by rtracklayer
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

#length(gtf)

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

# Remove ";" in the metafield - causes problems with some software because they think it's a new field
#gtf@elementMetadata<-as.data.frame(apply(gtf@elementMetadata, 2, function(x) gsub(";", ",", x))) # Doesn't work because it's not possible to assign data.frame to S4 - we have to go column by column
df <- as.data.frame(gtf@elementMetadata)
df<-as.data.frame(apply(df, 2, function(x) gsub(";", ",", x)))
for(col in colnames(df)){
  gtf@elementMetadata[col]<-df[col]
}

# Remove CDS/codons which are not covered by exons either by overlap or the gene/transcript doesn't have any annotated exons (shouldn't happen but does)
# Note: In sc3 annotation, these are mostly "unknown_transcript" with annotated CDS but without annotated exon
# TODO: Consider only exons from the particular transcript, not all of them - see below about how to approach it with GRangesList
noncds<-gtf[!(gtf$transcript_id %in% gtf[gtf$type=="CDS"]$transcript_id)] # get overall non-cds trancripts (like ncRNA) and set them aside

cds<-gtf[gtf$transcript_id %in% gtf[gtf$type=="CDS"]$transcript_id] # get the rest = transcripts which have cds

codons<-subsetByOverlaps(cds[cds$type=="CDS" | cds$type=="start_codon" | cds$type=="stop_codon"], 
                         cds[cds$type=="exon"], type="within", ignore.strand=FALSE) # get cds, start, stop codons with overlap
codons<-codons[codons$transcript_id %in% cds[cds$type=="exon"]$transcript_id] # get cds, start, stop codons from genes which have exons (hopefully this was the overlap)

cds_overl_error <- cds[!(cds$transcript_id %in% codons$transcript_id)] # Get removed rows/genes/transcripts for additional QC (might be genes with CDS but without exon)

gtf<-gtf[gtf$transcript_id %in% codons$transcript_id & !(gtf$type=="CDS" | gtf$type=="start_codon" | gtf$type=="stop_codon")]  # get everything else but cds, start and stop codon (we don't care about this at this time)
gtf <- c(gtf, codons) # merge good cds, start, stop codon with everything but cds, start, stop codons

#length(gtf) + length(cds_overl_error) # should be equal to the initial gtf length

# Test for split CDS
# tests<-c("NM_001179028.4", "NM_001179050.4", "NM_001180048.2", "NM_001180050.2",
# "NM_001180056.2", "NM_001180862.2", "NM_001181431.2", "NM_001181434.4",
# "NM_001181546.3", "NM_001181685.2", "NM_001181687.2", "NM_001182397.2",
# "NM_001182402.2", "NM_001182542.2", "NM_001182547.2", "NM_001183658.6",
# "NM_001183866.4", "NM_001184306.2", "NM_001184379.4", "NM_001184381.2",
# "NM_001184384.2", "NM_001184386.2", "NM_001184388.4", "NM_001184390.4",
# "NM_001184392.2", "NM_001184394.2", "NM_001184396.2", "NM_001184398.2",
# "NM_001184400.4", "NM_001184402.2", "NM_001184404.2", "NM_001184406.2",
# "NM_001184408.2", "NM_001184411.4", "NM_001184415.2", "NM_001184417.2",
# "NM_001184419.4", "NM_001184421.2", "NM_001184423.4", "NM_001184425.2",
# "NM_001184427.2", "NM_001184432.2", "NM_001184434.2", "NM_001184436.2",
# "NM_001281536.2", "NM_001305015.2")

#gtf$rows<-seq(1,length(gtf),by=1) # helper column
#grl<-split(gtf, gtf$transcript_id) # split to granges list
#names(grl)
# grl$NM_001179028.4
# gtf_tmp<-unlist(grl)
# gtf<-c(gtf_tmp, gtf[!(gtf$rows %in% gtf_tmp$rows)])

# Get transcript names where number of exons != number of CDS
# Note: In sc3 annotation, these are mostly genes with CDS split into two halves separated by just a couple of nucleotides (not sure why)
exons <- gtf %>% 
  as.data.frame() %>% 
  select(transcript_id, type) %>%
  filter(!is.na(transcript_id)) %>% 
  group_by(transcript_id) %>%
  add_tally(type=="exon", name="exon") %>%
  add_tally(type=="CDS", name="CDS") %>%
  filter(exon!=CDS) %>%
  pull(transcript_id) %>% 
  unique()

cds_num_error<-gtf[gtf$transcript_id %in% exons]
gtf<-gtf[!(gtf$transcript_id %in% exons)]

gtf<-c(gtf, noncds) # put back non-CDS transcripts/rows

# Sort the result
if(length(cds_overl_error)>0){
    cds_overl_error <- sortSeqlevels(cds_overl_error)
    cds_overl_error <- sort(cds_overl_error, ignore.strand = TRUE)
}

if(length(cds_num_error)>0){
    cds_num_error <- sortSeqlevels(cds_num_error)
    cds_num_error <- sort(cds_num_error, ignore.strand = TRUE)
}

gtf <- sortSeqlevels(gtf)
gtf <- sort(gtf, ignore.strand = TRUE)

#length(gtf) + length(cds_overl_error) + length(cds_num_error) # should be equal to the initial gtf length

if(opt$output=="stdout"){
  export(gtf, stdout(), format = "gtf")
  export(c(cds_overl_error, cds_num_error), stderr(), format = "gtf") # export removed rows for QC
}else{
  export(gtf, opt$output, format = "gtf")
  export(cds_overl_error, gsub(".gtf", ".cds_overl-issues.gtf", opt$output), format = "gtf") # export removed rows for QC
  export(cds_num_error, gsub(".gtf", ".cds_numb-issues.gtf", opt$output), format = "gtf") # export removed rows for QC
}

