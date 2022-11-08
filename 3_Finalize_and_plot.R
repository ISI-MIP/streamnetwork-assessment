# identify stations that have compatible streamflow networks, plot a global map of the basin characteristics
# Author: Leonie Schiebener 09.07.2022
# Last Update: Hannes Müller Schmied, 27.10.2022

rm(list = ls())


# Libraries
library(raster)
library(sf)
library(plotrix)
library(classInt)  #classIntervals()


# working directories
basicpath <- "D:/workpath/"
inpath <- paste0(basicpath,"INPUT/")
outpath <- paste0(basicpath,"OUTPUT/")
evalpath <- paste0(basicpath,"EVAL_RESULTS/")
#note that the evaluation results needs to be stored in evalpath/assessment_models_rivernetwork_filled.csv

# download calibration basin data WaterGAP2.2e
url <- "https://zenodo.org/record/7255968/files/WaterGAP22e_cal_bas.zip"
destfile <- paste0(inpath,"WaterGAP22e_cal_bas.zip")
download.file(url, destfile)
unzip(destfile,exdir=substr(inpath,1,nchar(inpath)-1))

# read obs discharge station data
calstat_shp  <- st_read(paste0(outpath,"WaterGAP22e_cal_stat_moveddm30.shp")) 
calbas_shp <- st_read(paste0(inpath,"WaterGAP22e_cal_bas.shp")) #MODIFY to read from caliibrepo
p4s_rob <- ("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84
            +units=m +no_defs")

# read additional shapefiles
url <- "https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/110m/physical/ne_110m_coastline.zip"
destfile <- paste0(inpath,"coastline.zip")
download.file(url, destfile)
unzip(destfile,exdir=substr(inpath,1,nchar(inpath)-1))
coast <- st_read(paste0(inpath,"ne_110m_coastline.shp"))
coast_proj <- st_transform(coast, crs = p4s_rob)
#modify shapefile
#get rid of horizontal line in Robinson projection
coast_proj$geometry[[94]][606,1] <- coast_proj$geometry[[94]][605,1]
#get rid of Antarctica and islands around (just double another feature)
coast_proj$geometry[[99]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[105]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[5]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[1]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[39]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[38]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[37]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[36]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[35]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[34]] <- coast_proj$geometry[[98]]
coast_proj$geometry[[97]] <- coast_proj$geometry[[98]]


# read compatible streamflow network files

network <- read.csv(paste0(evalpath,"assessment_models_rivernetwork_filled.csv"), header = TRUE)

#sum up stations
modelcount <- matrix(0,nrow=dim(network)[2],ncol=1)
rownames(modelcount) <- c(colnames(network)[2:dim(network)[2]],"allmodels")
colnames(modelcount) <- "Stations"
for (m in 2:dim(network)[2]) {
  modelcount[m-1,1] <- sum(network[,m])
  if (m == dim(network)[2]) {
    modelsummat <- matrix(NA,nrow=dim(network)[1],ncol=2)
    colnames(modelsummat) <- c("ID_1","allmodels")
    modelsummat[,1] <- network[,1]
    allmod <- 0
    for (n in 1:dim(network)[1]) {
      if (sum(network[n,2:dim(network)[2]]) == dim(network)[2]-1) {
        allmod <- allmod + 1
        modelsummat[n,2] <- 1
      } 
    }
    modelcount[m,1] <- allmod
  }
}

#write assessment statistics
write.csv(data.frame("Model"=rownames(modelcount),modelcount),paste0(evalpath,"assessment_models_statistics.csv"),row.names = F)

#summarize information to field DNassmt
#0: original station coordinates not in co-registered DDM30 grid cell 
#1: original station coordinates within co-registered DDM30 grid cell but upstream basin area < 50.000 km² 
#2: original station coordinates within co-registered DDM30 grid cell, upstream basin area > 50.000 km² 
#3: as 2 but compatible with all models of the assessment

tmp <- calstat_shp
DNassmt <- matrix(NA,nrow=dim(calstat_shp)[1],ncol=1)
tmp2 <- merge(tmp,network, by.x="ID_1", by.y="ID_1",all=T)
tmp3 <- merge(tmp2,modelsummat, by.x="ID_1", by.y="ID_1",all=T)
tmp4 <- cbind(tmp3,DNassmt)

#set the conditions above
tmp4[which(tmp4$Move_ddm30!=2),]$DNassmt <- 0
tmp4[which(tmp4$Move_ddm30==2 & tmp4$upbasinddm < 50000),]$DNassmt <- 1
tmp4[which(tmp4$Move_ddm30==2 & tmp4$upbasinddm >= 50000),]$DNassmt <- 2
tmp4[which(tmp4$DNassmt==2 & tmp4$allmodels==1),]$DNassmt <- 3
table(tmp4$DNassmt)
tmp4DNassmt <- as.data.frame(cbind(tmp4$ID_1,tmp4$DNassmt))
colnames(tmp4DNassmt) <- c("ID_1","DNassmt")

#combine assessment with shapefiles
#for output with all stations
tmp <- calstat_shp
tmp2 <- merge(tmp,network, by.x="ID_1", by.y="ID_1",all=T)
tmp3 <- merge(tmp2,modelsummat, by.x="ID_1", by.y="ID_1",all=T)
calstatout_shp <- merge(tmp3,tmp4DNassmt, by.x="ID_1", by.y="ID_1",all=T)

tmp <- calbas_shp
tmp2 <- merge(tmp,network, by.x="ID_1", by.y="ID_1",all=T)
tmp3 <- merge(tmp2,modelsummat, by.x="ID_1", by.y="ID_1",all=T)
calbasout_shp <- merge(tmp3,tmp4DNassmt, by.x="ID_1", by.y="ID_1",all=T)

st_write(calstatout_shp, paste0(evalpath,"assessment_models_stations.shp"), driver = "ESRI Shapefile")
st_write(calbasout_shp, paste0(evalpath,"assessment_models_basins.shp"), driver = "ESRI Shapefile")

#subset with all models compatible to the DN
t1 <- calbasout_shp[calbasout_shp$allmodels == 1,]
t2 <- as.data.frame(na.omit(t1$ID_1))
colnames(t2) <- "ID_1"

allmodstat_shp <- merge(calstatout_shp, t2, by = "ID_1", all.y = TRUE)  
allmodbas_shp <- merge(calbasout_shp, t2, by = "ID_1", all.y = TRUE)  

st_write(allmodstat_shp, paste0(evalpath,"compatible_dn_all_models_stat.shp"), driver = "ESRI Shapefile")


# prepare plotting
calbasout_shp_proj <- st_transform(calbasout_shp, crs = p4s_rob)
pname <- paste0(evalpath,"plot_assesment_result")

png(paste0(pname,".png"), width=2067, height=1170, units="px", res=300)
par(oma=c(0, 0, 0, 0),
    mar=c(0, 0, 1.9, 0),
    xpd = T)
cols <- c("#ffffcc","#a1dab4","#41b6c4","#225ea8")
plot(st_geometry(calbasout_shp_proj), ylim=c(-700000,800000),xlim=c(-14000000,15000000),col = (cols)[as.numeric(calbasout_shp_proj$DNassmt)+1], border = "grey",lwd=0.2)
plot(st_geometry(coast_proj),col="black", border=NA, add = TRUE)

legend("bottom", legend=c("moved","too small","not in DN","all models in DN"),fill=cols, bty="n", ncol=3,cex=0.7)


dev.off()
