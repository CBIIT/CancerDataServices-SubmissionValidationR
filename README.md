# CancerDataServices-SubmissionValidationR
Tool for validating the Cancer Data Service's (CDS) Metadata Template in R

This R Script takes a data file that is formatted to the [submission template for CDS](https://github.com/CBIIT/cds-model/tree/main/metadata-manifest) as input. It will output a file that describes whether sections of the Metadata table PASS, ERROR or WARNING on the checks.

To run the script on a CDS template, run the following command in a terminal where R is installed for help.

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
		dataset template file, CDS_submission_metadata_template

	-h, --help
		Show this help message and exit
```

To test the script on one of the provided test files:

```
Rscript --vanilla CDS-Submission_ValidationR.R -f test_files_v1.3.1/a_all_pass-v1.3.1.xlsx -t CDS_submission_metadata_template.xlsx
```

`Note: The AWS bucket checks will not work with any of the test files, as the files and their locations are fake data`


## Error Messages

|Message|Issue|Likely Fix|
|-------|-----|----------|
|ERROR: Please obtain a new data template with all sheets and columns present before making further edits to this one.|The template with metadata does not match the template being tested against.|Move metadata to the [newest version of the template](https://github.com/CBIIT/cds-model/tree/main/metadata-manifest) and rerun the validation.|
|ERROR: Please submit a data file that is in either xlsx, tsv or csv format.|The input file that was submitted is not in a supported format.|Please make sure you have the correct extension. For TSV and CSV, make sure these are the file extensions and not TXT.|
|ERROR: The Metadata sheet is missing the following required column: {column}|The workbook that has metadata entered is missing the specified columns.|Obtain the [newest version of the template](https://github.com/CBIIT/cds-model/tree/main/metadata-manifest) and migrate the metadata into the newly acquired workbook.|
|ERROR: Column from a required group of properties, {required_property_group}, was found empty on the Metadata sheet. Please add values for the following columns: {column} |For groups (Study, Sample, Participant, etc) that have information in some of the required properties, there are other required properties that are missing values.|Obtain the required information for all columns in a given row for a group.|
|WARNING: Required property group {required_property_group} contains values for all entries that are assumed to have values based on the submitted data structure.|A warning that notes while some rows have information in the property group, there are other rows that are completely empty for this group.|This is a confirmation and only needs to be fixed if this is unexpected.|
|ERROR: Missing values and/or leading/trailing white space in the required {property} property, on the Metadata sheet. Please check the following position: {row position}|For a required property that has other required information, this notes the property and row that is missing this information.|Locate the missing cell by going to the column (property) and row and supply the correct metadata.|
|WARNING: Required property {property} contains values for all entries that are assumed to have values based on the submitted data structure.|Based on a required property, if there are missing values, they are assumed to be purposely empty based on the other missing values in the required properties for a group.|This is a confirmation and only needs to be fixed if this is unexpected.|
|ERROR: {value_set_name} property contains a value that is not recognized: {value}|The property has an expected enumeration list and the value that was supplied does not match that list.|Locate the "Terms and Value Sets" tab in the workbook, and determine the given acceptable values for the property.|
|ERROR:The following participant_id, {participant_id}, is linked to more than one value for gender.|There are conflicting values of gender for the same participant id in the metadata submission file.|Check all instances of gender for each listed participant_id and determine the values are all identical. |
|ERROR: The following participant_id, {participant_id}, is linked to more than one value for ethnicity.|There are conflicting values of ethnicity for the same participant id in the metadata submission file.|Check all instances of ethnicity for each listed participant_id and determine the values are all identical.|
|ERROR: The following participant_id, {participant_id}, is linked to more than one value for race.|There are conflicting values of race for the same participant id in the metadata submission file.|Check all instances of race for each listed participant_id and determine the values are all identical.|
|WARNING: The library_id, {library_id}, has multiple samples associated with it, {sample_ids}. This setup will cause issues when submitting to SRA.|The library_id is pointing to multiple sample_ids within the same submission.|This is a confirmation and only needs to be fixed if this is unexpected. If submitting to SRA, library_ids will need to be manipulated to become unique, usually by concatenating library_id and sample_id into one string.|
|WARNING: The sample_id {sample_id} is associated with multiple single sample sequencing files: {file list}|The sample_id is connected to multiple single sample files (e.g. fastq, bam, cram).|This is a confirmation and only needs to be fixed if this is unexpected. This is a common occurance if you are submitting both the fastq files with the cram/bam file.|
|ERROR: The file, {file_name}, is missing at least one expected value (bases, avg_read_length, coverage, number_of_reads) that is associated with an SRA submissions.|For most files that have one of these statistical values, it is common to have the other values, and of that group one or more is missing.|For the file with the missing statistics, these will be required for submission to the SRA. An external program (e.g. samtools) will be needed to obtain the missing values if they do not already exist elsewhere.|
|WARNING: The file in row {row_position}, has a size value of 0. Please make sure that this is a correct value for the file.|The file size of a file has the value of 0. |This is a confirmation and only needs to be fixed if this is unexpected. This is often and issue that needs a new value supplied and not an expected warning.|
|ERROR: The file in row {row_position}, has a md5sum value that does not follow the md5sum regular expression.|The md5sum of a file does not match the expected regex of a md5sum value.|Replace the noted value with a recalculated md5sum of the file.|
|WARNING: There are more than one aws bucket that is associated with this metadata file: {s3 bucket list}|Based on the manifest supplied there are more than one base bucket in the manifest.|This is a confirmation and only needs to be fixed if this is unexpected.|
|ERROR: The following file is not found in the AWS bucket: {file list}|The files supplied in the manifest column, "file_url_in_cds", are not found in the bucket.|Make sure the files exist in the bucket and the urls in the manifest are correctly pointing to them.|
|ERROR: The following file does not have the same file size found in the AWS bucket: {file list}|The file sizes supplied in the manifest do not match the file sizes based on AWS calls. |Make sure you have the correct file size for each file and the numbers have not been rounded by other programs (e.g. Excel).|
