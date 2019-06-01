library(knitr)
library(readxl)
library(dplyr)
library(lubridate)
library(reshape2)
library(leaflet)
library(readr)
library(fs)


## get all file names
## add the file name here, with eh correct path
## rocky or beach
baseDataDir =  "../data2"
baseEcosystem = "rocky"

datafileNames = dir_ls(file.path(baseDataDir, baseEcosystem))


## taxa dictionary file
taxaDictFileName = file.path(baseDataDir, "taxalist", baseEcosystem, "RS-taxonlistALL.csv")
taxaDict = read_tsv(taxaDictFileName)


for (ii in 1:length(datafileNames)){
  
  datafileName = datafileNames[ii]
  print(paste0(ii, " - ", datafileName))
  
  
    
  ## I will read from line 3 as there are merged rows in rows 1-2 that fucks everything
  ## NEVER NEVER NEVER merge columns or rows if you want to do a serious data analysis. NEVER.
  ## Reading data upto the first rugosity column
  ## set the names of the columns
  siteColNames = c("yyear", "mmonth", "dday", "country", "state", "locality", "site", "strata", 
                   "pictureID", "stratumCriteria", "decimalLatitude", "decimalLongitude", 
                   "coordinateUncertaintyInMeters", "geodeticDatum", 
                   "substrateComposition", "isMPA", "isUrban", "isAffectedbySand", 
                   "rugosityRatio")
  
  siteColTypes = c(rep("numeric", 3), rep("text", 7), rep("numeric", 3), rep("text", 5), "numeric")
  
  siteDF = read_xlsx(path = datafileName, sheet = 3, range = cell_cols("A:S"),  
                     col_names = siteColNames, col_types = siteColTypes)
  
  ## remove the first two rows (as range took precedence)
  siteDF = siteDF[3:nrow(siteDF),]
  
  ## conver country name to upeer case
  siteDF$country = toupper(siteDF$country)
  siteDF$locality = toupper(siteDF$locality)
  siteDF$site = toupper(siteDF$site)
  siteDF$strata = toupper(siteDF$strata)
  siteDF$pictureID = as.character(siteDF$pictureID)
  siteDF$eventDate = ymd(paste0(siteDF$yyear, sprintf("%02i",siteDF$mmonth), sprintf("%02i",siteDF$dday)))
  
  ## eventID for siteDF -- this is the MAIN (parent) eventID
  ## country-locality-site-date
  siteDF$eventID = paste(siteDF$country, gsub(" ", "", siteDF$locality), 
                         gsub(" ", "", siteDF$site), 
                         paste0(year(siteDF$eventDate), 
                                sprintf("%02i", month(siteDF$eventDate)), 
                                sprintf("%02i", day(siteDF$eventDate))), 
                         sep="_")
  
  
  ## TRANSECT eventID. Child of MAIN (parent) eventID
  ## country-locality-site-date-strata
  siteDF$eventID.transect = paste(siteDF$country, gsub(" ", "", siteDF$locality), 
                                  gsub(" ", "", siteDF$site), 
                                  paste0(year(siteDF$eventDate), 
                                         sprintf("%02i", month(siteDF$eventDate)), 
                                         sprintf("%02i", day(siteDF$eventDate))), 
                                  siteDF$strata,
                                  sep="_")
  
  ## Read the Abundance data sheet
  Abundance = read_excel(path = datafileName, sheet =1, skip = 15)
  
  ## change the name of the first columns
  names(Abundance)[1:7] = c("eventDate", "country", "locality", "site", "strata", "pictureID", "replicateID")
  
  ## the rest of the columns will correspond to the scientific names in wide format.
  ## we need to remove the last rows that contains the totals. They are identified as eventDate in NA
  Abundance = Abundance[!is.na(Abundance$eventDate),]
  Abundance$replicateID = as.numeric(Abundance$replicateID)
  Abundance$country = toupper(Abundance$country)
  Abundance$locality = toupper(Abundance$locality)
  Abundance$site = toupper(Abundance$site)
  Abundance$strata = toupper(Abundance$strata)
  Abundance$pictureID = as.character(Abundance$pictureID)
  
  ## 
  ## Transform the DF into a long format using reshape
  Abundance.lf = melt(Abundance, id.vars = 1:7, measure.vars = 8:ncol(Abundance), 
                      variable.name = "scientificName", value.name = "abundance", na.rm = T)
  
  ## verifiy that abundace is a number
  Abundance.lf$abundance = as.numeric(Abundance.lf$abundance)
  
  ## remove ecords with abundance==0
  ## uncommnet if you want to exclude abundace==0
  ## Abundance.lf= Abundance.lf %>% dplyr::filter(abundance!=0)
  
  
  ## Read Data: Cover
  ### Read the Cover data sheet
  Cover = read_excel(path = datafileName, sheet =2, skip = 15)
  
  ## change the name of the first columns
  names(Cover)[1:7] = c("eventDate", "country", "locality", "site", "strata", "pictureID", "replicateID")
  
  ## the rest of the columns will correspond to the scientific names in wide format.
  ## we need to remove the last rows that contains the totals. They are identified as eventDate in NA
  Cover = Cover[!is.na(Cover$eventDate),]
  
  ## convert country to uppercase
  Cover$replicateID = as.numeric(Cover$replicateID)
  Cover$country = toupper(Cover$country)
  Cover$locality = toupper(Cover$locality)
  Cover$site = toupper(Cover$site)
  Cover$strata = toupper(Cover$strata)
  Cover$pictureID = as.character(Cover$pictureID)
  
  ## 
  ## transform the DF into a long format using reshape
  Cover.lf = melt(Cover, id.vars = 1:7, measure.vars = 8:ncol(Cover), 
                  variable.name = "scientificName", value.name = "Cover", na.rm = T)
  
  ## verify that Cover is a number
  Cover.lf$Cover = as.numeric(Cover.lf$Cover)
  
  
  ## remove ecords with Cover==0
  ## uncomment if you want to remove cover==0
  ## Cover.lf = Cover.lf %>% dplyr::filter(Cover!=0)
  
  ### Join Abundance and Cover tables
  
  Occurrence = full_join(Abundance.lf, Cover.lf,  
                         by = c("eventDate", "country", "locality", "site", "strata", "replicateID", "scientificName"))
  
  ## order the result in long format data frame
  Occurrence = Occurrence %>% arrange(country, locality, site, strata, replicateID)
  
  
  ### Add the taxon name info from the WoRMS matched file
  ## join the taxon fields to the abundance data
  Occurrence = left_join(Occurrence, taxaDict, by = c("scientificName"="ScientificName"))
  
  
  ### Create eventID and occurrenceID for occurrence DF
  
  ## create eventID.quadrat
  ## country-locality-site-date-strata
  eventID.quadrat = paste(Occurrence$country, gsub(" ", "", Occurrence$locality), 
                          gsub(" ", "", Occurrence$site), 
                          paste0(year(Occurrence$eventDate), 
                                 sprintf("%02i", month(Occurrence$eventDate)), 
                                 sprintf("%02i", day(Occurrence$eventDate))),
                          Occurrence$strata,
                          paste0("R", sprintf("%003i", Occurrence$replicateID)),
                          sep = "_")
  
  Occurrence = cbind(eventID.quadrat, Occurrence)
  
  ## eventID to siteDF
  ## siteDF = cbind(siteDF$, siteDF)
  
  
  ## create occurrenceID, adding the seq number
  organismSeq = 1:nrow(Occurrence)
  occurrenceID = paste(eventID.quadrat, sprintf("%000005i", organismSeq), sep="-")
  
  Occurrence = cbind(occurrenceID, Occurrence)
  
  ## set eventData as Date
  Occurrence$eventDate = as.Date(Occurrence$eventDate)
  
  ## Create DwC EVENT, OCCURRENCE and eMoF files
  ### Event core file
  ## create the structure of the table
  eventFile = data.frame(eventID = character(),
                         parentEventID = character(),
                         eventDate = as.Date(character()),
                         habitat = character(),
                         country = character(), 
                         locality = character(),
                         site = character(),
                         strata = character(),
                         decimalLongitude = numeric(),
                         decimalLatitude = numeric(),
                         coordinateUncertaintyInMeters = numeric(),
                         geodeticDatum = character(),
                         pictureID = character()
  )
  
  
  ## create Grandparent eventID: SITE
  eventFile.site = siteDF %>% group_by(eventID) %>% 
    summarise(parentEventID = "", 
              eventDate = unique(eventDate),
              habitat = "Rocky Shore",
              country=unique(country),
              locality = unique(locality),
              site = unique(site),
              strata = "",
              decimalLongitude = mean(decimalLongitude),
              decimalLatitude = mean(decimalLatitude),
              coordinateUncertaintyInMeters = mean(coordinateUncertaintyInMeters),
              geodeticDatum = "WGS84",
              pictureID = unique(pictureID)[1])
  
  
  ## create eventID.TRANSECT
  eventFile.transect = siteDF %>% group_by(eventID = eventID.transect) %>% 
    summarise(eventDate = unique(eventDate),
              habitat = "Rocky Shore",
              country=unique(country),
              locality = unique(locality),
              site = unique(site),
              strata = unique(strata),
              decimalLongitude = mean(decimalLongitude),
              decimalLatitude = mean(decimalLatitude),
              coordinateUncertaintyInMeters = mean(coordinateUncertaintyInMeters),
              geodeticDatum = "WGS84",
              pictureID = unique(pictureID), 
              parentEventID = substr(eventID.transect,1,
                                     unlist(gregexpr("_", eventID.transect))[length(unlist(gregexpr("_", eventID.transect)))]-1)
    )
  
  
  ## create eventID.QUADRAT
  eventFile.quadrat = Occurrence %>% group_by(eventID = eventID.quadrat) %>% 
    summarise(eventDate = unique(eventDate), 
              habitat = "Rocky Shore", 
              country = unique(country), 
              locality = unique(locality), 
              site = unique(site), 
              strata = unique(strata),
              decimalLongitude = NA, 
              decimalLatitude = NA, 
              coordinateUncertaintyInMeters = NA, 
              geodeticDatum = "", 
              pictureID = "") %>% 
    mutate(parentEventID = substr(eventID,1, nchar(as.character(eventID))-5))
  
  eventFile = bind_rows(eventFile.site, eventFile.transect, eventFile.quadrat)
  
  ## write file
  readr::write_csv(path = file.path(baseDataDir, "IPTFiles", paste0(siteDF$country[1], "-", siteDF$locality[1], "_ipt_event.csv")), eventFile)
  
  
  
  
  ### Occurrence extension file
  
  ## check for present or absent based on abundance 
  Occurrence$occurrenceStatus = ifelse((Occurrence$abundance==0 & Occurrence$Cover==0) | (is.na(Occurrence$abundance) & is.na(Occurrence$Cover)),
                                       "absent", "present")
  
  
  occurrenceFile = data.frame(occurrenceID = Occurrence$occurrenceID, 
                              eventID = Occurrence$eventID,
                              scientificName = Occurrence$ScientificName_accepted,
                              scientificNameID = Occurrence$LSID,
                              basisOfRecord = rep("HumanObservation", nrow(Occurrence)),
                              occurrenceStatus = Occurrence$occurrenceStatus)
  
  
  readr::write_csv(path = file.path(baseDataDir, "IPTFiles", paste0(siteDF$country[1], "-", siteDF$locality[1], "_ipt_occurrence.csv")), occurrenceFile)
  
  
  ### Measurement or facts file
  ## we will do that first for abundance then for cover and them bind both DF 
  ## abundance
  Occurrence.abun = subset(Occurrence, !is.na(abundance))
  MoF.abund = data.frame(occurrenceID = Occurrence.abun$occurrenceID, 
                         eventID = Occurrence.abun$eventID,
                         measurementType = rep("abundance", nrow(Occurrence.abun)),
                         measurementTypeID = rep("http://vocab.nerc.ac.uk/collection/P06/current/UMSQ/1/",
                                                 nrow(Occurrence.abun)),
                         measurementValue = as.numeric(Occurrence.abun$abundance), 
                         measurementUnit = rep("count", nrow(Occurrence.abun)),
                         measurementUnitID = rep("count", nrow(Occurrence.abun))) ## needs to be checked
  
  ## cover
  Occurrence.cover = subset(Occurrence, !is.na(Cover))
  MoF.cover = data.frame(occurrenceID = Occurrence.cover$occurrenceID, 
                         eventID = Occurrence.cover$eventID,
                         measurementType = rep("cover", nrow(Occurrence.cover)),
                         measurementTypeID = rep("http://vocab.nerc.ac.uk/collection/P01/current/SDBIOL10/",
                                                 nrow(Occurrence.cover)),
                         measurementValue = as.numeric(Occurrence.cover$Cover), 
                         measurementUnit = rep("percentage", nrow(Occurrence.cover)),
                         measurementUnitID = rep("percentage", nrow(Occurrence.cover))) ## needs to be checked
  
  
  
  MoFFile = bind_rows(MoF.abund, MoF.cover)
  
  readr::write_csv(path = file.path(baseDataDir, "IPTFiles", paste0(siteDF$country[1], "-", siteDF$locality[1], "_ipt_MoF.csv")), MoFFile)
  
  
  ### save file for analysis
  fileNameSite = paste(siteDF$country[1], gsub(" ", "", siteDF$locality[1]), 
                       gsub(" ", "", siteDF$site[1]),"dashboard_siteDF.csv", sep="_")
  fileNameOccurrence = paste(siteDF$country[1], gsub(" ", "", siteDF$locality[1]),
                             gsub(" ", "", siteDF$site[1]), "dashboard_occurrence.csv", sep="_")
  
  write_csv(path = file.path(baseDataDir, "DataAnalysisFiles", baseEcosystem, fileNameSite), eventFile)
  write_csv(path = file.path(baseDataDir,"DataAnalysisFiles", baseEcosystem, fileNameOccurrence), Occurrence)
  
}