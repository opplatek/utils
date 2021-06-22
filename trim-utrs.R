#!/usr/bin/env Rscript
#
# Trim UTR regions from exons so we have 'clean' coding exons only
# Added as "coding_exon" in the third column
#
# TODO TODO TODO
# change exon number to follow the new coding_exon - there might be some missing exons especially at the beginning if they are fully overlapped by utr
# TODO TODO TODO

library("optparse")
suppressPackageStartupMessages(library("data.table"))
suppressPackageStartupMessages(library("GenomicFeatures"))
suppressPackageStartupMessages(library("rtracklayer"))

option_list <- list(
  make_option(
    c("-g", "--gtf"), type = "character",
    help = "Input GTF, preferably Ensembl.", metavar = "File"),
  make_option(
    c("-o", "--ofile"), type = "character",
    help = "Output GTF with added \"coding_exon\" representing exons with trimmed UTRs.", metavar = "File")
)
opt = parse_args(OptionParser(option_list = option_list))

####################################################################################################
# print("TESTING VARIABLES!!!")
# opt<-NULL
# opt$gtf<-"/home/joppelt/projects/rna_degradation/data/hg38/Homo_sapiens.GRCh38.100.sorted.gtf.bckp"
# opt$ofile<-"/home/joppelt/projects/rna_degradation/data/hg38/Homo_sapiens.GRCh38.100.sorted.gtf.bckp.test"
# print("TESTING VARIABLES!!!")
####################################################################################################

txdb = makeTxDbFromGFF(opt$gtf, format = "gtf")

exon <- exonsBy(txdb, by="tx", use.names=T)
utr5p <- fiveUTRsByTranscript(txdb, use.names=T)
utr3p <- threeUTRsByTranscript(txdb, use.names=T)
cds <- cdsBy(txdb, by="tx", use.names=T) # get only coding part of the exons = remove UTRs

#utr3p$ENST00000420190
#utr5p$ENST00000420190
#ds$ENST00000420190
#exon$ENST00000420190

gtf <- rtracklayer::import(opt$gtf, format="gtf")
gtf.dt <- as.data.table(gtf)
gtf.dt.exon <- gtf.dt[type=="exon"] # get only exon
#gtf.dt.rest <- gtf.dt[type!="exon"] # get everything else

cds.dt <- as.data.table(cds)
cds.dt <- cds.dt[, c("group_name", "start", "end", "exon_rank")] # keep only columns we need

gtf.dt.exon[, new:=paste(transcript_id, exon_number, sep=".")] # Make replacement id
cds.dt[, new:=paste(group_name, exon_rank, sep=".")] # Make replacement id

gtf.dt.exon <- merge(gtf.dt.exon, cds.dt, by = "new", all.x = T)

gtf.dt.exon <- na.omit(gtf.dt.exon, cols="group_name") # remove exons which do not have an alternative in CDS
gtf.dt.exon[, start.x := start.y] # update start/end by the cds
gtf.dt.exon[, end.x := end.y]
setnames(gtf.dt.exon, c("start.x", "end.x"), c("start", "end")) # rename
gtf.dt.exon[, c("group_name", "start.y", "end.y", "exon_rank", "new") := NULL] # clean

gtf.dt.exon[, type:="coding_exon"] # change exon column to coding_exon
# TODO TODO TODO
# change exon number to follow the new coding_exon - there might be some missing exons especially at the beginning if they are fully overlapped by utr
# TODO TODO TODO

print("Basic length statistics")
print("Exons")
quantile(unlist(width(exon)))
print("5 UTRs")
quantile(unlist(width(utr5p)))
print("3 UTRs")
quantile(unlist(width(utr3p)))
print("Coding exons")
quantile(unlist(width(cds)))

gtf.out <- rbindlist(list(gtf.dt.exon, gtf.dt)) # add new lines to the original gtf
gtf.out <- gtf.out[order(seqnames, start)] # sort

# Check
# write.table(gtf.out[transcript_id=="ENST00000379409" & type %in% c("five_prime_utr", "three_prime_utr", "exon", "coding_exon")], sep=",", row.names=F)

gtf.out.granges <- makeGRangesFromDataFrame(gtf.out, keep.extra.columns=TRUE, ignore.strand=FALSE) # make the granges for easier exprort
rtracklayer::export(gtf.out.granges, opt$ofile) # Export final gtf
