#!/usr/bin/env Rscript

#Cancer Data Services - Submission Validation-R v1.3.3


##################
#
# USAGE
#
##################

#This takes a data file as input that is formatted to the submission template for CDS v1.3.

#Run the following command in a terminal where R is installed for help.

#Rscript --vanilla CDS-Submission_ValidationR.R --help

##################
#
# Env. Setup
#
##################

#List of needed packages
list_of_packages=c("dplyr","readr","stringi","janitor","readxl","optparse")

#Based on the packages that are present, install ones that are required.
new.packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
suppressMessages(if(length(new.packages)) install.packages(new.packages))

#Load libraries.
suppressMessages(library(dplyr,verbose = F))
suppressMessages(library(readr,verbose = F))
suppressMessages(library(stringi,verbose = F))
suppressMessages(library(janitor,verbose = F))
suppressMessages(library(readxl,verbose = F))
suppressMessages(library(optparse,verbose = F))

#remove objects that are no longer used.
rm(list_of_packages)
rm(new.packages)


##################
#
# Arg parse
#
##################

#Option list for arg parse
option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="dataset file (.xlsx, .tsv, .csv)", metavar="character"),
  make_option(c("-t", "--template"), type="character", default=NULL, 
              help="dataset template file, CDS_submission_metadata_template-v1.3.xlsx", metavar="character")
)

#create list of options and values for file input
opt_parser = OptionParser(option_list=option_list, description = "\nCDS-Submission_ValidationR v.1.3.3")
opt = parse_args(opt_parser)

#If no options are presented, return --help, stop and print the following message.
if (is.null(opt$file)&is.null(opt$template)){
  print_help(opt_parser)
  cat("Please supply both the input file (-f) and template file (-t), CDS_submission_metadata_template-v1.3.xlsx.\n\n")
  suppressMessages(stop(call.=FALSE))
}

#Data file pathway
file_path=opt$file

#Template file pathway
template_path=opt$template

#A start message for the user that the validation is underway.
cat("The data file is being validated at this time.\n")


###############
#
# Start write out
#
###############

#Rework the file path to obtain a file name, this will be used for the output file.
file_name=stri_reverse(stri_split_fixed(str = stri_reverse(file_path), pattern="/",n = 2)[[1]][1])

ext=tolower(stri_reverse(stri_split_fixed(str = stri_reverse(file_name),pattern = ".",n=2)[[1]][1]))

#Output file name based on input file name and date/time stamped.
output_file=paste(file_name,
                  "_validation_output_",
                  stri_replace_all_fixed(
                    str = stri_replace_all_fixed(
                      str = stri_replace_all_fixed(
                        str = Sys.time(),
                        pattern = ":",
                        replacement = "_"),
                      pattern = "-",
                      replacement = "_"),
                    pattern = " ",
                    replacement = "_"),
                  ".txt",
                  sep="")

#Start writing in the outfile.
sink(output_file)

cat(paste("This is a validation output for ",file_name,".\n",sep = ""))


###############
#
# Expected sheets to check
#
###############

#Pull sheet names
sheet_names=excel_sheets(path = template_path)
sheet_gone=0

#Expected sheet names based on v1.3
expected_sheets=c("README and INSTRUCTIONS",
                  "Metadata",
                  "Dictionary",             
                  "Terms and Value Sets")

#Test to see if expected sheet names are present.
if (all(expected_sheets%in%sheet_names)){
  cat("PASS: Found expected sheets in the submitted template file.\n")
  }else{
    sheet_gone=1
  }

#If any sheet is missing, throw an overt error message then stops the process. This script pulls information from the expected sheets and requires all sheets present before running.

template_warning="\n\n##################################################################################################################\n#                                                                                                                #\n# Please obtain a new data template with all sheets and columns present before making further edits to this one. #\n#                                                                                                                #\n##################################################################################################################\n\n\n"

if (sheet_gone==1){
  stop(paste("\nThe following sheet(s) is/are missing in the template file: ",paste(expected_sheets[!expected_sheets%in%sheet_names],collapse = ", "), template_warning, sep = ""), call.=FALSE)
}


####################
#
# Finding expected/required columns
#
####################

#Read in Dictionary page to obtain the required properties.
df_dict=suppressMessages(read_xlsx(path =template_path,sheet = "Dictionary"))
df_dict=remove_empty(df_dict,c('rows','cols'))

#Look for all entries that have a value
all_properties=unique(df_dict$Field)[grep(pattern = '.',unique(df_dict$Field))]
#Remove all entries that are all spaces
all_properties=all_properties[!grepl(pattern = " ",x = all_properties)]
#Remove the Field column header that is repeated
all_properties=all_properties[!grepl(pattern = "Field",x = all_properties)]
#Pull out required properties
required_properties=df_dict$Field[grep(pattern = "Yes",x = df_dict$`Required?`)]


