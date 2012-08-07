#!/usr/bin/r

# This script graphs the output of the script analyse-domains.py

library(reshape2)
library(ggplot2)
library(scales)

data <- read.table('domain-distribution.csv',
                   sep=',',
                   header=TRUE)

sorted.data <- data[order(data$Fine, decreasing=TRUE),]
top.domains <- sorted.data[1:3,]

top.domains$Domain <- paste(top.domains$Domain,
                            "\n(",
                            (top.domains$Fine +
                             top.domains$UnconfirmedNotBounced +
                             top.domains$Bounced), ")",
                            sep='')

datm <- melt(cbind(top.domains,
                   ind=rownames(top.domains)),
             is.vars=c('Legend'))

datm <- melt(top.domains)

ggplot(datm, aes(x = Domain,y = value, fill = variable)) +
  geom_bar(position = "fill") +
  scale_y_continuous(labels = percent_format())
