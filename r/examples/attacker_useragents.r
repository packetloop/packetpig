data <- read.csv("output/attacker_useragents/part-r-00000", header=F)

pdf(file="output/attacker_useragents/plot.pdf")
plot(data)
