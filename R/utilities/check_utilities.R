# check utilities
# functions to check that the code entered in the database is correct
# Author: cedric.briand
###############################################################################




#' check for missing values
#' 
#' @param dataset the name of the dataset
#' @param column the name of the column
#' @param country the current country being evaluated
check_missing <- function(dataset,column,country){
  answer = NULL
  if (any(is.na(dataset[,column]))){
    line<-(1:nrow(dataset))[is.na(dataset[,column])]
    if (length(line)>10) line <-str_c(str_c(line[1:10],collapse=";"),"...") else
      line <- str_c(line) # before it was str_c(line, collapse=";") but it was crashing when checking for duplicates
    if (length(line)>0){
      cat(sprintf("column <%s>, missing values line %s \n",
                  column,
                  line))
      answer  = data.frame(nline = line, error_message = paste0("missing value in column: ", column))
    }
  }
  return(answer)
}

#' check_values
#' 
#' check the values in the current column against a list of values, missing values are removed
#' prior to assessment
#' @param dataset the name of the dataset
#' @param column the name of the column
#' @param country the current country being evaluated

check_values <- function(dataset,column,country,values){
  answer = NULL
  newdataset <- dataset
  newdataset$nline <- 1:nrow(newdataset)
  # remove NA from data
  ddataset <- as.data.frame(newdataset[!is.na(newdataset[,column]),])
  if (nrow(ddataset)>0){ 
    #line<-(1:nrow(dataset))[is.na(dataset[,column])]# there might be NA, this will have been tested elsewhere
    if (! all(ddataset[,column]%in%values)) { # are all values matching ?
      value <- str_c(unique(ddataset[,column][!ddataset[,column]%in%values]),collapse=";")
      line <- ddataset$nline[!ddataset[,column]%in%values]
      if (length(line)>0){
        cat(sprintf("column <%s>, line <%s>, value <%s> is wrong \n",                   
                    column,
                    line,
                    value))
        
        answer  = data.frame(nline = line , error_message = paste0("value in column: ", column, " is wrong"))
      }
    }
  }
  return(answer)
}


#' check_type
#' 
#' check for a specific type, e.g. numeric or character
#' @param dataset the name of the dataset
#' @param column the name of the column
#' @param country the current country being evaluated
#' @param type, a class described as a character e.g. "numeric"

check_type <- function(dataset,column,country,values,type){
  answer = NULL
  newdataset <- dataset
  newdataset$nline <- 1:nrow(newdataset)
  #remove NA from data
  ddataset <- as.data.frame(newdataset[!is.na(newdataset[,column]),])
  if (nrow(ddataset)>0){ 
    
    if (type=="numeric") { # cant check for a numeric into a character
      options("warn"=1)
      ddataset[,column]<-as.numeric(ddataset[,column]) # creates a warning message because of NAs introduced by coercion
      options("warn"=0)
      line <- ddataset$nline[is.na(ddataset[,column])]
      if (length(line)>0){
        cat(sprintf("column <%s>, line <%s>,  should be of type %s \n",
                    column,
                    line,
                    type))
        
        answer  = data.frame(nline = line, error_message = paste0("error type in: ", column))
      }
    }
  }
  return(answer)  
}



#' check_unique
#' 
#' check that there is only one value in the column
#' @param dataset the name of the dataset
#' @param column the name of the column
#' @param country the current country being evaluated
#' @param type, a class described as a character e.g. "numeric"
check_unique <- function(dataset,column,country){
  answer = NULL
  newdataset <- dataset
  newdataset$nline <- 1:nrow(newdataset)
  # remove the NA
  ddataset <- as.data.frame(newdataset[!is.na(newdataset[,column]),])
  
  if (length(unique(ddataset[,column])) != 1) {   
    line <- ddataset$nline[which(ddataset[,column] != country)]
    if (length(line)>0){
    cat(sprintf("column <%s>, line <%s> , should only have one value \n",
            column,
            line))
    
    answer  = data.frame(nline = line, error_message = paste("different country name in: ", column, sep = ""))
  return(answer)  
    }
  }
}



#' check_missvaluequal
#' 
#' check that there are data in missvaluequal only when there are missing value (NA) is eel_value
#' @param dataset the name of the dataset
#' @param column the name of the column
#' @param country the current country being evaluated
#' @param type, a class described as a character e.g. "numeric"
check_missvaluequal <- function(dataset,country){
  answer1 = NULL
  answer2 = NULL
  # tibbles are weird, change to dataframe
  ddataset<-as.data.frame(dataset)
  # first check that any value in eel_missvaluequal corresponds to a NA in eel_value
  # get the rows where a label has been put
  if (! all(is.na(ddataset[,"eel_missvaluequal"]))){
    # get eel_values where missing has been filled in
    lines<-which(!is.na(ddataset[,"eel_missvaluequal"]))
    eel_values_for_missing <-ddataset[lines,"eel_value"]
    if (! all(is.na(eel_values_for_missing))) {
      line1 <- lines[!is.na(eel_values_for_missing)]
      if (length(line1)>0){
        cat(sprintf("column <%s>, lines <%s>, there is a code, but the eel_value field should be empty \n",
                    "eel_missvaluequal",
                    line1))
        
        answer1  = data.frame(nline = line1, error_message = paste("there is a code in eel_missvaluequal, but the eel_value field should be empty", sep = ""))
      }
    }
  }
  # now check of missing values do all get a comment
  # if there is any missing values
  if (any(is.na(ddataset[,"eel_value"]))){
    # get eel_values where missing has been filled in
    lines<-which(is.na(ddataset[,"eel_value"]))
    eel_missingforvalues <-ddataset[lines,"eel_missvaluequal"]
    # if in those lines, one missing value has not been commented upon
    if (any(is.na(eel_missingforvalues))) {
      line2 <- lines[is.na(eel_missingforvalues)]
      if (length(line2)>0){
        cat(sprintf("column <%s>, lines <%s>, there should be a code, as the eel_value field is missing \n",
                    "eel_missvaluequal",
                    line2))
        
        answer2  = data.frame(nline = line2, error_message = paste("there should be a code in eel_missvaluequal, as the eel_value field is missing", sep = ""))
      }
    }
  }
  return(rbind(answer1, answer2))  
}


