# Plots modeled discharge within a 6.5 deg x 6.5 deg size pane for each model and calibration station 
# Author: Leonie Schiebener 09.07.2022
# Last Update: Hannes Müller Schmied, 27.10.2022


rm(list=ls())

# Libraries
library(raster)
library(sf)
library(plotrix)
library(classInt)  #classIntervals()

# working directories
basicpath <- "D:/workpath/"
inpath <- paste0(basicpath,"INPUT/")
inpath_calstat <- paste0(basicpath,"OUTPUT/")
outpath <- paste0(basicpath,"EVAL_RESULTS/")
ifelse(!dir.exists(file.path(outpath)), dir.create(file.path(outpath)))
plotpath <- paste0(outpath,"plots/")
ifelse(!dir.exists(file.path(plotpath)), dir.create(file.path(plotpath)))


# download model data for ISIMIP2b
url <- "https://zenodo.org/record/7256381/files/isimip2b_streamflow_examples.zip"
destfile <- paste0(inpath,"isimip2b_streamflow_examples.zip")
download.file(url, destfile)
unzip(destfile,exdir=substr(inpath,1,nchar(inpath)-1))

# download streamline
url <- "https://zenodo.org/record/7256788/files/ddm30wlm_basarea.zip"
destfile <- paste0(inpath,"ddm30wlm_basarea.zip")
download.file(url, destfile)
unzip(destfile,exdir=substr(inpath,1,nchar(inpath)-1))

