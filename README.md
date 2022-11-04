# CancerDataServices-SubmissionValidationR
Tool for validating the Cancer Data Service's (CDS) Metadata Template in R

This R Script takes a data file that is formatted to the submission template for CDS v1.3.1 as input. It will output a file that describes whether sections of the Metadata table PASS, ERROR or WARNING on the checks.

To run the script on a CDS v1.3.1 template, run the following command in a terminal where R is installed for help.

```
Rscript --vanilla CDS-Submission_ValidationR.R --help
```


```
Usage: CDS-Submission_ValidationR.R [options]

CDS-Submission_ValidationR v2.0.1

Options:
	-f CHARACTER, --file=CHARACTER
		dataset file (.xlsx, .tsv, .csv)

	-t CHARACTER, --template=CHARACTER
		dataset template file, CDS_submission_metadata_template-v1.3.xlsx

	-h, --help
		Show this help message and exit
```

To test the script on one of the provided test files:

```
Rscript --vanilla CDS-Submission_ValidationR.R -f test_files_v1.3.1/a_all_pass-v1.3.1.xlsx -t CDS_submission_metadata_template-v1.3.1.xlsx
```

`Note: The AWS bucket checks will not work with any of the test files, as the files and their locations are fake data`


## Error Messages

|Message|Issue|Likely Fix|
|-------|-----|----------|
|ERROR: Please obtain a new data template with all sheets and columns present before making further edits to this one.|The template with metadata does not match the template being tested against.|Move metadata to the updated template and rerun the validation.|
|ERROR: Please submit a data file that is in either xlsx, tsv or csv format.|The input file that was submitted is not in a supported format.|Please make sure you have the correct extension. For TSV and CSV, make sure these are the file extensions and not TXT.|
|ERROR: The Metadata sheet is missing the following required column: {column}|The workbook that has metadata entered is missing the specified columns.|Obtain a [fresh version of the workbook](https://github.com/CBIIT/ccdi-model/blob/main/CCDI_Submission_Template_v1.0.1.xlsx) and migrate the metadata into the newly acquired workbook.|
|ERROR: Column from a required group of properties, {required_property_group}, was found empty on the Metadata sheet. Please add values for the following columns: {column} |For groups (Study, Sample, Participant, etc) that have information in some of the required properties, there are other required properties that are missing values.|Obtain the required information for all columns in a given row for a group.|
|WARNING: Required property group {required_property_group} contains values for all entries that are assumed to have values based on the submitted data structure.|A warning that notes while some rows have information in the property group, there are other rows that are completely empty for this group.|This is a confirmation and only needs to be fixed if this is unexpected.|
|ERROR: Missing values and/or leading/trailing white space in the required {property} property, on the Metadata sheet. Please check the following position: {row position}|||
|WARNING: Required property {property} contains values for all entries that are assumed to have values based on the submitted data structure.||This is a confirmation and only needs to be fixed if this is unexpected.|
|ERROR: {value_set_name} property contains a value that is not recognized: {value}|||
|ERROR:The following participant_id, {participant_id}, is linked to more than one value for gender.|There are conflicting values of gender for the same participant id in the metadata submission file.|Check all instances of gender for each listed participant_id and determine the values are all identical. |
|ERROR: The following participant_id, {participant_id}, is linked to more than one value for ethnicity.|There are conflicting values of ethnicity for the same participant id in the metadata submission file.|Check all instances of ethnicity for each listed participant_id and determine the values are all identical.|
|ERROR: The following participant_id, {participant_id}, is linked to more than one value for race.|There are conflicting values of race for the same participant id in the metadata submission file.|Check all instances of race for each listed participant_id and determine the values are all identical.|
|WARNING: The library_id, {library_id}, has multiple samples associated with it, {sample_ids}. This setup will cause issues when submitting to SRA.||This is a confirmation and only needs to be fixed if this is unexpected.|
|WARNING: The sample_id {sample_id} is associated with multiple single sample sequencing files: {file list}||This is a confirmation and only needs to be fixed if this is unexpected.|
|ERROR: The file, {file_name}, is missing at least one expected value (bases, avg_read_length, coverage, number_of_reads) that is associated with an SRA submissions.|||
|WARNING: The file in row {row_position}, has a size value of 0. Please make sure that this is a correct value for the file.|||
|ERROR: The file in row {row_position}, has a md5sum value that does not follow the md5sum regular expression.|||
|WARNING: There are more than one aws bucket that is associated with this metadata file: {s3 bucket list}||This is a confirmation and only needs to be fixed if this is unexpected.|
|ERROR: The following file is not found in the AWS bucket: {file list}|||
|ERROR: The following file does not have the same file size found in the AWS bucket: {file list}|||
