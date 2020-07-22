#
# Extract intron lengths (only to the screen)
# R --no-save < intron-length.R --args SIRVome_isoforms_C_170612a.E2.gtf
#

library(GenomicFeatures)
library(rtracklayer)

args <- commandArgs(trailingOnly=TRUE)
print(args)

#gtf <- makeTxDbFromGFF("/home/joppelt/projects/ribothrypsis/data/external/spikein/sirv/SIRV_Set1_Sequences_170612a/SIRVome_isoforms_C_170612a.gtf.E2.gtf") # Testing
gtf <- makeTxDbFromGFF(args[1]) #change me!
exons <- exonsBy(gtf, by="gene")

#make introns
exons <- reduce(exons)
exons <- exons[sapply(exons, length) > 1]

introns <- lapply(exons, function(x) {
    #Make a "gene" GRange object
    gr = GRanges(seqnames=seqnames(x)[1], ranges=IRanges(start=min(start(x)),
        end=max(end(x))),
        strand=strand(x)[1])
    db = disjoin(c(x, gr))
    ints = db[countOverlaps(db, x) == 0]
    #Add an ID
    if(as.character(strand(ints)[1]) == "-") {
        ints$exon_id = c(length(ints):1)
    } else {
        ints$exon_id = c(1:length(ints))
    }
    ints
})
introns <- GRangesList(introns)
print("All introns")
unlist(width(introns))
print("Shortest intron:")
unlist(width(introns))[unlist(width(introns))==min(unlist(width(introns)))]
print("Longest intron:")
unlist(width(introns))[unlist(width(introns))==max(unlist(width(introns)))]
