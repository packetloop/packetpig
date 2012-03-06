library("zoo")
library("xts")
library("ggplot2")

bandwidth <- read.csv("../../out/bandwidth/part-r-00000", header=F)

z_bandwidth <- zoo(bandwidth$V2/(1024*1024), as.POSIXlt(bandwidth$V1,origin="1970-01-01", tz="GMT"))

plot(z_bandwidth,title="Bandwidth in MB/s",ylab="MB's")
hist(z_bandwidth/(1024*1024), breaks=100,xlab="MB/s")
qplot(x=bandwidth$V2/(1024*1024), stat='density', geom='line', ylab="Density")
