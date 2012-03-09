library("ggplot2")

dns <- read.csv("output/dns_response_ttl/part-r-00000", header=F)

pdf(file="output/dns_response_ttl/plot.pdf")

ggplot(dns, aes(x=dns$V2, y=dns$V1)) + geom_point(shape=4)
ggplot(dns, aes(x=dns$V2, y=dns$V3)) + geom_point(shape=4)
ggplot(dns, aes(x=dns$V2, y=dns$V3)) + geom_point(shape=4) + facet_grid(V1~.)
qplot(x=dns$V2, stat='density', geom='line', ylab="Density")
