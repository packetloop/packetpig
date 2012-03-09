histo <- read.delim("output/protocol_size_histogram/part-r-00000", header=F)

pdf(file="output/protocol_size_histogram/plot.pdf")

plot(histo)

