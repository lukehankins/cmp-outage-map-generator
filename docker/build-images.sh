#!/bin/sh

set -e

# TODO: check for jq

AMD64DIGEST=$(docker manifest inspect  python:3.10-slim | jq -r '.manifests[] | select(.platform.architecture == "amd64") | .digest')

for STYLE in updater website; do
# for STYLE in updater; do
    cd ${STYLE}

    NAME=cmp-outage-map-generator-${STYLE}
    FILES="requirements.txt Maine_E911_NG_Roads.zip cmp-outages.py upload-to-s3.py"

    for file in $FILES; do
        cp "../../${file}" .
    done

    cp ../docker-entrypoint.sh .

    docker build \
        -t "${NAME}:arm64" .

    # echo "@${AMD64DIGEST}"
    # docker build \
    #     --platform linux/amd64 \
    #     --build-arg DIGEST="@${AMD64DIGEST}" \
    #     -t "registry.fly.io/${NAME}:amd64" .

    # docker push "registry.fly.io/${NAME}:amd64"

    for file in $FILES; do
        rm "./${file}"
    done

    cd ..
done

echo "======="
# echo docker rm updater
# echo docker logs --follow updater
echo docker run --rm --env-file ~/.aws/cmpomg.env --name updater cmp-outage-map-generator-updater:arm64
echo fly m run --verbose -a cmp-outage-map-generator-updater registry.fly.io/cmp-outage-map-generator-updater:amd64
echo docker run -d --rm -p 8080:8080 --env RUN_SERVER=true --env-file ~/.aws/cmpomg.env --name website cmp-outage-map-generator-website:arm64
echo aws s3 ls esp-cmpomg
echo docker exec -it updater /bin/sh
