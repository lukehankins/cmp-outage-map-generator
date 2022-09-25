from collections import defaultdict
import logging
import datetime
import os
from flask import Flask, render_template
import boto3
import sys
 
app = Flask(__name__,
    static_url_path='', 
    static_folder='website/static',
    template_folder='website/templates')

def get_files_from_s3():
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
    bucket = s3.Bucket("esp-cmpomg")
    files = [file.key for file in bucket.objects.all()]

    return files

# if __name__ != '__main__':
#     gunicorn_logger = logging.getLogger('gunicorn.error')
#     app.logger.handlers = gunicorn_logger.handlers
#     app.logger.setLevel(gunicorn_logger.level)

@app.template_filter('strftime')
def _jinja2_filter_datetime(date, fmt=None):
    # date = dateutil.parser.parse(date)
    # native = date.replace(tzinfo=None)
    # format='%b %d, %Y'
    # return native.strftime(format) 
    return datetime.datetime.fromtimestamp(date).strftime('%c')

@app.route("/")
def index():
    # DEBUG and INFO are off
    # app.logger.debug('this is a DEBUG message')
    # app.logger.info('this is an INFO message')
    # app.logger.warning('this is a WARNING message')
    # app.logger.error('this is an ERROR message')
    # app.logger.critical('this is a CRITICAL message')
    return render_template("index.html")

@app.route("/stats")
def stats():
    data = dict()
    data['flyenv'] = {'FLY_APP_NAME':os.getenv('FLY_APP_NAME')}
    # data['environ'] = {}
    data['environ'] = os.environ
    data['static'] = os.scandir(path = './website/static')
    # get last run
    # get list of /static
    # get env variables
    return render_template("status.html", data=data)

@app.route("/filedump")
def filedump():
    # data = defaultdict(list)

    files = reversed(get_files_from_s3())

    data = []

    for file in files:
        if "png" in file:
            prefix = file.split('.')[0]
            date = '-'.join(file.split('-')[1:4])
            data.append(date)

    return render_template("filedump.html", files=data)

@app.route("/log")
def status():
    log_lines = [row for row in reversed(list(open("/tmp/out.txt")))]
    return render_template("log.html", log_lines=log_lines)
 
print("FOO!", __name__)
app.logger.critical(f'STARTING with name {__name__}')

# if __name__ == "__main__":
#     print("oi!")
#     app.run()