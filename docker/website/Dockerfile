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

# RUN apt-get update && apt-get install -y cron

# RUN apt-get update && apt-get install -y \
#     python3-pip \
#     python3-venv \
#     python3-dev \
#     python3-setuptools \
#     python3-wheel

# RUN apt-get update && apt-get install -y \
#     python3-pip

# RUN mkdir -p /app

COPY . /app

WORKDIR /app

EXPOSE 8080

# CMD ["cron", "-f"]
CMD ["./docker-entrypoint.sh"]

