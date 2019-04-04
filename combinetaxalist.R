## combine worms matched files
library(readr)
library(dplyr)
library(fs)



## rocky or beach
basedir = "../data2/taxalist/rocky"

filenames = dir_ls(path = basedir, regexp = "txt")


matchednames = read_tsv(filenames[1])

for (i in 2: length(filenames)){
  print(paste0(i, " - ", filenames[i]))
  
  matchednames0 = read_tsv(filenames[i])
  
  ## remove lines with NAs in case the match is not complete
  matchednames0 = matchednames0[!is.na(matchednames0$AphiaID_accepted),]
  matchednames0$AphiaID = as.integer(matchednames0$AphiaID)
  
  ## bind DFs
  matchednames = bind_rows(matchednames, matchednames0)
  
}

## order and cur non interesting columns
matchednames = matchednames[order(matchednames$ScientificName),1:7]
matchednames = matchednames[complete.cases(matchednames),]

## remove complete duplicates
matchednames = matchednames[!duplicated(matchednames),]

## remove accepted Aphia ID duplicates
matchednames.uniqueAphia = matchednames[!duplicated(matchednames$AphiaID_accepted),]


## write file
write_tsv(path = file.path(basedir, "taxonlistALL.csv"), matchednames)
write_tsv(path = file.path(basedir, "taxonlistALL_nonduplicated.csv"), matchednames.uniqueAphia)



