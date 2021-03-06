###################################################################################"
# File create to build excel files sent to persons responsible for recruitment data
# Author Cedric Briand
# This script will create an excel sheet per country that currently have recruitment series
#######################################################################################
# put the current year there
CY<-2018
# function to load packages if not available
load_library=function(necessary) {
	if(!all(necessary %in% installed.packages()[, 'Package']))
		install.packages(necessary[!necessary %in% installed.packages()[, 'Package']], dep = T)
	for(i in 1:length(necessary))
		library(necessary[i], character.only = TRUE)
}
###########################
# Loading necessary packages
############################
load_library("sqldf")
load_library("RPostgreSQL")
load_library("stacomirtools")
load_library("stringr")
load_library("XLConnect")
#############################
# here is where the script is working change it accordingly
##################################
#setwd("C:/workspace/wgeel/sweave")
#wd<-getwd()
#############################
# here is where you want to put the data. It is different from the code
# as we don't want to commit data to git
# read git user 
##################################
wddata<-"C:/Users/cboulenger/Documents/test_wgeel"
#####################################
# Finally we store the xl data in a sub chapter
########################################
dataxl<-str_c(wddata,"/",CY,"/xl/")
###################################
# this set up the connextion to the postgres database
# change parameters accordingly
###################################"

source("R/database_interaction/database_connection.R")


#############################
# Table storing information from the database
##################################
t_eelstock_eel<-sqldf("SELECT 
eel_id,
eel_typ_id,
eel_year,
eel_value,
eel_emu_nameshort,
eel_cou_code,
eel_lfs_code,
eel_hty_code,
eel_area_division,
eel_qal_id,
eel_qal_comment,
eel_comment,
eel_datelastupdate,
eel_missvaluequal,
eel_datasource,
eel_dta_code,
qal_kept,
typ_name
FROM datawg.t_eelstock_eel 
left join ref.tr_quality_qal on eel_qal_id=tr_quality_qal.qal_id 
left join ref.tr_typeseries_typ on eel_typ_id=typ_id;")



#' function to create the data sheet 
#' 
#' @note this function writes the xl sheet for each country
#' it creates series metadata and series info for ICES station table
#' loop on the number of series in the country to create as many sheet as necessary
#' 
#' @param country the country name, for instance "Sweden"
createx_all<-function(country,eel_typ){
  
  #cat("work begun for",country," and ",eel_typ)
  
  
  #create a folder for the country
  
  dir.create(str_c(dataxl,country),showWarnings = FALSE)
  
  #select the data
  if (eel_typ %in% c(4,5,6,7)){
    
    r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id %in% c(4,5,6,7),]
    data_type<-"landings"
    
    }else if (eel_typ %in% c(8,9,10)){
      
      r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id %in% c(8,9,10),]
      data_type<-"releases"
        
      }else if (eel_typ %in% c(11,12)){
        
        r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id %in% c(11,12),]
        data_type<-"aquaculture"
        
      }else if (eel_typ %in% c(13,14,15)){
        
        r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id %in% c(13,14,15),]
        data_type<-"biomass_indicators"
      }else if (eel_typ %in% c(17:25)){
        
        r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id %in% c(17:25),]
        data_type<-"mortality_rate"
        
        }else if (eel_typ %in% c(26:31)){
        
          r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id %in% c(26:31),]
          data_type<-"mortality_see"
          
          }else if (eel_typ %in% c(32:33)){
          
            r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id %in% c(32:33),]
            data_type<-"other_landings"
            
          }else{
            
            r_coun<-t_eelstock_eel[t_eelstock_eel$eel_cou_code==country & t_eelstock_eel$eel_typ_id==16,]
            data_type<-"habitats"
            
          }
    
      # if no data available for these type of data then we don't create a file
      if (nrow(r_coun)==0){print(paste("data are not available for eel_typ_id ",eel_typ," and ",country, sep=""))
     
         }else{
    
      ## reorder data columns so type names is next to eel_type_id      
      r_coun<-data.frame(r_coun[, 1:2],typ_name=r_coun[,ncol(r_coun)],r_coun[,3:17])     
      ## separate sheets for discarded and keeped data  
      data_kept<-r_coun[which(r_coun$eel_qal_id==TRUE),]
      data_kept<-data_kept[,-ncol(r_coun)]
      
      data_disc<-r_coun[!(r_coun$eel_qal_id==TRUE),]
      data_disc<-data_disc[,-ncol(r_coun)]
      
      
      xls.file<-str_c(dataxl,country,"/",country,CY,data_type,".xls")
      wb = loadWorkbook(xls.file, create = TRUE)
      createSheet(wb,paste(data_type,"_discarded",sep=""))
      writeWorksheet (wb , data_disc , sheet=paste(data_type,"_discarded",sep="") ,header = TRUE )
      createSheet(wb,paste(data_type,"_kept",sep=""))
      writeWorksheet (wb , data_kept , sheet=paste(data_type,"_kept",sep="") ,header = TRUE )
      saveWorkbook(wb)	

    	cat("work finished",country," and ",eel_typ,"\n")
      }
}	
	
# lselect the countries and the typ_id you have
cou_code<-unique(t_eelstock_eel$eel_cou_code)
typ_id<-unique(t_eelstock_eel$eel_typ_id)

# create an excel file for each of the countries and each typ_id

for (i in cou_code){
  
  for (j in typ_id){
    
    createx_all(i,j)
  }
}


