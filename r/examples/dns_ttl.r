library("ggplot2")

dns <- read.csv("../../out/dns/ttl/part-r-00000", header=F)

ggplot(dns, aes(x=dns$V2, y=dns$V1)) + geom_point(shape=4)
ggplot(dns, aes(x=dns$V2, y=dns$V3)) + geom_point(shape=4)
ggplot(dns, aes(x=dns$V2, y=dns$V3)) + geom_point(shape=4) + facet_grid(V1~.)
qplot(x=dns$V2, stat='density', geom='line', ylab="Density")
