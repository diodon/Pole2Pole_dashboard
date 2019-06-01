### UPDATE SST timeseries
### Get SST timeseries from satellite products using erddap
### the source of data is `jplMURSST41`. See https://coastwatch.pfeg.noaa.gov/erddap/info/jplMURSST41/index.html
### data is extracted with `rerddap::griddap` for a particular coordinate and stored as csv file.
### E Klein. eklein@usb.ve
### 2019-04-10

### you need to run getSST.R first to get all the data
### then use this script to update the new data since tha last run

library(readr)
library(rerddap)
library(lubridate)
library(dplyr)


## functions

## remove all spaces from string
NoSpaces = function(x){
  return(gsub(" ", "", x))
}

## set base directories
baseDataDir =  "../data2"
SSTDir = "sst"
SSTSiteName = "Arraial do Cabo"   ## for the resulting file name
SSTcoords.lon = -41.95
SSTcoords.lat = -23.00

## set site coordinates and time for SST extraction
## Gorgona
## SSTcoords.lon = -78.2
## SSTcoords.lat = +2.95

## get the last date collected
SST.old = read.csv(file.path(baseDataDir, SSTDir, paste0(NoSpaces(SSTSiteName), "_SST.csv")), stringsAsFactors = F)
SSTstartDate = SST$time[nrow(SST)]

## set dataset source
SSTsource = info("jplMURSST41")

##
## Get sst 
SST = griddap(SSTsource, 
              time=c(SSTstartDate, "last"),
              longitude = c(SSTcoords.lon, SSTcoords.lon),
              latitude = c(SSTcoords.lat, SSTcoords.lat),
              fields = "analysed_sst",
              fmt = "csv")

SST = SST[,c(1,4)]
names(SST) = c("time", "SST")

## convert time to a Data object
SST$time = as.Date(ymd_hms(SST$time))

## add new lines
SST = rbind(SST.old, SST)

## save SST
write_csv(SST, path = file.path(baseDataDir, SSTDir, paste0(NoSpaces(SSTSiteName), "_SST.csv")))

## END
