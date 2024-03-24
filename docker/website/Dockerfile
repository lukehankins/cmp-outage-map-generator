ARG PYTHON_VERSION=3.10
ARG DIGEST

FROM python:${PYTHON_VERSION}-slim${DIGEST} as base

FROM base as builder
RUN mkdir /install
WORKDIR /install
# COPY requirements.txt /requirements.txt
COPY requirements.txt.local /requirements.txt.local
RUN pip install --prefix=/install -r /requirements.txt.local

FROM base
COPY --from=builder /install /usr/local
RUN apt-get update && apt-get install -y cron curl

COPY . /app

# COPY ./cron-do-update /etc/cron.d/cron-do-update
# RUN crontab /etc/cron.d/cron-do-update

# RUN curl -L https://fly.io/install.sh | sh

WORKDIR /app

EXPOSE 8080

# CMD ["cron", "-f"]
# CMD ["./docker-entrypoint.sh"]
CMD [ "sh", "-c", "cron && ./docker-entrypoint.sh" ]
