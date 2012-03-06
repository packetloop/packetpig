library("zoo")
library("xts")
library("ggplot2")

attacks <- read.csv("../../out/snort/distinct/part-r-00000", header=F)

z_attacks <- zoo(attacks$V6, as.POSIXlt(attacks$V1,origin="1970-01-01", tz="GMT"))

plot(z_attacks,title="Time",ylab="Attacks")
points(z_attacks, col='blue', pch=20, cex=1)
qplot(x=attacks$V6, stat='density', geom='line', xlab="No of Attacks per bin period",ylab="Density")
