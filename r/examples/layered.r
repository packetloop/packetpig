library(ggplot2)
data <- data.frame(V1 <- rnorm(700), V2=sample(LETTERS[1:3], 700, replace=TRUE))
ggplot(data, aes(x=V1)) +
stat_bin(aes(y=..density..)) + 
stat_function(fun=dnorm) + 
facet_grid(V2~.)
