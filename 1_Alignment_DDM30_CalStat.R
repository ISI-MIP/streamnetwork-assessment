# Initial script to identify WaterGAP 2.2e calibration stations that had to be moved in order to fit with DDM30
# Leonie Schiebener 09.07.2022
# Last Update: Hannes Müller Schmied 27.10.2022

rm(list = ls())

#libraries
library(sf)

# paths
basicpath <- "D:/workpath/" #needs to exist, the other folders are created if not existing
inpath <- paste0(basicpath,"INPUT/")
ifelse(!dir.exists(file.path(inpath)), dir.create(file.path(inpath)))
outpath <- paste0(basicpath,"OUTPUT/")
ifelse(!dir.exists(file.path(outpath)), dir.create(file.path(outpath)))

# download calibration station data WaterGAP2.2e
url <- "https://zenodo.org/record/7255968/files/WaterGAP22e_cal_stat.zip"
destfile <- paste0(inpath,"WaterGAP22e_cal_stat.zip")
download.file(url, destfile)
unzip(destfile,exdir=substr(inpath,1,nchar(inpath)-1))

# read in station data 22e 
cal_shp  <- st_read(paste0(inpath,"WaterGAP22e_cal_stat.shp"))

cal_stat <- as.data.frame(cal_shp)

# round original coordinates
# ATTENTION: whole numbers are rounded down

cal_stat['lat_round'] <- round((cal_stat$Latitud+0.25)*2)/2-0.25
cal_stat['lon_round'] <- round((cal_stat$Longitd +0.25)*2)/2-0.25

# identify differences between original lat & position on ddm30

cal_stat['lat_identical'] <- NA 
cal_stat['lon_identical'] <- NA

# loop over 1509 observation stations
for (i in 1:1509) {
  
  if (cal_stat[i,"lat_round"] == cal_stat[i,"Lat_ddm30"]) {
    
    cal_stat[i,"lat_identical"] <- 1        # station has not been moved 
    
  } else {
    
    cal_stat[i,"lat_identical"] <- 0        # station has been moved
    
  }
  if (cal_stat[i,"lon_round"] == cal_stat[i,"Lon_ddm30"]) {
    
    cal_stat[i,"lon_identical"] <- 1       # station has not been moved 
    
  } else  {
    
    cal_stat[i,"lon_identical"] <- 0       # station has been moved
    
  } 
  
}

# bulding the sum of the columns providing the information whether station was moved to match DDM30 or not

cal_stat['both_identical'] <- cal_stat$lat_identical + cal_stat$lon_identical    # value of 2 means station has not been moved  


# add info about move to original shp file
move_info <- cal_stat$both_identical

cal_shp['Move_ddm30'] <- move_info

# write out shp file
st_write(cal_shp, paste0(outpath,"WaterGAP22e_cal_stat_moveddm30.shp"), driver = "ESRI Shapefile")




##### Subsetting & Identifying moved stations ####

    # Additional and optional data processing steps

Cal_stat_identical <- subset(cal_stat, cal_stat$both_identical == 2 )

# write out .shp: stations of all databases that have not been moved

st_write(Cal_stat_identical, paste0(outpath,"Cal_Stat_Unchanged_Location.shp"), driver = "ESRI Shapefile")

# identify stations that are NOT derived from GRDC

cal_stat_GSIM <- subset(Cal_stat_identical, Cal_stat_identical$sourc_1 == "GSIM")

cal_stat_ADHI <- subset(Cal_stat_identical, Cal_stat_identical$sourc_1 == "ADHI")

# identify stations that are ONLY derived from GRDC

cal_stat_GRDC <- subset(Cal_stat_identical, Cal_stat_identical$sourc_1 != "ADHI" & Cal_stat_identical$sourc_1 != "GSIM")

cal_stat_GRDC_old <- subset(Cal_stat_identical, Cal_stat_identical$sourc_2 == "oldGRDC" )

cal_stat_GRDC_upd <- subset(Cal_stat_identical, Cal_stat_identical$sourc_2 == "updGRDC" )
