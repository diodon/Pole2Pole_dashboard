## get country, locality and site names and coordinates from excel data tables

library(readxl)
library(fs)
library(lubridate)
library(dplyr)


basedir = "../data2/rocky"

filenames = dir_ls(path = basedir, regexp = "xlsx")

siteColNames = c("yyear", "mmonth", "dday", "country", "state", "locality", "site", "strata", 
                 "sitePicture", "stratumCriteria", "decimalLatitude", "decimalLongitude", 
                 "coordinateUncertaintyInMeters", "geodeticDatum", 
                 "substrateComposition", "isMPA", "isUrban", "isAffectedbySand", 
                 "rugosityRatio")

siteColTypes = c(rep("numeric", 3), rep("text", 7), rep("numeric", 3), rep("text", 5), "numeric")


siteALL = data.frame(country = character(),
                     locality = character(),
                     site = character(),
                     eventDate = as.Date(character()),
                     decimalLongitude = numeric(),
                     decimalLatitude = numeric(),
                     nQuadrats = numeric(),
                     nStrata = numeric())


for (i in 1:length(filenames)){
  
  print(paste0(i, "--", filenames[i]))
  
  siteDF = read_xlsx(path = filenames[i], sheet = 3, range = cell_cols("A:S"),  
                     col_names = siteColNames, col_types = siteColTypes)
  
  ## remove the first two rows (as range took precedence)
  siteDF = siteDF[3:nrow(siteDF),]
  
  ## conver country, Locality and site names to upeer case
  siteDF$country = toupper(siteDF$country)
  siteDF$state = toupper(siteDF$state)
  siteDF$locality = toupper(siteDF$locality)
  siteDF$site = toupper(siteDF$site)
  
  ## get the date
  siteDF$eventDate = ymd(paste0(siteDF$yyear, sprintf("%02i", siteDF$mmonth), sprintf("%02i", siteDF$dday)))
  
  
   
  ## get strata column from abundance sheet
  strataCol = read_xlsx(path = filenames[i], range = "Abundance!E16:E200")
  strataCol = strataCol$Strata[!is.na(strataCol$Strata)]

  
  siteDF.short = siteDF %>% dplyr::group_by(country, locality, site, eventDate) %>% 
    dplyr::summarise(decimalLatitude = mean(decimalLatitude),
                     decimalLongitude = mean(decimalLongitude)) %>% 
    dplyr::mutate(nQuadrats = length(strataCol), nStrata = length(unique(strataCol)))
  
  
   
  siteALL = bind_rows(siteALL, siteDF.short)
  
}
