#!/bin/sh

set -e

TIMESTAMP=$(date +%Y%m%d%H%M)

do_build () {
    for file in $FILES; do
        cp "../../${file}" .
    done
    cp ../docker-entrypoint.sh .
    date > build_date.txt

    docker build \
        -t "${NAME}:arm64-${TIMESTAMP}" .

    echo "@${AMD64DIGEST}"
    docker build \
        --platform linux/amd64 \
        --build-arg DIGEST="@${AMD64DIGEST}" \
        -t "registry.fly.io/${NAME}:amd64-${TIMESTAMP}" .

    docker push "registry.fly.io/${NAME}:amd64-${TIMESTAMP}"

    for file in $FILES; do
        rm "./${file}"
    done
    rm docker-entrypoint.sh
}


# TODO: check for jq

echo "setting AMD64DIGEST"
AMD64DIGEST=$(docker manifest inspect  python:3.10-slim | jq -r '.manifests[] | select(.platform.architecture == "amd64") | .digest')

if [ "$1" != "website" ]; then
    cd updater
    NAME=cmp-outage-map-generator-updater
    FILES="requirements.txt Maine_E911_NG_Roads.zip cmp-outages.py upload-to-s3.py list-s3.py"
    do_build
    cd ..
fi

if [ "$1" != "updater" ]; then
    cd website
    NAME=cmp-outage-map-generator
    FILES=""
    do_build
    cd ..
fi

echo "========="
echo " IMAGES:"
echo "========="

for NAME in cmp-outage-map-generator-updater cmp-outage-map-generator; do
    docker image ls "${NAME}:arm64-${TIMESTAMP}"
    docker image ls "registry.fly.io/${NAME}:amd64-${TIMESTAMP}"
done


# for STYLE in website; do
#     cd ${STYLE}

#     NAME=cmp-outage-map-generator-${STYLE}

#     if [ $"$STYLE" -eq "updater" ]; then
#         FILES="requirements.txt Maine_E911_NG_Roads.zip cmp-outages.py upload-to-s3.py"
#     else
#         FILES="requirements.txt"
#     fi

#     for file in $FILES; do
#         cp "../../${file}" .
#     done

#     cp ../docker-entrypoint.sh .
#     date > build_date.txt

#     docker build \
#         -t "${NAME}:arm64" .

#     echo "@${AMD64DIGEST}"
#     docker build \
#         --platform linux/amd64 \
#         --build-arg DIGEST="@${AMD64DIGEST}" \
#         -t "registry.fly.io/${NAME}:amd64" .

#     # docker push "registry.fly.io/${NAME}:amd64"

#     for file in $FILES; do
#         rm "./${file}"
#     done

#     cd ..
# done

echo "======="
./hints.sh