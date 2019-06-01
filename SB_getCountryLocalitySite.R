## get country, locality and site names and coordinates from excel data tables
## SANDY BEACH

library(readxl)
library(fs)
library(lubridate)


basedir = "../data2/beach"

filenames = dir_ls(path = basedir, regexp = "xlsx")


siteALL = data.frame(country = character(),
                     locality = character(),
                     site = character(),
                     eventDate = as.Date(character()),
                     decimalLongitude = numeric(),
                     decimalLatitude = numeric(),
                     nTransects = numeric(),
                     nStrata = numeric())


for (i in 1:length(filenames)){
  
  print(paste0(i, "--", filenames[i]))
  
  siteDF = read_xlsx(path = filenames[i])
  
  
  ## conver country, Locality and site names to upeer case
  siteDF$country = toupper(siteDF$Country)
  siteDF$locality = toupper(siteDF$City)
  siteDF$site = toupper(siteDF$Beach)
  siteDF$decimalLatitude = as.numeric(siteDF$Latitude)
  siteDF$decimalLongitude = as.numeric(siteDF$Longitude)
  
  ## get the date
  siteDF$eventDate = as.Date(siteDF$Date)
  
  
  siteDF.short = siteDF %>% dplyr::group_by(country, locality, site, eventDate) %>% 
    dplyr::summarise(decimalLatitude = mean(decimalLatitude),
                     decimalLongitude = mean(decimalLongitude)) %>% 
    dplyr::mutate(nTransects = nrow(siteDF), nStrata = length(unique(siteDF$Zone)))
  
  
   
  siteALL = bind_rows(siteALL, siteDF.short)
  
}
