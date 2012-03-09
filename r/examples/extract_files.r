files <- read.delim("output/extract_files/part-m-00000", header=F)

pdf(file="output/extract_files/plot.pdf")

plot(files$V12)
