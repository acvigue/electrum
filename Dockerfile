FROM python:alpine

ENV ELECTRUM_VERSION=4.5.8

ENV ELECTRUM_RPC_USER=electrum
ENV ELECTRUM_RPC_PASSWORD=electrumz
ENV ELECTRUM_NETWORK=mainnet
ENV ELECTRUM_HOME=/home/electrum

WORKDIR /root

RUN mkdir build

COPY electrum-key.asc build

#Install dependencies
RUN apk update
RUN apk add --no-cache \
  bash \
  jq \
  libsecp256k1 \
  gnupg \
  curl \
  gcc \
  libc-dev \
  linux-headers

# Signature
RUN gpg --import < build/electrum-key.asc

# Download electrum
RUN cd build \
    SIG=Electrum-${ELECTRUM_VERSION}.tar.gz.ThomasV.asc; \
    FILE=Electrum-${ELECTRUM_VERSION}.tar.gz; \
    curl -sO https://download.electrum.org/${ELECTRUM_VERSION}/${SIG}; \
    curl -sO https://download.electrum.org/${ELECTRUM_VERSION}/${FILE}; \
    gpg --verify "${SIG}" "${FILE}"; \
    pip3 install pycryptodomex; \
    pip3 install --no-cache "${FILE}";

# Clean up
RUN cd .. ; \
    rm -rf build .gnupg .cache;

#Run as non-root user
RUN adduser -D electrum

RUN mkdir -p /data \
        /home/electrum/.electrum/wallets/ \
	    /home/electrum/.electrum/testnet/wallets/ \
	    /home/electrum/.electrum/regtest/wallets/ \
	    /home/electrum/.electrum/simnet/wallets/ && \
    ln -sf /home/electrum/.electrum/ /data && \
	chown -R electrum:electrum /home/electrum/.electrum /data

WORKDIR /home/electrum
VOLUME /data
EXPOSE 7000

COPY docker-entrypoint.sh /usr/local/bin/
RUN ["chmod", "a+x", "/usr/local/bin/docker-entrypoint.sh"]

USER electrum
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]