# List of input NetCDF files of models - adjustable with varying models and number of models to be compared
# ATTENTION: if the number of models changes further adjustments need to be done after line 98
model_files <- list( clm45 = c(paste0(inpath,"clm45_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"CLM4.5"),
                     cwatm = c(paste0(inpath,"cwatm_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"CWatM"),
                     h08 = c(paste0(inpath,"h08_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"H08"),
                     jules_w1 = c(paste0(inpath,"jules-w1_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"JULES-W1"),
                     lpjml  = c(paste0(inpath,"lpjml_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"LPJmL"),
                     matsiro = c(paste0(inpath,"matsiro_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"MATSIRO"),
                     mpi_hm = c(paste0(inpath,"mpi-hm_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"MPI-HM"),
                     orchidee = c(paste0(inpath, "orchidee_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"ORCHIDEE"),
                     orchidee_dgvm = c(paste0(inpath,"orchidee-dgvm_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"ORCHIDEE-DGVM"),
                     pcr_globwb = c(paste0(inpath,"pcr-globwb_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"PCR-GLOBWB"),
                     watergap = c(paste0(inpath,"watergap2_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"WaterGAP"),
                     legende = c(paste0(inpath,"watergap2_ipsl-cm5a-lr_historical_dis_global_yearly_1971_1980.nc4"),"legend")
                     
)


# read DDM30 with according streamflow accumulation
DDM30 <- st_read(paste0(inpath,"ddm30wlm_basarea.shp"))

#subset DDM30 regarding flow accumulation

DDM30['DRAINAGE'] <- NA

DDM30 = within(DDM30,{
  
  DRAINAGE[upstr_area %in% c(10:15000)] = 'E'
  DRAINAGE[upstr_area %in% c(15001:50000)] = 'D'
  DRAINAGE[upstr_area %in% c(50001:150000)] = 'C'
  DRAINAGE[upstr_area %in% c(150001:300000)] = 'B'
  DRAINAGE[upstr_area %in% c(300001:5915800)] = 'A'
  
})

DDM30$DRAINAGE <- as.factor(DDM30$DRAINAGE)

lineWidths <- (c(5,4,3,2,1))[DDM30$DRAINAGE]


# read obs discharge station data
calstat_shp  <- st_read(paste0(inpath_calstat,"WaterGAP22e_cal_stat_moveddm30.shp")) 

# subset WaterGAP 2.2e calibration stations (calstat_shp) to only those stations that have NOT been moved to match DDM30 (Mv_dd30 = 2) & comprise a discharge area of at least 50000 km2

subcalstat <- subset(calstat_shp, calstat_shp$Move_ddm30 == 2 & calstat_shp$upbasinddm >= 50000)

# dummy raster needed for the setting of pane size. Which model from the list is used here is of no concern but this line is mandatory for the success of the loop over stations
prep_raster <- raster::raster(model_files[[1]][[1]])

# loop over stations via length of the subset station dataset
for (s in 1:length(subcalstat$ID_1)) {
  
  stat <- subcalstat[s,]
  
  # leads to an extend of 6.5° x 6.5°. Can be adjusted.
  pane_size <- 3.25
  
  # bottom and top margin
  bottom<- stat$Lat_ddm30 - pane_size
  top <- stat$Lat_ddm30 + pane_size
  
  # right and left margin
  right <- stat$Lon_ddm30 + pane_size
  left <- stat$Lon_ddm30 - pane_size
  
  boundingbox <- sf::st_bbox(c(xmin = left, xmax = right, ymin = bottom, ymax = top))
  st_crs(boundingbox) <- 4326
  my_window <- extent(boundingbox)
  pane <- setExtent(prep_raster,boundingbox)
  DDM30clip <- st_crop(DDM30,boundingbox) 
  lineWidths <- (c(5,4,3,2,1))[DDM30clip$DRAINAGE]
  
  
  # settings for plotting
  pname <- paste0("plot_",stat$ID_1)
  
  png(paste0(plotpath, pname,".png"), width=3000, height=4000, units="px", res=300)
  
  par(mfrow=c(4,3),
      oma=c(0, 0, 2, 0),
      mar=c(0, 0, 0.5, 0)+2,
      xpd = NA)
  
  brks_discharge <- c(0,1,10,100,1000,10000,100000,1000000000000) # adjustable in case of less fluctuating discharges
  colors <- c("#FFFF33","#A6D96A","#66BD63","#1A9850","#4393C3","#2166AC","#053061") # adjustable if varying amount of discharge classes are required
  
  # loop over ISIMIP model output files      
  for (m in 1:length(model_files)) {
    
    if (m == 12) {
      
      # dummy plot for legend
      discharge_raster <- raster::raster(model_files[[m]][[1]]) 
      
      plot(my_window,xlab="",ylab="", axes=F,col=NA)
      plot(discharge_raster, ext=pane, breaks = brks_discharge, axes=F, col = "white", legend = F,add=T, box=FALSE, bty="n")
      
    } else {
      
      
      discharge_raster <- raster::raster(model_files[[m]][[1]]) 
      
      plot(my_window, col=NA,xlab="",ylab="",main = model_files[[m]][[2]])
      plot(discharge_raster, ext=pane, breaks = brks_discharge, col = colors, legend = F, add=T )
      plot(st_geometry(DDM30clip), add = TRUE, col = "darkred", lwd = lineWidths)
      plot(st_geometry(stat), pch = 16, add = TRUE , col = "black", cex = 2 )
    }
  }
  
  
  xpd = NA
  
  mtext(paste0(stat$ID_1,": ",stat$sttn_nm,", ", stat$rivr_nm," (",stat$country,")"), side = 3, outer = TRUE)
  lables <- c("0-1","1-10","10-100","100-1000","1000-10000","10000-100000","> 100000") #needs adjusting if line 106 has been previously adjusted
  legend("bottom",legend = lables, fill = colors, bty = "n", cex = 2.25, title = "streamflow [m3/s]" )
  
  xpd= TRUE
  
  dev.off()
  
}

#create file for manual storing the assessment result
assessmentfile <- matrix(0,nrow=length(subcalstat$ID_1),ncol=length(names(model_files[1:(length(names(model_files))-1)])))
rownames(assessmentfile) <- subcalstat$ID_1
colnames(assessmentfile) <- c(names(model_files[1:(length(names(model_files))-1)]))

write.csv(data.frame("ID_1"=rownames(assessmentfile),assessmentfile),paste0(outpath,"assessment_models_rivernetwork.csv"),row.names=F)
