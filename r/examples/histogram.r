histo <- read.delim("output/histogram/part-r-00000", header=F)

pdf(file="output/histogram/plot.pdf")

hist(histo$V1, breaks=50)
