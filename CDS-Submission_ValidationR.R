#!/usr/bin/env Rscript

#Cancer Data Services - Submission Validation-R v2.0.1


##################
#
# USAGE
#
##################

#This takes a data file as input that is formatted to the submission template for CDS.

#Run the following command in a terminal where R is installed for help.

#Rscript --vanilla CDS-Submission_ValidationR.R --help

##################
#
# Env. Setup
#
##################

#List of needed packages
list_of_packages=c("dplyr","tidyr","readr","stringi","janitor","readxl","optparse","tools")

#Based on the packages that are present, install ones that are required.
new.packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
suppressMessages(if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org"))

#Load libraries.
suppressMessages(library(dplyr,verbose = F))
suppressMessages(library(readr,verbose = F))
suppressMessages(library(tidyr,verbose = F))
suppressMessages(library(stringi,verbose = F))
suppressMessages(library(janitor,verbose = F))
suppressMessages(library(readxl,verbose = F))
suppressMessages(library(optparse,verbose = F))
suppressMessages(library(tools,verbose = F))

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
              help="dataset template file, CDS_submission_metadata_template.xlsx", metavar="character")
)

#create list of options and values for file input
opt_parser = OptionParser(option_list=option_list, description = "\nCDS-Submission_ValidationR v2.0.1")
opt = parse_args(opt_parser)

#If no options are presented, return --help, stop and print the following message.
if (is.null(opt$file)&is.null(opt$template)){
  print_help(opt_parser)
  cat("Please supply both the input file (-f) and template file (-t), CDS_submission_metadata_template.xlsx.\n\n")
  suppressMessages(stop(call.=FALSE))
}

#Data file pathway
file_path=file_path_as_absolute(opt$file)

#Template file pathway
template_path=file_path_as_absolute(opt$template)

#A start message for the user that the validation is underway.
cat("The data file is being validated at this time.\n")


###############
#
# Start write out
#
###############

#Rework the file path to obtain a file name, this will be used for the output file.
file_name=stri_reverse(stri_split_fixed(stri_reverse(basename(file_path)),pattern = ".", n=2)[[1]][2])
ext=tolower(stri_reverse(stri_split_fixed(stri_reverse(basename(file_path)),pattern = ".", n=2)[[1]][1]))
path=paste(dirname(file_path),"/",sep = "")

#Output file name based on input file name and date/time stamped.
output_file=paste(file_name,
                  "_Validate",
                  stri_replace_all_fixed(
                    str = Sys.Date(),
                    pattern = "-",
                    replacement = ""),
                  sep="")

#Start writing in the outfile.
sink(paste(path,output_file,".txt",sep = ""))

cat(paste("This is a validation output for ",file_name,".\n\n",sep = ""))


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
template_warning="\n\n################################################################################################################################\n#                                                                                                                              #\n# ERROR: Please obtain a new data template with all sheets and columns present before making further edits to this one.        #\n#                                                                                                                              #\n################################################################################################################################\n\n\n"

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
#Pull out required property groups
required_property_groups=unique(df_dict$`Required?`[!is.na(df_dict$`Required?`)])
required_properties=df_dict$Field[!is.na(df_dict$`Required?`)]

