########################################################################################
## Versions
########################################################################################
## Define which versions of both Alpine Linux and Tor you want to use for the image build. Latest stable versions are recommended for security.
## ALPINE_VER can be overwritten with --build-arg
## Pinned version tag from https://hub.docker.com/_/alpine
ARG ALPINE_VER=3.15


########################################################################################
## STAGE ONE - BUILD
########################################################################################
FROM alpine:$ALPINE_VER AS tor-builder

## TOR_VER can be overwritten with --build-arg at build time
## Get latest version from > https://dist.torproject.org/
ARG TOR_VER=0.4.7.8
ARG TORGZ=https://dist.torproject.org/tor-$TOR_VER.tar.gz
ARG TOR_KEY=0x6AFEE6D49E92B601

## Install tor make requirements
RUN apk --no-cache add --update \
    alpine-sdk \
    gnupg \
    libevent libevent-dev \
    zlib zlib-dev \
    openssl openssl-dev

## Get Tor key file and tar source file
RUN wget $TORGZ.sha256sum &&\
    wget $TORGZ.sha256sum.asc &&\
    wget $TORGZ

## Verify Tor source tarballs sha256 checksum file against gpg signature
## Get signing key from key server
RUN gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${TOR_KEY}
## Verify that the checksums file is PGP signed by the release signing key
RUN gpg --verify tor-${TOR_VER}.tar.gz.sha256sum.asc tor-${TOR_VER}.tar.gz.sha256sum 2>&1 |\
    grep -q "gpg: Good signature" ||\
    { echo "Couldn't verify signature!"; exit 1; }
RUN gpg --verify tor-${TOR_VER}.tar.gz.sha256sum.asc tor-${TOR_VER}.tar.gz.sha256sum 2>&1 |\
    grep -q "Primary key fingerprint: 2133 BC60 0AB1 33E1 D826  D173 FE43 009C 4607 B1FB" ||\
    { echo "Couldn't verify Primary key fingerprint!"; exit 1; }
## Checking if signed sha256 hash matches downloaded file.
RUN sha256sum -c tor-${TOR_VER}.tar.gz.sha256sum 2>&1 | grep -q "OK" ||\
    { echo "SHA256 hash does not match downloaded tor archive!"; exit 1; }

## Make install Tor
RUN tar xfz tor-$TOR_VER.tar.gz &&\
    cd tor-$TOR_VER && \
    ./configure &&\
    make install &&\
    rm ../tor-$TOR_VER.tar.*

########################################################################################
## STAGE TWO - RUNNING IMAGE
########################################################################################
FROM alpine:$ALPINE_VER as release

## CREATE NON-ROOT USER FOR SECURITY
RUN addgroup --gid 1001 --system nonroot && \
    adduser  --uid 1000 --system --ingroup nonroot --home /home/nonroot nonroot

## Install Alpine packages
## bind-tools is needed for DNS resolution to work in *some* Docker networks
RUN apk --no-cache add --update \
    bash \
    curl \
    libevent \
    bind-tools su-exec \
    openssl shadow coreutils \
    python3

## Data directory for tor files
ENV DATA_DIR=/tor

## Create tor directories
RUN mkdir -p ${DATA_DIR} && chown -R nonroot:nonroot ${DATA_DIR} && chmod -R go+rX,u+rwX ${DATA_DIR}

## Copy compiled Tor daemon from tor-builder
COPY --from=tor-builder /usr/local/ /usr/local/

COPY --chown=nonroot:nonroot entrypoint.py /data/


## Docker health check
HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
            CMD curl --socks5-hostname 127.0.0.1:9050 'https://check.torproject.org/' | grep -q "Congratulations"
 
ENTRYPOINT ["python3", "/data/entrypoint.py"]

EXPOSE 9050/tcp

LABEL name="EZ Onion host"
LABEL version=$TOR_VER
LABEL description="A docker image to make your hosts available over the TOR network."
LABEL license="GPL3.0"
LABEL maintainer="systemling32 (https://github.com/systemling32) <systemling32@protonmail.com>"
