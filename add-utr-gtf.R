#!/usr/bin/env Rscript
#
# Adds 'fake' 5' UTR and 3' UTR by extending specified number of nt before/after start/stop codon
# The UTR nucleotides are added to first/last annotated exon, not as separate exons (there is no 
#   intron in between so it shouldn't be a separate exon)
# Very simple, primarily done for one of the yeast projects
#
# IMPORTANT: This might (and will in compact genomes) cause overlapping regions!
#
# TODO: Disallow overlapping of UTRs with other UTRs or exons - but how to decide what is correct UTR and what's not?
#

library("optparse")
suppressPackageStartupMessages(library("dplyr"))
#suppressPackageStartupMessages(library("GenomicRanges")) # loaded by rtracklayer
suppressPackageStartupMessages(library("rtracklayer"))

# Function to extend 5'UTR and 3'UTR by xx bp upstream (5' UTR) or downstream (3' UTR); https://support.bioconductor.org/p/78652/
extend <- function(x, upstream = 0, downstream = 0) {
  if (any(strand(x) == "*")) {
    warning("'*' ranges were treated as '+'")
  }
  on_plus <- strand(x) == "+" | strand(x) == "*"
  new_start <- start(x) - ifelse(on_plus, upstream, downstream)
  new_end <- end(x) + ifelse(on_plus, downstream, upstream)
  ranges(x) <- IRanges(new_start, new_end)
  trim(x)
}

# Read command line options and arguments
option_list <- list(
  make_option(
    c("-i", "--input"),
    type = "character",
    help = "Gene annotation in GTF to add the UTRs to.", metavar = "File"
  ),
  make_option(
    c("-f", "--five_utr"),
    type = "integer", default = 100,
    help = "Make 5'UTRs of this size (from start codon).", metavar = "Integer"
  ),
  make_option(
    c("-t", "--three_utr"),
    type = "integer", default = 100,
    help = "Make 3'UTRs of this size (from stop codon)", metavar = "Integer"
  ),
  make_option(
    c("-o", "--output"),
    type = "character",
    help = "GTF with added UTRs (as three_prime_utr, five_prime_utr, and exons)", metavar = "File",
  ),
    make_option(
      c("-g", "--gen_ind"),
      type = "character",
      help = "Chromosome sizes (chr\tchr_size). For example .fai from samtools faidx.", metavar = "File"  
  )
)
opt <- parse_args(OptionParser(option_list = option_list))

### TESTING VARIABLES ###
 # opt<-NULL
 # opt$five_utr<-100
 # opt$three_utr<-100
 # opt$input<-"/home/jan/projects/mourelatos11/projects/rna_degradation/data/sc3/GCF_000146045.2_R64_genomic.gtf.gz"
 # opt$output<-"/home/jan/projects/mourelatos11/projects/rna_degradation/data/sc3/GCF_000146045.2_R64_genomic.withUtr.gtf"
 # opt$gen_ind<-"/home/jan/projects/mourelatos11/projects/rna_degradation/data/sc3/genome/genome.fa.fai"
### TESTING VARIABLES ###

gtf <- rtracklayer::import(opt$input, format = "gtf")
length(gtf)
gtf$rows<-seq(1:length(gtf)) # add a helper column to copy back all the missing rows at the end
gtf.bckp<-gtf
#other <- gtf[gtf$type != "start_codon" & gtf$type != "stop_codon"]
#nas<-gtf[is.na(gtf$transcript_id)] # Remove NAs (will be added later), whatever it is
gtf<-gtf[!is.na(gtf$transcript_id)]
#other <- gtf # keep the original annotation to shift the exon numbers

gen_ind <- read.table(opt$gen_ind, stringsAsFactors = F, header = F) # chrom length is V2
gen_ind <- gen_ind[, c(1,2)]
colnames(gen_ind)<-c("seqnames", "chr_end")

plus_start <- gtf[strand(gtf) == "+" & gtf$type == "start_codon"]
minus_start <- gtf[strand(gtf) == "-" & gtf$type == "start_codon"]
plus_stop <- gtf[strand(gtf) == "+" & gtf$type == "stop_codon"]
minus_stop <- gtf[strand(gtf) == "-" & gtf$type == "stop_codon"]

# Fix gbkey if exists not to confuse us
if(any(colnames(gtf@elementMetadata) == "gbkey")){
  plus_start$gbkey <- "mRNA"
  minus_start$gbkey <- "mRNA"
  plus_stop$gbkey <- "mRNA"
  minus_stop$gbkey <- "mRNA"
}

utr5_plus <- extend(plus_start[plus_start$type == "start_codon", ], upstream = opt$five_utr, downstream = 0)
end(utr5_plus) <- start(plus_start) - 1
utr5_minus <- extend(minus_start[minus_start$type == "start_codon", ], upstream = opt$five_utr, downstream = 0)
start(utr5_minus) <- end(minus_start) + 1
utr5 <- c(utr5_plus, utr5_minus)

utr3_plus <- extend(plus_stop[plus_stop$type == "stop_codon", ], upstream = 0, downstream = opt$three_utr)
start(utr3_plus) <- end(plus_stop) + 1
utr3_minus <- extend(minus_stop[minus_stop$type == "stop_codon", ], upstream = 0, downstream = opt$three_utr)
end(utr3_minus) <- start(minus_stop) - 1
utr3 <- c(utr3_plus, utr3_minus)

