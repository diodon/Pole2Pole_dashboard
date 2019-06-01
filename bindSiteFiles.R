### Bid all _dashboard files into a single one
library(fs)
library(readr)
library(dplyr)

baseDataDir =  "../data2/DataAnalysisFiles/"
baseEcosystem = "rocky"

filenames = dir_ls(file.path(baseDataDir, baseEcosystem),  glob="*_dashboard_siteDF.csv")


SitesAll = read_csv(filenames[1])

for (i in 2:length(filenames)) {
  
  print(filenames[i])
  
  Sites.0 = read_csv(filenames[i])
   
  SitesAll = bind_rows(SitesAll, Sites.0)
  
}


## write the binded file
write_csv(path = file.path(baseDataDir, baseEcosystem, "SitesAll.csv"), SitesAll)

