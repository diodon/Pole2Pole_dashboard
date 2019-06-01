### Bid all _dashboard files into a single one
library(fs)
library(readr)
library(dplyr)

baseDataDir =  "../data2/DataAnalysisFiles/"
baseEcosystem = "beach"

filenames = dir_ls(file.path(baseDataDir, baseEcosystem),  glob="*_beach_occurrence.csv")


OccurrenceAll = read_csv(filenames[1])

OccurrenceAll$abundance = as.numeric(OccurrenceAll$abundance)
OccurrenceAll$Country = as.character(OccurrenceAll$Country)
OccurrenceAll$City = as.character(OccurrenceAll$City)
OccurrenceAll$Beach = as.character(OccurrenceAll$Beach)

for (i in 2:length(filenames)) {
  
  print(filenames[i])
  
  Occurrence.0 = read_csv(filenames[i])
  Occurrence.0$abundance = as.numeric(Occurrence.0$abundance)
  Occurrence.0$Country = as.character(Occurrence.0$Country)
  Occurrence.0$City = as.character(Occurrence.0$City)
  Occurrence.0$Beach = as.character(Occurrence.0$Beach)
  
  OccurrenceAll = bind_rows(OccurrenceAll, Occurrence.0)
  
}



## write the binded file
write_csv(path = file.path(baseDataDir, baseEcosystem, "OccurrenceALL.csv"), OccurrenceAll)