utr5$type <- "five_prime_utr"
utr3$type <- "three_prime_utr"

# Assign exon numbers for better compatibility
# Assign 5' UTR as exon no 1
# utr5$exon_number<-1
# # Shift of other exons by 1 for 5' UTRs
# shift<-other$exon_number[other$transcript_id %in% unique(utr5$transcript_id)]
# shift[!is.na(shift)]<-as.character(as.numeric(shift[!is.na(shift)])+1)
# other$exon_number[other$transcript_id %in% unique(utr5$transcript_id)]<-shift

# # Assign 3' UTRs
# # Please note genes with 5'UTRs and 3'UTRs don't have to be the same; sometimes one of the start/stop codons is not annotated
# # Get highest exon number for each genes and set 3' UTR as +1
# exon_num<-as.data.frame(other[other$transcript_id %in% unique(utr3$transcript_id), c("transcript_id", "exon_number")])
# exon_num<-unique(exon_num[, c("transcript_id", "exon_number")])
# exon_num<-exon_num[!is.na(exon_num$exon_number),]
# exon_max<-exon_num %>%
#   group_by(transcript_id) %>%
#   top_n(n=1) %>%
#   dplyr::rename(exon_number_max = exon_number)

# shift<-left_join(as.data.frame(utr3), exon_max)
# shift<-shift$exon_number_max
# shift[!is.na(shift)]<-as.character(as.numeric(shift[!is.na(shift)])+1)
# utr3$exon_number<-shift

print("Number of potentially overlapping UTRs (5UTRs, 3UTRs, 5&3UTRs")
findOverlaps(utr5, utr5) %>% 
  as.data.frame() %>% 
  filter(queryHits != subjectHits) %>%
  nrow()
findOverlaps(utr3, utr3) %>% 
  as.data.frame() %>% 
  filter(queryHits != subjectHits) %>%
  nrow()
findOverlaps(utr5, utr3) %>% 
  as.data.frame() %>% 
  filter(queryHits != subjectHits) %>%
  nrow()

utrs <- c(utr5, utr3)
# exons <- utrs
# exons$type <- "exon"
utrs$exon_number<-NA
utrs$rows<-NA # it inherited row numbers from start/stop codon, we don't want that because we use it to get missing rows at the end

# Get genes with annotated start/stop codong for exon extension
cds <- gtf[gtf$transcript_id %in% c(plus_start$transcript_id, minus_start$transcript_id, plus_stop$transcript_id, minus_stop$transcript_id)]
#other <- other[!other$transcript_id %in% cds$transcript_id] # remove transcript lines included in cds from other in order not to duplicate regions
cds <- cds[cds$type=="exon"] # get only exons

# 5 UTR on + & 3 UTR on - (first exons)
# Extend first exon by opt$five_utr and last by opt$three_utr
# start(cds[strand(cds) == "+" & cds$exon_number==1]) <- start(cds[strand(cds) == "+" & cds$exon_number==1]) - opt$five_utr # on plus strand, shift 1. exon (actual 1. exon) by 5utr
# start(cds[strand(cds) == "-" & cds$exon_number==1]) <- start(cds[strand(cds) == "-" & cds$exon_number==1]) - opt$three_utr # on minus strand, shift 1. exon (last exon) by 3utr
cds[cds$exon_number==1] <- extend(cds[cds$exon_number==1], upstream = opt$five_utr, downstream = 0)

# 3 UTR on + & 5 UTR on - (last exons)
cds$exon_number_max<-cds %>%
  as.data.frame() %>%
  group_by(transcript_id) %>%
  mutate(exon_number_max=max(exon_number)) %>%
  ungroup() %>%
  pull(exon_number_max) # pull() - get vector from tibble

#end(cds[strand(cds) == "+" & cds$exon_number==cds$exon_number_max]) <- end(cds[strand(cds) == "+" & cds$exon_number==cds$exon_number_max]) + opt$three_utr # on plus strand, shift last exon (actual last exon) by 3utr
#end(cds[strand(cds) == "-" & cds$exon_number==cds$exon_number_max]) <- end(cds[strand(cds) == "-" & cds$exon_number==cds$exon_number_max]) + opt$five_utr # on minus strand, shift last exon (1. exon) by 5utr
cds[cds$exon_number==cds$exon_number_max] <- extend(cds[cds$exon_number==cds$exon_number_max], upstream = 0, downstream = opt$three_utr)

cds$exon_number_max<-NULL

# Merge all the parts and export
#out <- c(other, utrs, exons) # Adding UTRs as both UTR and exon
out <- c(cds, utrs)
out<-c(out, gtf.bckp[!(gtf.bckp$rows %in% out$rows)]) # put back all the rows we have left behind
print("If TRUE the UTRs were added correctly (by number of rows)")
length(gtf.bckp)+length(utrs)==length(out) # does original annotation + new utr rows equal to the total number of rows?
out$rows<-NULL

# Fix chromosome overflowing
start(out)[start(out)<0]<-1

out$chr_end <- out %>% 
  as.data.frame() %>% 
  left_join(gen_ind) %>% 
  pull(chr_end)
end(out)[end(out)>out$chr_end]<-out$chr_end[end(out)>out$chr_end]
out$chr_end<-NULL

# Sort the result
out <- sortSeqlevels(out)
out <- sort(out, ignore.strand = TRUE)

rtracklayer::export(out, opt$output, format = "gtf")
