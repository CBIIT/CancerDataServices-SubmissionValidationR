# CancerDataServices-SubmissionValidationR
Tool for validating the Cancer Data Service's (CDS) Metadata Template in R

This R Script takes a data file that is formatted to the submission template for CDS v1.3.1 as input. It will output a file that describes whether sections of the Metadata table PASS, ERROR or WARNING on the checks.

To run the script on a CDS v1.3.1 template, run the following command in a terminal where R is installed for help.

```
Rscript --vanilla CDS-Submission_ValidationR.R --help
```


```
Usage: CDS-Submission_ValidationR.R [options]

CDS-Submission_ValidationR v2.0.0

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
|ERROR: Please submit a data file that is in either xlsx, tsv or csv format.||
|ERROR: The Metadata sheet is missing the following required column: {column}||
|ERROR: Column from a required group of properties, {required_property_group}, was found empty on the Metadata sheet. Please add values for the following columns: {column} ||
|WARNING: Required property group {required_property_group} contains values for all entries that are assumed to have values based on the submitted data structure.||
|ERROR: Missing values and/or leading/trailing white space in the required {property} property, on the Metadata sheet. Please check the following position: {row position}||
|WARNING: Required property {property} contains values for all entries that are assumed to have values based on the submitted data structure.||
|ERROR: {value_set_name} property contains a value that is not recognized: {value}||
|ERROR:The following participant_id, {participant_id}, is linked to more than one value for gender.||
|ERROR: The following participant_id, {participant_id}, is linked to more than one value for ethnicity.||
|ERROR: The following participant_id, {participant_id}, is linked to more than one value for race.||
|WARNING: The library_id, {library_id}, has multiple samples associated with it, {sample_ids}. This setup will cause issues when submitting to SRA.||
|WARNING: The sample_id {sample_id} is associated with multiple single sample sequencing files: {file list}||
|ERROR: The file, {file_name}, is missing at least one expected value (bases, avg_read_length, coverage, number_of_reads) that is associated with an SRA submissions.||
|WARNING: The file in row {row_position}, has a size value of 0. Please make sure that this is a correct value for the file.||
|ERROR: The file in row {row_position}, has a md5sum value that does not follow the md5sum regular expression.||
|WARNING: There are more than one aws bucket that is associated with this metadata file: {s3 bucket list}||
|ERROR: The following file is not found in the AWS bucket: {file list}||
|ERROR: The following file does not have the same file size found in the AWS bucket: {file list}||
