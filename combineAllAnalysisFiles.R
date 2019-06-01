## bind all analysis files (siteDF, occurrence) in a master file
library(readr)
library(dplyr)


baseDataDir =  "../data2"
baseEcosystem = "rocky"

datafileNames.sites = dir_ls(file.path(baseDataDir, "DataAnalysisFiles", baseEcosystem), glob = "*DF.csv")
datafileNames.occurrence = dir_ls(file.path(baseDataDir, "DataAnalysisFiles", baseEcosystem), glob = "*occurrence.csv")

nFiles = length(datafileNames.sites)

## open first files
siteAll = read.csv(datafileNames.sites[1])
occurrenceAll = read.csv(datafileNames.occurrence[1])

  
for (i in 2:nFiles){
  print(paste0(i, "-", datafileNames.occurrence[i]))
  
  siteAll = bind_rows(siteAll, read.csv(datafileNames.sites[i]))
  occurrenceAll = bind_rows(occurrenceAll, read.csv(datafileNames.occurrence[i]))
  
  
}

write_csv(path=file.path(baseDataDir, "DataAnalysisFiles", baseEcosystem, "siteAll.csv"), siteAll)
write_csv(path=file.path(baseDataDir, "DataAnalysisFiles", baseEcosystem, "occurrenceAll.csv"), occurrenceAll)
