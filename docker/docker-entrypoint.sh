#!/bin/bash

if [ -f ./build_date.txt ]; then
    echo -n "BUILD DATE: "
    cat ./build_date.txt
fi

if [ -z "${RUN_SERVER}" ]; then
    DT=$(date +"%Y-%m-%d-%H-%M")
    FILENAME="cmp-outages-${DT}.png"
    LOGFILE="cmp-outages-${DT}.txt"
    python3 ./cmp-outages.py --verbose --zoom Kittery --zoom Augusta -o "/tmp/$FILENAME" | tee "/tmp/$LOGFILE"
    # TODO: https://www.pythoninformer.com/python-libraries/pillow/creating-animated-gif/
    echo XXXXXXXXXXXXXXXXX
    ls -l /tmp
    echo XXXXXXXXXXXXXXXXX
    if [ -f "/tmp/$FILENAME" ]; then
        python3 ./upload-to-s3.py --verbose --debug --file "/tmp/$FILENAME" --destination "$FILENAME" --mimetype "image/png"
        python3 ./upload-to-s3.py --verbose --debug --file "/tmp/$FILENAME" --destination "latest.png" --mimetype "image/png"
        python3 ./upload-to-s3.py --verbose --debug --file "/tmp/$LOGFILE" --destination "$LOGFILE" --mimetype "text/plain"
    else
        echo "ERROR: /tmp/$FILENAME not found.  Exiting."
        exit 1
    fi
else
    echo "running server"
    gunicorn --bind :8080 --workers 2 website:app
fi