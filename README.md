# CancerDataServices-SubmissionValidationR
Tool for validating the Cancer Data Service's (CDS) Metadata Template in R

This R Script takes an XLSX file that is formatted to submission for CDS v1.3 as input. It will output a file that describes whether sections of the Metadata table PASS or ERROR on the checks.

To run the script on a CDS v1.3 template, run the following command in a terminal where R is installed.

```Rscript --vanilla CDS-Submission_ValidationR_v1.3.2.R input_file.xlsx```
