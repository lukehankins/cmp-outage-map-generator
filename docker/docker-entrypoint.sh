#!/bin/bash

if [ -f ./build_date.txt ]; then
    echo -n "BUILD DATE: "
    cat ./build_date.txt
fi

if [ -z "${RUN_SERVER}" ]; then
    DT=$(date +"%Y-%m-%d-%H-%M")
    FILENAME="cmp-outages-${DT}.png"
    ANIMATION="cmp-outages-${DT}-animated.gif"
    LOGFILE="cmp-outages-${DT}.txt"
    echo XXXXXXXXXXXXXXXXX
    pwd
    ls -ltr /app/data
    echo XXXXXXXXXXXXXXXXX
    #
    # Get images needed to make the animation
    #

    # for filename in $(aws s3 ls esp-cmpomg | grep cmp-outages | grep png | tail -24 | awk '{ print $4}'); do
    #     if [ ! -f "/app/data/${filename}" ]; then
    #         aws s3 cp s3://esp-cmpomg/"$filename" /app/data
    #     fi
    # done

    #
    # Generate latest image
    #
    python3 ./cmp-outages.py --verbose --zoom Kittery --zoom Augusta -o "/app/data/$FILENAME" | tee "/app/data/$LOGFILE"

    # Generate latest animation
    cd /app/data || exit
    for filename in cmp-outages-*.png; do
        ymd=$(echo "$filename" | cut -d- -f 3,4,5)
        hhh=$(echo "$filename" | cut -d- -f 6)
        mmm=$(echo "$filename" | cut -d- -f 7 | cut -c1-2)
        datestamp=$(TZ='America/New_York' date --date="${ymd} ${hhh}:${mmm}" -Iminutes)
        # datestamp="$ymd-${hhh}:$mmm-Eastern"
        echo "Burning in $datestamp"
        convert "$filename" -stroke  none -fill red -pointsize 40  -annotate +600+1700 "${datestamp}" "mod-${filename}"
    done

    last=$(\ls -tr mod-*.png | tail -1)
    lastbase=$(basename "${last}" .png)
    echo "Duplicating $lastbase"
    for x in 01 02 03 04 05 06 07 08 09 10; do
        cp "${lastbase}.png" "${lastbase}-${x}.png"
    done

    echo "Creating animation"
    convert -delay 60 -loop 0 mod-* "$ANIMATION"
    rm mod*

    echo XXXXXXXXXXXXXXXXX
    ls -ltr /app/data
    echo XXXXXXXXXXXXXXXXX
    cd /app | exit
    if [ -f "/app/data/$FILENAME" ]; then
        python3 /app/upload-to-s3.py --verbose --debug --file "/app/data/$FILENAME" --destination "$FILENAME" --mimetype "image/png"
        python3 /app/upload-to-s3.py --verbose --debug --file "/app/data/$FILENAME" --destination "latest.png" --mimetype "image/png"
        python3 /app/upload-to-s3.py --verbose --debug --file "/app/data/$LOGFILE" --destination "$LOGFILE" --mimetype "text/plain"
    else
        echo "ERROR: /app/data/$FILENAME not found.  Exiting."
        exit 1
    fi

    if [ -f "/app/data/$ANIMATION" ]; then
        python3 /app/upload-to-s3.py --verbose --debug --file "/app/data/$ANIMATION" --destination "$ANIMATION" --mimetype "text/plain"
    else
        echo "ERROR: /app/data/$ANIMATION not found.  Exiting."
        exit 1
    fi

else
    echo "running server"
    gunicorn --bind :8080 --workers 2 website:app
fi