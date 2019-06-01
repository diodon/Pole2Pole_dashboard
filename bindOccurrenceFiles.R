### Bid all _dashboard files into a single one
library(fs)
library(readr)
library(dplyr)

baseDataDir =  "../data2/DataAnalysisFiles/"
baseEcosystem = "rocky"

filenames = dir_ls(file.path(baseDataDir, baseEcosystem),  glob="*_dashboard_occurrence.csv")


OccurrenceAll = read_csv(filenames[1])

OccurrenceAll$abundance = as.numeric(OccurrenceAll$abundance)
OccurrenceAll$Cover = as.numeric(OccurrenceAll$Cover)
OccurrenceAll$eventDate = as.Date(OccurrenceAll$eventDate)
OccurrenceAll$pictureID.x = as.character(OccurrenceAll$pictureID.x)
OccurrenceAll$pictureID.y = as.character(OccurrenceAll$pictureID.y)

for (i in 2:length(filenames)) {
  
  print(filenames[i])
  
  Occurrence.0 = read_csv(filenames[i])
  Occurrence.0$abundance = as.numeric(Occurrence.0$abundance)
  Occurrence.0$Cover = as.numeric(Occurrence.0$Cover)
  Occurrence.0$eventDate = as.Date(Occurrence.0$eventDate)
  Occurrence.0$pictureID.x = as.character(Occurrence.0$pictureID.x)
  Occurrence.0$pictureID.y = as.character(Occurrence.0$pictureID.y)
  
  OccurrenceAll = bind_rows(OccurrenceAll, Occurrence.0)
  
}


## clean the DF
OccurrenceAll = OccurrenceAll %>% dplyr::select(c(1:7, 9:11, 13:14, 18:19))

## remove no AphiaID except "Bare rock" 
OccurrenceAll = OccurrenceAll %>% filter(!is.na(AphiaID))

## write the binded file
write_csv(path = file.path(baseDataDir, baseEcosystem, "OccurrenceALL.csv"), OccurrenceAll)

