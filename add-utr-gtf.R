#!/usr/bin/env Rscript
#
# Adds 'fake' 5' UTR and 3' UTR by extending specified number of nt before/after start/stop codon
# Very simple, primarily done for one of the yeast projects
#
# TODO: Add chromosome overflow protection

library("optparse")
suppressPackageStartupMessages(library("dplyr"))
suppressPackageStartupMessages(library("rtracklayer"))

# Read command line options and arguments
option_list <- list(
  make_option(
    c("-i", "--input"),
    type = "character",
    help = "Gene annotation in GTF to add the UTRs to.", metavar = "File"
  ),
  make_option(
    c("-f", "--five_utr"),
    type = "integer", default = 50,
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
    help = "GTF with added UTRs (as three_prime_utr, five_prime_utr, and exons)", metavar = "File"
  )
)
opt <- parse_args(OptionParser(option_list = option_list))

### TESTING VARIABLES ###
# opt<-NULL
# opt$five_utr<-50
# opt$three_utr<-100
# opt$input<-"/home/jan/projects/mourelatos11/projects/rna_degradation/data/sc3/genes.gtf"
# opt$output<-"/home/jan/projects/mourelatos11/projects/rna_degradation/data/sc3/genes.withUtr.gtf"
# genome_size<-"/home/jan/projects/mourelatos11/projects/rna_degradation/data/sc3/genome/genome.fa.fai"
### TESTING VARIABLES ###

gtf <- import(opt$input, format = "gtf")

# Extend 5'UTR and 3'UTR by 150 bp upstream (5' UTR) or downstream (3' UTR); https://support.bioconductor.org/p/78652/
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

#other <- gtf[gtf$type != "start_codon" & gtf$type != "stop_codon"]
other <- gtf # keep the original annotation to shift the exon numbers

plus_start <- gtf[strand(gtf) == "+" & gtf$type == "start_codon"]
minus_start <- gtf[strand(gtf) == "-" & gtf$type == "start_codon"]
plus_stop <- gtf[strand(gtf) == "+" & gtf$type == "stop_codon"]
minus_stop <- gtf[strand(gtf) == "-" & gtf$type == "stop_codon"]

# Fix gbkey if exists not to confuse us
if(any(colnames(gtf@elementMetadata) == "gbkey")){
  plus_start$gbkey<-"mRNA"
  minus_start$gbkey<-"mRNA"
  plus_stop$gbkey<-"mRNA"
  minus_stop$gbkey<-"mRNA"
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
utr5$exon_number<-1
# Shift by 1 for 5' UTRs
shift<-other$exon_number[other$gene_id %in% unique(utr5$gene_id)]
shift[!is.na(shift)]<-as.character(as.numeric(shift[!is.na(shift)])+1)
other$exon_number[other$gene_id %in% unique(utr5$gene_id)]<-shift

# Assign 3' UTRs
# Please note genes with 5'UTRs and 3'UTRs don't have to be the same; sometimes one of the start/stop codons is not annotated
# Get highest exon number for each genes and set 3' UTR as +1
exon_num<-as.data.frame(other[other$gene_id %in% unique(utr3$gene_id), c("gene_id", "exon_number")])
exon_num<-unique(exon_num[, c("gene_id", "exon_number")])
exon_num<-exon_num[!is.na(exon_num$exon_number),]
exon_max<-exon_num %>% 
  group_by(gene_id) %>% 
  top_n(n=1) %>%
  dplyr::rename(exon_number_max = exon_number)

shift<-left_join(as.data.frame(utr3), exon_max)
shift<-shift$exon_number_max
shift[!is.na(shift)]<-as.character(as.numeric(shift[!is.na(shift)])+1)
utr3$exon_number<-shift

utrs <- c(utr5, utr3)
exons <- utrs
exons$type <- "exon"
utrs$exon_number<-NA

# Merge all the parts and export
out <- c(other, utrs, exons)

out <- sortSeqlevels(out)
out <- sort(out, ignore.strand = TRUE)

export(out, opt$output, format = "gtf")
