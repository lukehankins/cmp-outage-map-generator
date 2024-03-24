ARG PYTHON_VERSION=3.10
ARG DIGEST

FROM python:${PYTHON_VERSION}-slim${DIGEST} as base

FROM base as builder
RUN mkdir /install
WORKDIR /install
COPY requirements.txt /requirements.txt
COPY requirements.txt.local /requirements.txt.local
RUN pip install --prefix=/install -r /requirements.txt \
    && pip install --prefix=/install -r /requirements.txt.local

FROM base
COPY --from=builder /install /usr/local

RUN apt-get update && apt-get install -y ca-certificates imagemagick

COPY . /app

RUN mkdir -p /app/data

WORKDIR /app

# CMD ["cron", "-f"]
CMD ["./docker-entrypoint.sh"]

