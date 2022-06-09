#!/bin/sh

if [ -z "${RUN_SERVER}" ]; then
    FILENAME="cmp-outages-$(date +"%Y-%m-%d-%H-%M").png"
    python3 ./cmp-outages.py --verbose --zoom Kittery --zoom Augusta -o "/tmp/$FILENAME"
    echo XXXXXXXXXXXXXXXXX
    ls -l /tmp
    echo XXXXXXXXXXXXXXXXX
    if [ -f "/tmp/$FILENAME" ]; then
        python3 ./upload-to-s3.py --verbose --debug --file "/tmp/$FILENAME" --destination "$FILENAME"
    else
        echo "ERROR: /tmp/$FILENAME not found.  Exiting." 
    fi
else
    echo "running server"
    gunicorn --bind :8080 --workers 2 website:app
fi