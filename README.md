Initial author: Leonie Schiebener 19.07.2022
Revision and extension: Hannes Müller Schmied, 08.11.2022

# Technical Documentation of Streamnetwork Assessment

## 1. Objective

Not all ISIMIP2b models use the same (e.g. DDM30) drainage network to route runoff into streamflow. In some cases, this results in a mismatch between the stream network identified by the models and the locations of the observational streamflow station. Furthermore, the individual models identify differing streamflow networks. Consequently, intercomparison between the modelled streamflow is limited and validation with observational data is problematic if the streamflow network and observation station location do not align. In order to establish a consistent and plausible evaluation routine for ISIMIP models a set of observational stations, which locations match all stream networks is needed.

During WaterGAP2.2e development the station database for calibration has been updated. Monthly GRDC, GSIM and ADHI data were combined to create the best available spatio-temporal coverage for hydrological evaluation that meet the following criteria: a) a minimum basin area of 9000 km², b) a minimum of 4 complete years and c) a minimum interstation area of 30000 km². With those criteria, and partly by merging of datasets, a dataset of 1509 stations replaced the dataset for previous WaterGAP calibration. This process also included (manual) co-registration of each station to the DDM30 river network in case of significant dieviation between the upstream areas.

This dataset has been used as basis to select a common dataset of basins for model intercomparison. The end-users might be those who want to evaluate the multiple ISIMIP models as well as the support of the quality assessment tool by pre-defining a (sub) set of common basins to evaluate.

## 2. Methodological approach

The manual co-registration of observational stations during the creation of the WaterGAP 2.2e calibration dataset in some cases required moving the location of the station to match DDM30. Even though the use of these stations is beneficial for overall model success, relocating leads to inconsistencies between the stream networks of the models and additionally introduce a bias during data evaluation. Relocated stations should therefore be excluded from the dataset used for model intercomparison. Identification of those stations was achieved through the R script:

_1\_Alignment\_DDM30\_CalStat.R_

Processing steps

- Reads in the calibration station shapefile
- Rounding longitude and latitude of the observation station to match the framework used for DDM30
  - DDM30 works on a 0.5° grid in accordance with the spatial resolution of WaterGAP and only allows for locations to be indicated as 0.25 or 0.75 in the decimal range for lat and long coordinates
  - ATTENTION: whole numbers pose a unique situation during the rounding process since the calculation either allows for rounding up OR down. The script used here rounds whole numbers down.
- Compares latitude and longitude information of the stations original and DDM30 location
  - If the location of either lat or long is identical, a 1 is added to the respective column ('lon\_identical','lat\_identical')
- Builds the sum of columns 'lon\_identical' and 'lat\_identical' in a new column ('both\_identical'). Hence stations with a 2 have not been moved to match DDM30
- Information regarding moving of station location is appended to the shapefile with a new column ('Move\_ddm30')
  - 0 = lat and lon were adjusted,
  - 1 = only one parameter was adjusted,
  - 2 = lat and lon are identical
- Saves the shapefile including the new column 'Move\_ddm30' as _WaterGAP22e\_cal\_stat\_moveddm30.shp_
- Subsets the station shapefile to only those that have not been moved and saving the new shapefile as _Cal\_Stat\_Unchanged\_Location.shp_
- Additional processing steps (code lines 70 - 92)
  - Option to further subset the station dataset depending on the data source of observational data e.g. GRDC, GSIM or ADHI


| **Input Name** | **Description** | **Output Name** | **Description** |
|---|---|---|---|
| **WaterGAP22e\_cal\_stat.shp** | 1509 WaterGAP 2.2e calibration stations as shapefile |  **WaterGAP22e\_cal\_stat\_moveddm30.shp** | New shapefile of 1509 WaterGAP 2.2e calibration stations as shapefile including information regarding alignment of DDM30 and original location |
| | | **Cal\_Stat\_Unchanged\_Location.shp** | Subset of WaterGAP 2.2e calibration stations including only those 711 stations that have not been moved |

