# Smoke test 
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ="America/New_York"
RUN apt-get update && apt-get install -y python3 python3-pip libpng-dev cmake libfreetype6-dev libfontconfig1-dev xclip python3-tk
    COPY . /
RUN pip3 install -r ./requirements.txt
RUN python3 ./cmp-outages.py