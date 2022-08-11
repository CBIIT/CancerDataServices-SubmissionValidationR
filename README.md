# CancerDataServices-SubmissionValidationR
Tool for validating the Cancer Data Service's (CDS) Metadata Template in R

This R Script takes a data file that is formatted to the submission template for CDS v1.3.1 as input. It will output a file that describes whether sections of the Metadata table PASS or ERROR on the checks.

To run the script on a CDS v1.3.1 template, run the following command in a terminal where R is installed for help.

```
Rscript --vanilla CDS-Submission_ValidationR.R --help
```


```
Usage: CDS-Submission_ValidationR.R [options]

CDS-Submission_ValidationR v.1.3.1

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