#' check_missvalue_restocking
#' 
#' check if there is data in eel_value_number and eel_value_kg
#' if there is data in eel_value_number or eel_value_kg, give warring to the user to fill the missing value 
#' if there is data in neither eel_value_number and eel_value_kg, check if there are data in missvaluequa 
#' 
#' @param dataset the name of the dataset
#' @param column the name of the column
#' @param country the current country being evaluated
#' @param type, a class described as a character e.g. "numeric"
#' 
check_missvalue_release <- function(dataset,country){
  answer1 = NULL
  answer2 = NULL
  answer3 = NULL
  # tibbles are weird, change to dataframe
  ddataset<-as.data.frame(dataset)
  # first check that any value in eel_missvaluequal corresponds to a NA in eel_value_number and eel_value_kg
  # get the rows where a label has been put
  if (! all(is.na(ddataset[,"eel_missvaluequal"]))){
    # get eel_values where missing has been filled in
    lines<-which(!is.na(ddataset[,"eel_missvaluequal"]))
    eel_values_for_missing <-ddataset[lines,c("eel_value_number","eel_value_kg")]
    if (! all(is.na(eel_values_for_missing))) {
      line1 <- lines[!is.na(eel_values_for_missing)]
      if (length(line1)>0){
      cat(sprintf("column <%s>, lines <%s>, there is a code, but the eel_value_number and eel_value_kg field should be empty \n",
                  "eel_missvaluequal",
                  line1 ))
      answer1 <- data.frame(nline = line1, error_message = paste(" there is a code in eel_missvaluequal but the eel_value_number and eel_value_kg field should be empty" ))
      }
    }
  }
  # now check of missing values do all get a comment
  # if there is any missing values
  if (all(is.na(ddataset[,c("eel_value_number","eel_value_kg")]))){
    # get eel_values where missing has been filled in
    lines<-which(is.na(ddataset[,c("eel_value_number","eel_value_kg")]))
    eel_missingforvalues <-ddataset[lines,"eel_missvaluequal"]
    # if in those lines, one missing value has not been commented upon
    if (any(is.na(eel_missingforvalues))) {
      line2 <- lines[is.na(eel_missingforvalues)]
      if (length(line2)>0){
      cat(sprintf("column <%s>, lines <%s>, there should be a code, as the eel_value_number and eel_value_kg fields are both missing \n",
                  "eel_missvaluequal",
                  line2 ))
        answer2 <- data.frame(nline = line2, error_message = paste("there should be a code in eel_missvaluequal as the eel_value_number and eel_value_kg fields are both missing"))
      }
    }
  }
  
  # now check if there is data in eel_value_number or eel_value_kg, give warring to the user to fill the missing value 
  # if there is any missing values
    if (any(is.na(ddataset[,c("eel_value_number","eel_value_kg")]))){
    # get eel_values where missing has been filled in
    line3<-which(is.na(ddataset[,c("eel_value_number","eel_value_kg")]))
    if (length(line3)>0){
    # if in those lines, one missing value has not been commented upon
      cat(sprintf("column <%s>, lines <%s>, there should be a value in both column eel_value_number and eel_value_kg \n",
                  "eel_missvaluequal",
                  line3))
      answer3 <- data.frame(nline = line3, error_message = paste("there should be a value in both column eel_value_number and eel_value_kg"))   
        }
    }
  return(rbind(answer1,answer2,answer3))  
}


#' check_positive
#' 
#' check that the data in ee_value is positive
#' 
#' @param dataset the name of the dataset
#' @param column the name of the column
#' @param country the current country being evaluated
#' @param type, a class described as a character e.g. "numeric"
#' 
check_positive <- function(dataset,column,country){
  answer = NULL
  newdataset <- dataset
  newdataset$nline <- 1:nrow(newdataset)
  #remove NA from data
  ddataset <- as.data.frame(newdataset[!is.na(newdataset[,column]),])
  if (nrow(ddataset)>0){
    line<-which(ddataset[,column]<0)
    if (length(line)>0){
      cat(sprintf("Country <%s>,  dataset <%s>, column <%s>, line <%s>,  should be a positive value \n",
                  country,
                  deparse(substitute(dataset)),
                  column,
                  line))
      answer  = data.frame(nline = line, error_message = paste("negative value in: ", column, sep = ""))
    }
  }
  return(answer)  
}


#' check if there is an ICES area division for freshwater data
#' prior to assessment
#' @param dataset the name of the dataset
#' @param country the current country being evaluated
check_freshwater_without_area <- function(dataset,country){
  #browser()
  answer = NULL
  newdataset <- dataset
  newdataset$nline <- 1:nrow(newdataset)
  # remove NA from data
  ddataset <- as.data.frame(newdataset[
    !is.na(newdataset[,"eel_area_division"]) &
      newdataset[,"eel_hty_code"]=="F" &
      !is.na(newdataset[,"eel_hty_code"]),]
  )   
  if (nrow(ddataset)>0){ 
    line <- ddataset$nline
    if (length(line)>0){
      cat(sprintf("line <%s>, there should not be any area divsion in freshwater \n",                   
                  line))
      
      answer  = data.frame(nline = line , error_message = paste0("there should not be any area divsion in freshwater"))
    }
    
  }
  return(answer)
}