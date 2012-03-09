fingerprints <- read.delim("output/p0f_fingerprints/part-r-00000", header=F)

pdf(file="output/p0f_fingerprints/plot.pdf")

plot(fingerprints)
