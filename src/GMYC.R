## R code for running GMYC analyses on trees generated with BEAST

library(ape)
library(splits)
tree1<-read.nexus("C:/Users/mikkopen/Desktop/Carabidae_MaxCladeCred.txt")
tree1
is.binary.tree(tree1) #check that the tree is strictly bifurcating
is.ultrametric(tree1) #check that the tree is ultrametric

##run the single threshold model
delimitation <- gmyc(tree1, method="single", interval=c(0, 10))
summary(delimitation)   #show summary results
plot(delimitation)      #plot lineages-through-time and the ultrametric tree
spec.list(delimitation) #show the division of samples into OTUs

##run the multiple threshold model - not used in this study
#test1 <- gmyc(tree1, method="multiple", interval= c(0, 10))
#summary(test1)
#plot(test1)
#spec.list(test1)