#Read in metadata page/file to check against the expected/required properties. 
#Further logic has been setup to accept the original XLSX as well as a TSV or CSV format.
if (ext == "tsv"){
  df=suppressMessages(read_tsv(file = file_path, guess_max = 1000000, col_types = cols(.default = col_character(),),trim_ws = FALSE))
}else if (ext == "csv"){
  df=suppressMessages(read_csv(file = file_path, guess_max = 1000000, col_types = cols(.default = col_character()), trim_ws = FALSE))
}else if (ext == "xlsx"){
  df=suppressMessages(read_xlsx(path = file_path,sheet = "Metadata", guess_max = 1000000, col_types = "text",trim_ws = FALSE))
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

cat("\nThis section is for required properties and their required groups, seen on the 'Dictionary' page of the template file.\nFor each row entry, if any value is in a required column, then all properties for that required group must also have values for that row entry:\n\n")

#For blocks of required columns, it will check if all required columns have values if any one required column have a value. If there are only partially filled rows for required columns or the values within the required column contain leading and/or trailing white space, it will return those row positions for the required columns.

for (required_property_group in required_property_groups){
  required_properties_dict=df_dict$Field[grepl(pattern = required_property_group,x = df_dict$`Required?`)]
  required_properties=colnames(df[colnames(df)%in%required_properties_dict])
  
  #Clean up the data frame, if the required property section was left completely blank, it is assumed that the user did not have data for that row. Thus, it will only compare to rows that have complete data.
  df_property_clean=remove_empty(df[required_properties],c('cols','rows'))
  
  #Counter used later for ignoring purposely empty groups of required information
  incomplete_required_group=0
  
  #Test to see if the number of columns are the same or if a complete property was ignored.
  if (dim(df_property_clean)[2]!=dim(df[required_properties])[2]){
    if (!all(is.na(df[required_properties]))){
      missing_col=colnames(df[required_properties][!colnames(df[required_properties])%in%colnames(df_property_clean)])
      cat(paste("ERROR: Column from a required group of properties, ",required_property_group,", was found empty on the Metadata sheet. Please add values for the following columns: ", missing_col,"\n", sep = ""))
    }
  #Test to see if there are complete cases, values for all properties.    
  }else if(!all(complete.cases(df[required_properties]))){
    for (row in 1:dim(df[required_properties])[1]){
      if (!complete.cases(df[required_properties][row,])){
        #if a row was left completely blank, assumed to be on purpose, then it will be skipped.
        if (!all(is.na(df[required_properties][row,]))){
          cat(paste("ERROR: Missing values were found in the required property group ",required_property_group,", on the Metadata sheet. Please check the following row: ", row+1,"\n", sep = ""))
          incomplete_required_group=1
        }
      }
    }
    #if there was not one instance of tripping the incomplete_required_group flag, then it will print that values are present for complete rows of required data for a required group.
    if (incomplete_required_group==0){
      cat(paste("WARNING: Required property group ",required_property_group," contains values for all entries that are assumed to have values based on the submitted data structure.\n",sep = ""))
    }
  }else{
    #if none of these situations are triggered, then the column likely has all values present in the required property group for each entry.
    cat(paste("PASS: Required property group ",required_property_group," contains values for all expected entries.\n",sep = ""))
  }
  #This section will check against white space in the values of each column when there is a value present.
  for (property in required_properties){
    if (property %in% colnames(df)){
      df_temp=df
      incomplete_required_property=0
      for (x in 1:dim(df[property])[1]){
        df_temp[property][x,]=trimws(df[property][x,])
      }
      #Return value positions that are either empty (NA) or contain leading/trailing white space in the value for the required column.
      if (!all(df_temp[property]==df[property]) | any(is.na(df_temp[property]==df[property]))){
        position_mis=grep(pattern = FALSE, x = df_temp[property]==df[property])
        position_na=grep(pattern = TRUE, x=(is.na(df_temp[property]==df[property])))
        position=c(position_mis,position_na)
        for (instance in position){
          if (!all(is.na(df_temp[required_properties][instance,]))){
            cat(paste("ERROR: Missing values and/or leading/trailing white space in the required ",property," property, on the Metadata sheet. Please check the following position: ", instance+1,"\n", sep = ""))
            incomplete_required_property=1
          }
        }
        #Returns a warning that there is likely empty rows on purpose due to not all entries having a value for that section of required input.
        if (incomplete_required_property==0 & !all(is.na(df[required_properties]))){
          cat(paste("WARNING: Required property ",property," contains values for all entries that are assumed to have values based on the submitted data structure.\n",sep = ""))
        }
      }else{
        #Required column contains values for each entry.
        if(incomplete_required_property==0 & incomplete_required_group==0){
          cat(paste("PASS: Required property ",property," contains values for all expected entries.\n",sep = ""))
        }
      }
    }
  }
  #For the '_id' properties, make sure there are no illegal characters and it only has "Only the following characters can be included in the ID: English letters, Arabic numerals, period (.), hyphen (-), underscore (_), at symbol (@), and the pound sign (#)."
  for (property in required_properties){
    if (property %in% colnames(df)){
      if (grepl(pattern = "_id", x = property)){
        bad_id_loc=grep(pattern = FALSE, x = grepl(pattern = '^[a-zA-Z0-9_.@#-]*$', x = df[property][[1]]))
        if (length(bad_id_loc)>0){
          for (bad_id in bad_id_loc){
            if (!is.na(df[property][[1]][bad_id])){
              cat(paste("\nERROR: The following ID, ",df[property][[1]][bad_id], ", has an illegal character (acceptable: A-z,0-9,_,.,-,@,#) in the property, ",property,".",sep = ""))
            }
          }
        }
      }
    }
  }
}

#Define the required properties again.
required_properties=df_dict$Field[!is.na(df_dict$`Required?`)]

#Check for white space issues in non-required columns. There is no enforcement that a column has to be completely filled or have values based on other related data inputs.
for (property in all_properties[!all_properties%in%required_properties]){
  if (property%in%colnames(df)){
    if(any(!is.na(unique(df[property])))){
      df_temp=df
      for (x in 1:dim(df[property])[1]){
        df_temp[property][x,]=trimws(df[property][x,])
      }
      if (!all(df_temp[property]==df[property]) | any(is.na(df_temp[property]==df[property]))){
        position_mis=grep(pattern = FALSE, x = df_temp[property]==df[property])
        position_na=grep(pattern = TRUE, x=(is.na(df_temp[property]==df[property])))
        position=c(position_mis,position_na)
        for (instance in position){
          if (!all(is.na(df_temp[property][instance,]))){
            cat(paste("ERROR: Leading/trailing white space in the ",property," property, on the Metadata sheet. Please check the following position: ", instance+1,"\n", sep = ""))
          }
        }
      }
    }
  }
}


##################
#
# Terms and Value sets
#
##################

cat("\nThe following columns have controlled vocabulary on the 'Terms and Value Sets' page of the template file:\n\n")

#Read in Terms and Value sets page to obtain the required value set names.
df_tavs=suppressMessages(read_xlsx(path = template_path, sheet = "Terms and Value Sets"))
df_tavs=remove_empty(df_tavs,c('rows','cols'))

#Pull out the positions where the value set names are located
VSN=grep(pattern = FALSE, x = is.na(df_tavs$`Value Set Name`))

df_all_terms=list()

#for each instance of a value_set_name, note the position on the Terms and Value Sets page, create a list for each with all accepted values.
for (x in 1:length(VSN)){
  if (!is.na(VSN[x+1])){
    df_all_terms[as.character(df_tavs[VSN[x],1])] = as.vector(df_tavs[VSN[x]:(VSN[x+1]-1),3])
    
  }else{
    df_all_terms[as.character(df_tavs[VSN[x],1])] = as.vector(df_tavs[VSN[x]:dim(df_tavs)[1],3])
  }
}

#Enumerated Array properties
enum_arrays=c('therapeutic_agents',"treatment_type","study_data_types","morphology","primary_site","race")

#Use the list of all accepted values for each value_set_name, and compare that against the Metadata page and determine if the values, if present, match the accepted terms.
for (value_set_name in names(df_all_terms)){
  if (value_set_name %in% enum_arrays){
    unique_values=unique(df[value_set_name][[1]])
    unique_values=unique(trimws(unlist(stri_split_fixed(str = unique_values,pattern = ";"))))
    unique_values=unique_values[!is.na(unique_values)]
    if (length(unique_values)>0){
      if (!all(unique_values%in%df_all_terms[value_set_name][[1]])){
        for (x in 1:length(unique_values)){
          check_value=unique_values[x]
          if (!is.na(check_value)){
            if (!as.character(check_value)%in%df_all_terms[value_set_name][[1]]){
              cat(paste("ERROR: ",value_set_name," property contains a value that is not recognized: ", check_value,"\n",sep = ""))
            }
          }
        }
      }else{
        cat(paste("PASS:",value_set_name,"property contains all valid values.\n"))
      }
    }
  }else if (value_set_name%in%colnames(df)){
    unique_values=unique(df[value_set_name][[1]])
    unique_values=unique_values[!is.na(unique_values)]
    if (length(unique_values)>0){
      if (!all(unique_values%in%df_all_terms[value_set_name][[1]])){
        for (x in 1:length(unique_values)){
          check_value=unique_values[x]
          if (!is.na(check_value)){
            if (!as.character(check_value)%in%df_all_terms[value_set_name][[1]]){
              cat(paste("ERROR: ",value_set_name," property contains a value that is not recognized: ", check_value,"\n",sep = ""))
            }
          }
        }
      }else{
        cat(paste("PASS:",value_set_name,"property contains all valid values.\n"))
      }
    }
  }
}


#################
#
# Participant check
#
#################

cat("\n\n")
participant_list=unique(df$participant_id)

for (participant in 1:length(participant_list)){
  gender=unique(df$gender[df$participant_id %in% participant_list[participant]])
  ethnicity=unique(df$ethnicity[df$participant_id %in% participant_list[participant]])
  race=unique(df$race[df$participant_id %in% participant_list[participant]])
  if (length(gender)>1){
    cat(paste("\nERROR:The following participant_id, ",participant_list[participant],", is linked to more than one value for gender.\n",sep = "" ))
  }
  if (length(ethnicity)>1){
    cat(paste("\nERROR: The following participant_id, ",participant_list[participant],", is linked to more than one value for ethnicity.\n",sep = "" ))
  }
  if (length(race)>1){
    cat(paste("\nERROR: The following participant_id, ",participant_list[participant],", is linked to more than one value for race.\n",sep = "" ))
  }
}


#################
#
# Library to sample check
#
#################

cat("\nThis submission and subsequent submission files derived from this template assume that a library_id is associated to only one sample_id.\nIf there are any unexpected values, they will be reported below:\n\n")

#For each library_id check to see how many instances it is found.
for (library_id in unique(df$library_id)){
  if(!is.na(library_id)){
    grep_instances=unique(df$sample_id[grep(pattern = library_id, x = df$library_id)])
    if (length(grep_instances)>1){
      cat(paste("WARNING: The library_id, ",library_id,", has multiple samples associated with it, ", grep_instances ,". This setup will cause issues when submitting to SRA.\n",sep = ""))
    }
  }
}


#################
#
# Require certain properties based on the file type.
#
#################

#For BAM, CRAM and Fastq files, we expect that all the files to have only one sample associated with them and the following properties: avg_read_length, coverage, bases, reads.

cat("\nThis submission and subsequent submission files derived from this template assume that FASTQ, BAM and CRAM files are single sample files, and contain all associated metadata for submission.\nIf there are any unexpected values, they will be reported below:\n\n")

#Gather all file types.
file_types=c("bam","cram","fastq")

#For each position, check to see if there are any samples that share the same library_id and make sure that the values for the required properties for SRA submission are present.      
for (file_type in file_types){
  single_sample_seq_files=grep(pattern = TRUE, x = tolower(df$file_type) %in% file_type)
  df_sssfi=select(df,file_name,file_size,file_type,md5sum)%>%mutate(index=1:dim(df)[1])
  df_sssfi=df_sssfi[single_sample_seq_files,]
  df_sssfu=unique(select(df_sssfi,-index))
  single_sample_seq_files_unique=c()
  #Match the unique rows with all the rows and their index number, and take the lowest index number as the input for the rest of the for loop to determine if the single sample file shares multiple sample ids.
  if (dim(df_sssfu)[1]!=0){
    for (urow in 1:dim(df_sssfu)[1]){
      min_num=min(df_sssfi[
        df_sssfi[,1][[1]] %in% df_sssfu[urow,1][[1]] &
          df_sssfi[,2][[1]] %in% df_sssfu[urow,2][[1]] &
          df_sssfi[,3][[1]] %in% df_sssfu[urow,3][[1]] &
          df_sssfi[,4][[1]] %in% df_sssfu[urow,4][[1]],
      ]["index"])
      single_sample_seq_files_unique=c(single_sample_seq_files_unique,min_num)
    }
  }
  #For each unique single sample file, make sure that the file is unique to the sample id. If not, throw a warning, as some of these files could share samples. Example: Two fastq files for a sample, a bam and a realigned bam for a sample, etc.
  for (file_location in single_sample_seq_files_unique){
    sample_id=df$sample_id[file_location]
    sample_id_loc=grep(pattern = sample_id, x = df$sample_id)
    if (any(single_sample_seq_files[!single_sample_seq_files %in% file_location]  %in% sample_id_loc)){
      sample_id_found=single_sample_seq_files[single_sample_seq_files %in% sample_id_loc]
      other_files=df$file_name[sample_id_found[!sample_id_found %in% file_location]]
      single_sample_seq_files=single_sample_seq_files[!single_sample_seq_files %in% file_location]
      cat(paste("WARNING: The sample_id",sample_id,"is associated with multiple single sample sequencing files:",df$file_name[file_location],other_files,"\n",sep = " "))
    }
  #Check to see if the expected SRA metadata is present for the files going to the SRA submission.
    bases_check= df$bases[file_location]
    avg_read_length_check=df$avg_read_length[file_location]
    coverage_check=df$coverage[file_location]
    reads_check=df$number_of_reads[file_location]
    #for fastq files, skips the checks for coverage values to be present
    if (file_type=="fastq"){
      SRA_checks=c(bases_check, avg_read_length_check, reads_check)
      if (any(is.na(SRA_checks))){
        cat(paste("ERROR: The file, ",df$file_name[file_location],", is missing at least one expected value (bases, avg_read_length, number_of_reads) that is associated with an SRA submission.\n",sep = ""))
      }
      if (!is.na(coverage_check)){
        cat(paste("WARNING: The file, ",df$file_name[file_location],", is not expected to have a coverage value.\n",sep = ""))
      }
    #for RNA-seq data, skips the checks for coverage values to be present
    }else if(!is.na(df$library_strategy[file_location]) & tolower(df$library_strategy[file_location])=="rna-seq"){
      SRA_checks=c(bases_check, avg_read_length_check, reads_check)
      if (any(is.na(SRA_checks))){
        cat(paste("ERROR: The file, ",df$file_name[file_location],", is missing at least one expected value (bases, avg_read_length, number_of_reads) that is associated with an SRA submission.\n",sep = ""))
      }
      if (!is.na(coverage_check)){
        cat(paste("WARNING: The file, ",df$file_name[file_location],", is not expected to have a coverage value.\n",sep = ""))
      }
    }else{
      SRA_checks=c(bases_check, avg_read_length_check, coverage_check, reads_check)
      if (any(is.na(SRA_checks))){
        cat(paste("ERROR: The file, ",df$file_name[file_location],", is missing at least one expected value (bases, avg_read_length, coverage, number_of_reads) that is associated with an SRA submission.\n",sep = ""))
      }
    }
  }
}


#################
#
# Check file metadata
#
#################

cat("\nIf there are columns that have unexpected values for files, they will be reported below:\n\n")

for (row_pos in 1:dim(df)[1]){
  if (!is.na(df$file_name[row_pos])){
    if (!is.na(df$file_size[row_pos])){
      if (df$file_size[row_pos]=="0"){
        cat(paste("WARNING: The file in row ",row_pos+1,", has a size value of 0. Please make sure that this is a correct value for the file.\n",sep = ""))
      }
    }
    if (!is.na(df$md5sum[row_pos])){
      if (!stri_detect_regex(str = df$md5sum[row_pos],pattern = '^[a-f0-9]{32}$',case_insensitive=TRUE)){
        cat(paste("ERROR: The file in row ",row_pos+1,", has a md5sum value that does not follow the md5sum regular expression.\n",sep = ""))
      }
    }
  }
}


###############
#
# AWS bucket file check
#
###############

cat("If there are unexpected values in the AWS buckets or files within the bucket, they will be reported below:\n\n")

#Obtain bucket information
df_bucket=select(df, file_url_in_cds)%>%
  separate(file_url_in_cds,into = c("s3","blank","bucket","the_rest"),sep = "/",extra = "merge")%>%
  select(-s3,-blank,-the_rest)
df_bucket=unique(df_bucket)

#Check to see if there is only one bucket associated with the submission. It is not required, but it is likely that there would only be one bucket.
if (dim(df_bucket)[1]>1){
  cat(paste("WARNING: There are more than one aws bucket that is associated with this metadata file: ", df_bucket$bucket,".\n",sep = ""))
  cat("\n")
}

#Do a list of the bucket and then check the file size and name against the metadata submission.
for (bucket_num in 1:dim(df_bucket)[1]){
  #pull bucket metadata
  metadata_files=suppressMessages(suppressWarnings(system(command = paste("aws s3 ls --recursive s3://", df_bucket[bucket_num,],"/",sep = ""),intern = TRUE)))
  
  #fix bucket metadata to have fixed delimeters of one space
  while (any(grepl(pattern = "  ",x = metadata_files))==TRUE){
    metadata_files=stri_replace_all_fixed(str = metadata_files,pattern = "  ",replacement = " ")
  }
  
  #Break bucket string into a data frame and clean up
  bucket_metadata=data.frame(all_metadata=metadata_files)
  bucket_metadata=separate(bucket_metadata, all_metadata, into = c("date","time","file_size","file_path"),sep = " ", extra = "merge")%>%
    select(-date, -time)%>%
    mutate(file_path=paste("s3://",df_bucket[bucket_num,],"/",file_path,sep = ""))
  bucket_metadata$file_size=as.character(bucket_metadata$file_size)
  df_bucket_specific=df[grep(pattern = df_bucket[bucket_num,], x = df$file_url_in_cds),]
  
  #For each row in the manifest for this bucket, check the contents of the bucket against the manifest.
  for (row in 1:dim(df_bucket_specific)[1]){
    #locate the file
    file_name_loc=grep(pattern = TRUE, x = bucket_metadata['file_path'][[1]] %in% df_bucket_specific[row,'file_url_in_cds'][[1]])
    #if the file is found, find that file with the correct size
    if (length(file_name_loc)!=0){
      if (bucket_metadata[file_name_loc,'file_size']!=df_bucket_specific[row,'file_size'][[1]]){
        cat(paste("ERROR: The following file does not have the same file size found in the AWS bucket: ", df_bucket_specific[row,'file_url_in_cds'][[1]],"\n", sep = ""))
      }
    }else{
      cat(paste("ERROR: The following file is not found in the AWS bucket: ", df_bucket_specific[row,'file_url_in_cds'][[1]],"\n", sep = ""))
    }
  }
  
  
  cat("\n\nThe following section is for files that are found in the bucket, but are not located in the manifest:\n")
  #Finally, check the bucket against the manifest to determine if there are files in the bucket that are not noted in the manifest.
  for (bucket_file in bucket_metadata$file_path){
    bucket_value = bucket_file  %in% df_bucket_specific['file_url_in_cds'][[1]]
    if (bucket_value==FALSE){
      cat(paste("ERROR: The following file is found in the AWS bucket and not the manifest that was provided: ", bucket_file,"\n", sep = ""))
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

cat(paste("\n\nProcess Complete.\n\nThe output file can be found here: ",path,"\n\n",sep = "")) 
