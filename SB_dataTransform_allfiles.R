
library(RColorBrewer)
palette(brewer.pal(8, "Set2"))

library(readxl)
library(dplyr)
library(lubridate)
library(reshape2)
library(leaflet)
library(readr)
library(fs)


## function to remove all spaces in a string
NoSpaces = function(x){
  return(gsub(" ", "", x))
}


baseDataDir =  "../data2"
baseEcosystem = "beach"

datafileNames = dir_ls(file.path(baseDataDir, baseEcosystem))


## taxa dictionary file name
taxaDictFileName = file.path(baseDataDir, "taxalist", baseEcosystem, "taxonlistALL.csv")
taxaDict = read_tsv(taxaDictFileName)


for (ii in 1:length(datafileNames)){
  
  print(paste0(ii, " - ", datafileNames[ii]))
  
  ## Reading data 
  beachData = read_xlsx(path = datafileNames[ii], sheet = 1)
  
  ## standardise the variable types and format
  beachData$Country = toupper(beachData$Country)
  beachData$City = toupper(beachData$City)
  beachData$Beach = toupper(beachData$Beach)
  beachData$Zone = toupper(beachData$Zone)
  beachData$Beach_slope = as.numeric(beachData$Beach_slope)
  
  ## remove the parenthesis fgrom the variable name
  names(beachData)[20] = "Level"
  
  siteDF = beachData[,1:21]
  nRecords = nrow(beachData)
  
  ## create eventID: countryCode-LocalityCode-SiteCode-strataCode-yymmdd
  eventID = with(beachData, paste(NoSpaces(Country), NoSpaces(City), NoSpaces(Beach), Station, 
                                  sprintf("T%02i", Transect), sprintf("L%02i",Level), Zone,
                                  paste0(year(Date), sprintf("%02i", month(Date)), sprintf("%02i", day(Date))), 
                                  sep = "-"))
  
  
  ## put eventID as first variable
  beachData = cbind(eventID, beachData)
  siteDF = cbind(eventID, siteDF)
  
  
  
  
  ## Read the Abundance data sheet
  
  ## lets transform the DF into a long format using reshape
  Occurrence = melt(beachData, id.vars = c(1,3:5,11,12,16,19:22), measure.vars = 23:ncol(beachData), 
                    variable.name = "scientificName", value.name = "abundance", na.rm = T)
  
  ## remove ecords with abundance==0
  ## uncomment if wants to remove abundance==0
  ## Occurrence= Occurrence %>% dplyr::filter(abundance!=0)
  
  
  ### Add the taxon name info from the WoRMS matched file
  ## join the taxon fields to the abundance data
  Occurrence = left_join(Occurrence, taxaDict, by = c("scientificName"="ScientificName"))
  
  
  ## remove records with no WoRMS match
  Occurrence = Occurrence %>% filter(!is.na(LSID))
  
  ### Create eventID and occurrenceID
  ## create occurrenceID, adding the seq number
  organismSeq = 1:nrow(Occurrence)
  occurrenceID = paste(Occurrence$eventID, sprintf("%000005i", organismSeq), sep="-")
  
  Occurrence = cbind(occurrenceID, Occurrence)
  
  ### save file for analysis
  fileNameBeach = file.path(baseDataDir, "DataAnalysisFiles", baseEcosystem, 
                            paste(Occurrence$Country[1], NoSpaces(Occurrence$City[1]), NoSpaces(Occurrence$Beach[1]),
                                  sep="-"))
  readr::write_csv(path = paste0(fileNameBeach, "_beach_siteDF.csv"), siteDF)
  readr::write_csv(path = paste0(fileNameBeach, "_beach_occurrence.csv"), Occurrence)
  
  ## create Grandparent eventID: SITE
  eventFile = siteDF %>% group_by(eventID) %>% 
    summarise(parentEventID = "", 
              eventDate = unique(Date),
              habitat = "Sandy Beach",
              country=unique(Country),
              locality = unique(City),
              site = unique(Beach),
              strata = unique(Zone),
              decimalLongitude = mean(Longitude),
              decimalLatitude = mean(Latitude),
              coordinateUncertaintyInMeters = "",
              geodeticDatum = "WGS84")
  readr::write_csv(path = file.path(baseDataDir, "IPTFiles/beach", paste0(siteDF$Country[1], "-", siteDF$City[1], "-" , siteDF$Beach[1],"_ipt_event.csv")), eventFile)
  
  
  ## create occurrence file
  
  ## check for present or absent based on abundance 
  Occurrence$occurrenceStatus = ifelse(Occurrence$abundance==0, "absent", "present")
  
  ### Occurrence extension file
  occurrenceFile = data.frame(occurrenceID = Occurrence$occurrenceID, 
                              eventID = Occurrence$eventID,
                              scientificName = Occurrence$ScientificName_accepted,
                              scientificNameID = Occurrence$LSID,
                              basisOfRecord = rep("HumanObservation", nrow(Occurrence)),
                              occurrenceStatus = Occurrence$occurrenceStatus)

    readr::write_csv(path = file.path(baseDataDir, "IPTFiles/beach", paste0(siteDF$Country[1], "-", siteDF$City[1],"-" , siteDF$Beach[1], "_ipt_occurrence.csv")), occurrenceFile)
  
  ## create eMoF file for abundance
  MoFFile = data.frame(occurrenceID = Occurrence$occurrenceID, 
                       eventID = Occurrence$eventID,
                       measurementType = rep("abundance", nrow(Occurrence)),
                       measurementTypeID = rep("http://vocab.nerc.ac.uk/collection/P06/current/UMSQ/1/",
                                               nrow(Occurrence)),
                       measurementValue = as.numeric(Occurrence$abundance), 
                       measurementUnit = rep("count", nrow(Occurrence)),
                       measurementUnitID = rep("count", nrow(Occurrence))) ## needs to be checked
  readr::write_csv(path = file.path(baseDataDir, "IPTFiles/beach", paste0(siteDF$Country[1], "-", siteDF$City[1],"-" , siteDF$Beach[1], "_ipt_MoF.csv")), MoFFile)
  
}