To identify the compliance between the models stream network and the observation station location a visual revision has been chosen. Eleven plots (one for each model included in the evaluation process) were produced for every calibration station showing a pane of 6.5° x 6.5° surrounding the calibration station. The DDM30 is shown in red, while the discharge calculated for each 0.5 x 0.5° grid is indicated by the yellow green blue color scheme.

Example
![plot_1112300](https://user-images.githubusercontent.com/57669828/184154881-1960e6ba-75b0-4d68-8363-f3e104700db2.png)

_2\_Plot\_Discharge\_Pane.R_

Processing steps

- Reads NetCDF files and drainage direction shapefile
- Subdivides drainage direction into 5 classes by upstream basin area
- Extracts stations that have not been moved to match DDM30 and comprise a basin area of at least 50.000 km²
- Loops over station subset to plot modelled discharge for every included ISIMIP model
- Plotting pane size is set to 6.5 x 6.5° for every model
- Modelled discharge is subdivided into 7 discharge classes and plotted in differing colors. Subdivision is performed as follows
  - 0 -1 m³/s
  - 1-10 m³/s
  - 10-100 m³/s
  - 100-1000 m³/s
  - 1000-10000 m³/s
  - \> 10000 m³/s
- Some stations are characterized by less fluctuating discharges which required for a smaller discharge range when plotting. In order to do that lines 103 and 133 (labels) need to be adjusted. If the number of required classes changes, line 104 (colors) needs to be adjusted as well.

| **Input Name** | **Description** | **Output Name** | **Description** |
|---|---|---|---|
| **Isimip\_model.nc4** | NetCDF files of ISIMIP models | **Plot\_StationID.png** | Discharge plots for every station meeting the above mentioned requirements regarding basin area and DDM30 agreement |
| **ddm30wlm\_basarea.shp** | WaterGAP drainage direction shapefile | | |
| **WaterGAP22e\_cal\_stat\_moveddm30.shp** | 1509 WaterGAP 2.2e calibration stations as shapefile |

Script 2 identified 323 discharge stations with a drainage area larger than 50.000 km² which had not been moved to agree with DDM30. All resulting plots were visually inspected in terms of their agreement between the modelled drainage network and DDM30. Basically, a station was assessed to be within the drainage network if it lays within the line of the streamflow pattern. As mentioned above some stations showed unclear evidence and needed to be plotted with a modified discharge classification. The results of the visual analyses are documented in an csv file (_Evaluation\_assessment\_models\_rivernetwork.csv_), which was used for the creation of a station database including only those stations that showed perfect alignment between drainage directions of the models and DDM30. 
The csv file should be filled out so that a "1" indicates the station is within the drainage network for the specific model and a "0" if this is not the case. The result should be stored with a different file name, e.g. **\_Evaluation\_assessment\_models\_rivernetwork\_filled.csv**.

_3\_Finalize\_and\_plot.R_

The final script creates statistics, spatial results and draws a map of the stations being compatible for all models. The column "DNassmt" is added to the station and basin file which contains the information as
0: original station coordinates not in co-registered DDM30 grid cell
1: original station coordinates within co-registered DDM30 grid cell but upstream basin area < 50.000 km²
2: original station coordinates within co-registered DDM30 grid cell, upstream basin area > 50.000 km²
3: as 2 but compatible with all models of the assessment

Furthermore, the result of the visual inspection has been added (one column per model). A "0" jointly with a value below 2 in column DNassmt indicates here that this station is not selected for the visual inspection.

Processing steps

| **Input Name** | **Description** | **Output Name** | **Description** |
|---|---|---|---|
| **WaterGAP22e\_cal\_stat\_moveddm30.shp** | WaterGAP 2.2e calibration stations as shapefile including information of station re-location | **assessment\_models\_basins.shp** | discharge stations with information about the drainage network assessment |
| **WaterGAP22e\_cal\_bas.shp** | basins of the WaterGAP 2.2e calibration stations as shapefile | **assessment\_models\_basins.shp** | basins with information about the drainage network assessment |
| | | **assessment\_models\_rivernetwork_filled.csv** | csv sheet with documentation of alignment between station and river network |
| | | **compatible\_dn\_all\_models\_stat.shp** | shapefile for stations with the subset of all compatible stations |
