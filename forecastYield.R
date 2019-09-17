####  forecastYield.R 
####
####  
####
#### inputs:  
####  output of the SPI code
####  a US county shapefile 
####  NASS rainfed corn yieldsfrom https://quickstats.nass.usda.gov
####
#### shapefile from:
#### https://catalog.data.gov/dataset/tiger-line-shapefile-2016-nation-u-s-current-county-and-equivalent-national-shapefile/resource/fa774c9d-a098-4792-bfd4-94c7caa190b6
####
#### libraries required: sf
####
#### 

library(sf)

###########################################################################
#### data reading and organization
#### at the end, we have a set of regressors in zplot_ordered (spi by month by county)
#### and outcomes in yields_ordered (county corn yield)
#### but yields have not yet been detrended
###########################################################################

#### read SPI data
load("spi_shiny_app/data/spi/SPI_out_3month.RData")

### pick out which estimate you want to use z, z_emp, z_fit
zplot <- spi_results$z
Lon = spi_results$Lon
Lat = spi_results$Lat
monthList = spi_results$monthList
yearList = spi_results$yearList
yearSeq = sort(unique(yearList))
numYears = length(yearSeq)


rm(spi_results)
for (i in 1:30) gc()

#### read below for bigger shapefile with lat lon data
counties <- st_read("spi_shiny_app/data/us_counties_large/tl_2016_us_county.shp",stringsAsFactors=FALSE)

#### assign county SPI value to closest cell of z 
#### (calculating a county average might be nice to add later, but averaging effect might actually be detrimental to model)

#### create map of counties to cells
#### reorder zplot data
#### might be faster way to do this (to avoid loop), but only 3108 counties
celltocountymap <- array(0,c(nrow(counties),3))
zplot_ordered <- array(0,c(nrow(counties),dim(zplot)[3]))
for (icounty in 1:nrow(counties)){
  i=which(abs(as.numeric(counties$INTPTLON[icounty])-Lon) == min(abs(as.numeric(counties$INTPTLON[icounty])-Lon)))
  j=which(abs(as.numeric(counties$INTPTLAT[icounty])-Lat) == min(abs(as.numeric(counties$INTPTLAT[icounty])-Lat)))
  celltocountymap[icounty,1]=icounty
  celltocountymap[icounty,2]=i
  celltocountymap[icounty,3]=j
  zplot_ordered[icounty,]=zplot[i,j,]
}
#rm(zplot)
#for (i in 1:30) gc()

stateList = counties$STATEFP
countyList = counties$COUNTYFP
IDList = counties$GEOID
countyLatList = counties$INTPTLAT
countyLonList = counties$INTPTLON

rm(counties)
for (i in 1:30) gc()

yields <- read.csv("../NASS_corn_1989_2018.csv")
yields_ordered = array(NA,c(dim(zplot_ordered)[1],numYears))
for (i in 1:length(stateList)){
  i0 <-which(yields$State.ANSI == as.numeric(stateList[i]) & yields$County.ANSI == as.numeric(countyList[i]))
  j0 <- match(yields$Year[i0],yearSeq)
  yields_ordered[i,j0]=yields$Value[i0]
}

#######################################################
#### detrend yields (linear trends only right now!)
######################################################
for (i in length(countyList)){
  if (!all(is.na(yields_ordered[i,]))){
        
    model <- lm(yields_ordered[i,]~seq(1,numYears),na.action=na.exclude)
    trend <- predict(model)
    yields_ordered[i,]=yields_ordered[i,]-trend
  }
}


#######################################################
#### model A: linear stepwise regression
######################################################



#######################################################
#### model B: random forest
######################################################