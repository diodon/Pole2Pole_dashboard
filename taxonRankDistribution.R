## get taxonomic rank from WoRMS
## for the matched species lists
library(readr)
library(dplyr)
library(fs)
library(worrms)
library(plotly)




## rocky or beach
basedir = "../data2/taxalist/rocky"


taxalist = read_tsv(file.path(basedir, "taxonlistALL_nonduplicated_matched.txt"))
taxalist = taxalist[complete.cases(taxalist$AphiaID),]

taxonRank = as.character()

for (i in 1:nrow(taxalist)){
  print(paste0(i, "--", taxalist$ScientificName[i]))
  
  taxonRank0 = wm_classification(taxalist$AphiaID[i])
  taxonRank = c(taxonRank, taxonRank0$rank[nrow(taxonRank0)])
}

## add ranks
taxalist = cbind(taxalist, data.frame(rank=taxonRank))

## write file
write_tsv(path = file.path(basedir, "taxonlistALL_nonduplicated_taxonomy.csv"), taxalist)


## summarise the results
taxranks = as.data.frame(table(taxalist$rank))

## make a donut
p = taxranks %>% plot_ly(labels = ~Var1, values=~Freq) %>% 
  add_pie(hole=0.6) %>% 
  layout(title = ~paste0("Total number of Taxa: ", length(taxonRank))) 

plotly::config(p,displayModeBar = F) 

