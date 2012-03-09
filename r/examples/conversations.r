library("zoo")
library("xts")
library("ggplot2")

conversations <- read.csv("output/conversations/part-r-00000", header=F)

pdf(file="output/conversations/plot.pdf")

plot(conversations)
