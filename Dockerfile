# syntax=docker/dockerfile:1
FROM alpine:latest AS base

# Build arguments for multi-arch support
ARG TARGETARCH
ARG S6_OVERLAY_VERSION=3.2.1.0
ARG ELECTRUM_VERSION=4.6.2

RUN mkdir build

COPY electrum-key.asc build

# Install runtime dependencies (curl, xz, gnupg will be removed after use)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-setuptools \
    py3-cryptography \
    libsecp256k1 \
    bash

# Install temporary build dependencies
RUN apk add --no-cache --virtual .build-deps \
    curl \
    xz \
    gnupg

# Install s6-overlay - noarch component (always needed)
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    rm /tmp/s6-overlay-noarch.tar.xz

# Install s6-overlay - architecture-specific component
# Map Docker TARGETARCH to s6-overlay architecture naming
RUN case "${TARGETARCH}" in \
        amd64)   S6_ARCH="x86_64"  ;; \
        arm64)   S6_ARCH="aarch64" ;; \
        arm)     S6_ARCH="arm"     ;; \
        armhf)   S6_ARCH="armhf"   ;; \
        386)     S6_ARCH="i686"    ;; \
        riscv64) S6_ARCH="riscv64" ;; \
        s390x)   S6_ARCH="s390x"   ;; \
        *)       echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -L -o /tmp/s6-overlay-arch.tar.xz \
        https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    rm /tmp/s6-overlay-arch.tar.xz

RUN gpg --import < build/electrum-key.asc

ENV ELECTRUM_ECC_DONT_COMPILE=1

# Download and install electrum
RUN cd build && \
    SIG=Electrum-${ELECTRUM_VERSION}.tar.gz.ThomasV.asc && \
    FILE=Electrum-${ELECTRUM_VERSION}.tar.gz && \
    curl -sO https://download.electrum.org/${ELECTRUM_VERSION}/${SIG} && \
    curl -sO https://download.electrum.org/${ELECTRUM_VERSION}/${FILE} && \
    gpg --verify "${SIG}" "${FILE}" && \
    pip3 install pycryptodomex --break-system-packages && \
    pip3 install --no-cache "${FILE}" --break-system-packages && \
    cd .. && \
    rm -rf build .gnupg .cache && \
    apk del .build-deps

# Create electrum user with UID/GID 521 and directories
RUN addgroup -g 521 electrum && \
    adduser -u 521 -G electrum -h /data -D electrum && \
    mkdir -p /data/.electrum && \
    chown -R electrum:electrum /data

# Environment variables with defaults
ENV ELECTRUM_RPC_USERNAME="" \
    ELECTRUM_RPC_PASSWORD="" \
    ELECTRUM_PROXY="" \
    ELECTRUM_RPC_PORT="7000" \
    ELECTRUM_RPC_HOST="0.0.0.0" \
    TESTNET="false" \
    ELECTRUM_NETWORK="mainnet" \
    ELECTRUM_WALLET_NAME="default_wallet" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    PUID=521 \
    PGID=521

# Create S6 service directory for Electrum
RUN mkdir -p /etc/s6-overlay/s6-rc.d/electrum-daemon && \
    mkdir -p /etc/s6-overlay/s6-rc.d/electrum-daemon/dependencies.d && \
    mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d

# Create service type file
RUN echo "longrun" > /etc/s6-overlay/s6-rc.d/electrum-daemon/type

# Create dependency on base
RUN touch /etc/s6-overlay/s6-rc.d/electrum-daemon/dependencies.d/base

# Add electrum-daemon to user bundle
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/electrum-daemon

# Create the run script for the service
COPY electrum-daemon-run /etc/s6-overlay/s6-rc.d/electrum-daemon/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/electrum-daemon/run

# Create finish script to handle graceful shutdown
COPY electrum-daemon-finish /etc/s6-overlay/s6-rc.d/electrum-daemon/finish
RUN chmod +x /etc/s6-overlay/s6-rc.d/electrum-daemon/finish

# Create the main electrum startup script
COPY run-electrum.sh /usr/local/bin/run-electrum.sh
RUN chmod +x /usr/local/bin/run-electrum.sh

# Create health check script
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Set working directory
WORKDIR /data

# Expose RPC port
EXPOSE ${ELECTRUM_RPC_PORT}

# Volume for wallet data
VOLUME ["/data"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

# Use S6 as init system
ENTRYPOINT ["/init"]
