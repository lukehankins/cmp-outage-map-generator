import boto3
import argparse
import os
import sys

# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "-f",
    "--file",
    help='File to upload',
    default="cmp-outages.png",
    action="store",
)
parser.add_argument(
    "-d",
    "--destination",
    help='Destination',
    action="store",
)
parser.add_argument(
    "-m",
    "--mimetype",
    help='Mimetype',
    action="store",
)
parser.add_argument(
    "-b",
    "--bucket",
    help='Bucket to use',
    default="esp-cmpomg",
    action="store",
)
parser.add_argument(
    "-D",
    "--debug",
    help="Enable debugging",
    action="store_true",
)
parser.add_argument(
    "-v",
    "--verbose",
    help="Enable verbose",
    action="count",
)
args = parser.parse_args()

# Pull creds from env
aws_access_key_id = os.getenv('AWS_ACCESS')
aws_secret_access_key = os.getenv('AWS_SECRET')

if not aws_access_key_id or not aws_secret_access_key:
    print("ERROR: missing AWS credentials")
    sys.exit()

session = boto3.Session(
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key
)

s3 = session.resource('s3')

if not args.destination:
    args.destination = args.file

# check if file exists locally
# check if file exists remotely

if args.verbose:
    print(f"Uploading {args.file} to s3://{args.bucket}/{args.destination}")

extra_args = {}
if args.mimetype:
    extra_args['ContentType'] = args.mimetype

# if args.debug:
#     print(f"{aws_access_key_id} - {aws_secret_access_key}")

result = s3.Bucket(args.bucket).upload_file(args.file,args.destination, ExtraArgs=extra_args)

if args.verbose:
    print(result)