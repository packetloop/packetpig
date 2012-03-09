library("zoo")
library("xts")

bins <- read.csv("output/binning/part-r-00000", header=F)
z_tcp_data <- zoo(bins$V2/(1024*1024), as.POSIXlt(bins$V1,origin="1970-01-01", tz="GMT"))
z_udp_data <- zoo(bins$V3/(1024*1024), as.POSIXlt(bins$V1,origin="1970-01-01", tz="GMT"))
z_tot_data <- zoo(bins$V4/(1024*1024), as.POSIXlt(bins$V1,origin="1970-01-01", tz="GMT"))

pdf(file="output/binning/plot.pdf")

plot(z_tcp_data, col=2)
lines(z_udp_data, col=3)
lines(z_tot_data, col=5)
