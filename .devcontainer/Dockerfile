FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/base:focal
  # checkov:skip=CKV_DOCKER_2: Ignore healthcheck warning for dev container
  # checkov:skip=CKV_DOCKER_3: Ignore user creation for dev container

RUN apt-get update && \
    apt-get install --no-install-recommends -y xorriso whois && \
    apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*
