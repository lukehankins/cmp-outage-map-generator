import logging
import datetime
import os
from flask import Flask, render_template
 
app = Flask(__name__,
    static_url_path='', 
    static_folder='website/static',
    template_folder='website/templates')

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
    app.logger.debug('this is a DEBUG message')
    app.logger.info('this is an INFO message')
    app.logger.warning('this is a WARNING message')
    app.logger.error('this is an ERROR message')
    app.logger.critical('this is a CRITICAL message')
    return render_template("index.html")

@app.route("/status")
def status():
    data = dict()
    data['flyenv'] = {'FLY_APP_NAME':os.getenv('FLY_APP_NAME')}
    data['environ'] = []
    # data['environ'] = os.environ
    data['static'] = os.scandir(path = './website/static')
    # get last run
    # get list of /static
    # get env variables
    return render_template("status.html", data=data)
 
print("FOO!", __name__)
app.logger.critical(f'STARTING with name {__name__}')

# if __name__ == "__main__":
#     print("oi!")
#     app.run()