#Read in metadata page/file to check against the expected/required properties. 
#Further logic has been setup to accept the original XLSX as well as a TSV or CSV format.
if (ext == "tsv"){
  df=suppressMessages(read_tsv(file = file_path, guess_max = 1000000, col_types = cols(.default = col_character())))
}else if (ext == "csv"){
  df=suppressMessages(read_csv(file = file_path, guess_max = 1000000, col_types = cols(.default = col_character())))
}else if (ext == "xlsx"){
  df=suppressMessages(read_xlsx(path = file_path,sheet = "Metadata", guess_max = 1000000, col_types = "text"))
}else{
  stop("\n\nERROR: Please submit a data file that is in either xlsx, tsv or csv format.\n\n")
}

#If a required column was deleted, it will throw an error and ask the user to obtain a new template.
col_gone=0

if (all(all_properties%in%colnames(df))){
  cat("PASS: Found expected columns for the Metadata sheet.\n")
  }else{
    col_gone=1
    missing=all_properties[!all_properties%in%colnames(df)]
    for (missing_prop in missing){
      if (missing_prop%in%required_properties){
        cat(paste("ERROR: The Metadata sheet is missing the following required column: ",missing_prop,".\n",sep = ""))
      }else{
        cat(paste("ERROR: The Metadata sheet is missing the following column: ",missing_prop,".\n",sep = ""))
      }
    }
  
  #Make it very obvious that the user should not continue with the current template file as it does not contain all expected information.
  if (col_gone==1){
    cat(template_warning)
  }
}


####################
#
# Finding required property completeness
#
####################

#For the required columns that are present, it will check to make sure there are no completely empty columns. If there are only partially filled required columns or the values within the required column contain leading and/or trailing white space, it will return those row positions for the required columns.
for (property in required_properties){
  if (property%in%colnames(df)){
    #Return if required column is empty
    if (all(is.na(df[property]))){
      cat(paste("ERROR: All values are missing for the required ",property," property, on the Metadata sheet. Please enter values in this property.\n", sep = ""))
    }else{
      df_temp=df
      for (x in 1:dim(df[property])[1]){
      df_temp[property][x,]=trimws(df[property][x,])
      }
      #Return value positions that are either empty (NA) or contain leading/trailing white space in the value for the required column.
      if (!all(df_temp[property]==df[property]) | any(is.na(df_temp[property]==df[property]))){
        position_mis=grep(pattern = FALSE, x = df_temp[property]==df[property])
        position_na=grep(pattern = TRUE, x=(is.na(df_temp[property]==df[property])))
        position=c(position_mis,position_na)
        cat(paste("ERROR: Missing values and/or leading/trailing white space in the required ",property," property, on the Metadata sheet. Please check the following position: ", position,"\n", sep = ""))
      }else{
        #Required column contains values for each entry.
      cat(paste("PASS: Required property ",property," contains values for all entries.\n",sep = ""))
      }
    }
  }
}

##################
#
# Terms and Value sets
#
##################

#Read in Terms and Value sets page to obtain the required value set names.
df_tavs=suppressMessages(read_xlsx(path = template_path, sheet = "Terms and Value Sets"))
df_tavs=remove_empty(df_tavs,c('rows','cols'))

#Pull out the positions where the value set names are located
VSN=grep(pattern = FALSE, x = is.na(df_tavs$`Value Set Name`))

df_all_terms=list()

#for each instance of a value_set_name, note the position on the Terms and Value Sets page, create a list for each with all accepted values.
for (x in 1:length(VSN)){
  if (!is.na(VSN[x+1])){
    df_all_terms[as.character(df_tavs[VSN[x],1])] = as.vector(df_tavs[VSN[x]:(VSN[x+1])-1,3])
  }else{
    df_all_terms[as.character(df_tavs[VSN[x],1])] = as.vector(df_tavs[VSN[x]:dim(df_tavs)[1],3])
  }
}

#Use the list of all accepted values for each value_set_name, and compare that against the Metadata page and determine if the values, if present, match the accepted terms.
for (value_set_name in names(df_all_terms)){
  if (value_set_name%in%colnames(df)){
    if (!all(((unique(df[value_set_name][[1]]))%in%df_all_terms[value_set_name][[1]]))){
      for (x in 1:dim(unique(df[value_set_name]))[1]){
        check_value=unique(df[value_set_name])[x,]
        if (!is.na(check_value)){
          if (!grepl(pattern = check_value, x = df_all_terms[value_set_name])){
            cat(paste("ERROR: ",value_set_name," property contains a value that is not recognized: ", check_value,"\n",sep = ""))
          }
        }
      }
    }else{
      cat(paste("PASS:",value_set_name,"property contains all valid values.\n"))
    }
  }
}


#################
#
# Stop write out
#
#################

#Stop write out to file and display "done message" on command line.
sink()

cat(paste('Please see the following file, ',output_file,', to determine which parts passed or contained errors.\n',sep = ""))
