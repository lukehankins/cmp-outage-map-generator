#!/bin/sh

set -e

do_build () {
    for file in $FILES; do
        cp "../../${file}" .
    done
    cp ../docker-entrypoint.sh .
    date > build_date.txt

    docker build \
        -t "${NAME}:arm64" .

    echo "@${AMD64DIGEST}"
    docker build \
        --platform linux/amd64 \
        --build-arg DIGEST="@${AMD64DIGEST}" \
        -t "registry.fly.io/${NAME}:amd64" .

    docker push "registry.fly.io/${NAME}:amd64"

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
    FILES="requirements.txt Maine_E911_NG_Roads.zip cmp-outages.py upload-to-s3.py"
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
# echo docker rm updater
# echo docker logs --follow updater
echo docker run --rm --env-file ~/.aws/cmpomg.env --name updater cmp-outage-map-generator-updater:arm64
echo fly m run --memory 2048  --verbose -a cmp-outage-map-generator-updater registry.fly.io/cmp-outage-map-generator-updater:amd64
echo docker exec -it updater /bin/sh
echo
# echo fly m run --verbose -a cmp-outage-map-generator-updater registry.fly.io/cmp-outage-map-generator-updater:amd64
echo docker kill website
echo docker run -d --rm -p 8080:8080 --env RUN_SERVER=true --env-file ~/.aws/cmpomg.env --name website cmp-outage-map-generator:arm64
echo docker exec -it website /bin/sh
echo fly deploy --local-only --image cmp-outage-map-generator:amd64  -a cmp-outage-map-generator
echo 
echo aws s3 ls esp-cmpomg
