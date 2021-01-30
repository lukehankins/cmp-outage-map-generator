#!/bin/sh

cd ..

DATE=`date +%Y-%m-%d-%H:%M`

echo "defaults..."
python ./cmp-outages.py -o samples/sample-defaults.png                                           >& samples/sample-defaults.txt &

echo "verbose..."
python ./cmp-outages.py -o samples/sample-verbose.png --verbose                                  >& samples/sample-verbose.txt &

wait

echo "demo..."
python ./cmp-outages.py -o samples/sample-demo.png --demo                                        >& samples/sample-demo.txt &

echo "entire..."
python ./cmp-outages.py -o samples/sample-entire.png --entirestate --demo                        >& samples/sample-entire.txt &

wait

echo "fast..."
python ./cmp-outages.py -o samples/sample-fast.png --entirestate --demo --fast                   >& samples/sample-fast.txt &

echo "width..."
python ./cmp-outages.py -o samples/sample-width.png --entirestate --demo --fast --width 2        >& samples/sample-width.txt &

wait

echo "zoom..."
python ./cmp-outages.py -o samples/sample-zoom.png --zoom "Presque Isle" --demo                  >& samples/sample-zoom.txt &

echo "interesting..."
python ./cmp-outages.py -o samples/sample-interest.png --interesting "Portland" --demo --fast    >& samples/sample-interest.txt &

