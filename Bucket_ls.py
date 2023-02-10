import argparse
import argcomplete
from datetime import date
import os
import boto3

parser = argparse.ArgumentParser(
                    prog='Bucket_ls.py',
                    description='A script to create a ls --recursive list of bucket for ingest into the validation scripts. This is used when the pipeline needs to be run on a machine (VM) that does not have aws access, and this output is then transfered to that machine.',
                    )

parser.add_argument( '-s', '--s3_bucket', help="The s3 bucket location, in the format of 'bucket' when compared to the url of 's3://bucket/name/here/'")
parser.add_argument( '-o', '--output', help="The directory location of the output file. The default is the current directory.",default="./")

argcomplete.autocomplete(parser)

args = parser.parse_args()

#obtain the date
def refresh_date():
    today=date.today()
    today=today.strftime("%Y%m%d")
    return today

#pull in args as variables
s3_bucket=args.s3_bucket
output=args.output
output=os.path.abspath(output)


#Test bucket to make sure expected parts are there.
if s3_bucket.find("s3://") == 0:
    s3_bucket=s3_bucket.replace("s3://","")

if s3_bucket[len(s3_bucket)-1]=="/":
    s3_bucket=s3_bucket[:len(s3_bucket)-1]

#Make sure dir location is setup correctly
if output[len(output)-1]!="/":
    output=output+"/"

date=refresh_date()

#Get s3 session setup
session=boto3.Session()

s3=session.resource('s3')

my_bucket=s3.Bucket(s3_bucket)

#List the bucket's file size and file and write out.
tsv_text= open(f"{output}{s3_bucket}_{date}.tsv","w")

for my_bucket_obj in my_bucket.objects.all():
    write_down=str(my_bucket_obj.size)+"\t"+my_bucket_obj.key+"\n"
    n=tsv_text.write(write_down)

tsv_text.close()
