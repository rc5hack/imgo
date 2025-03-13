# syntax=docker/dockerfile:1
# escape=\

FROM ubuntu:22.04 AS stage-builder
WORKDIR /imgo-build
RUN mkdir -- ./bin
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
        build-essential \
        ca-certificates \
        gcc \
        libpng-dev \
        make \
        tar \
        unzip \
        wget && \
    rm -rf /var/lib/apt/lists/*
RUN echo "Install cryopng..." && \
    wget http://frdx.free.fr/cryopng/cryopng-linux-x86.tgz -nv -O cryopng.tar.gz && \
    tar -zxf cryopng.tar.gz && \
    mv cryo-files/cryopng ./bin && \
    rm -rf -- cryopng.tar.gz cryo-files
RUN echo "Install defluff..." && \
    wget https://github.com/imgo/imgo-tools/raw/master/src/defluff/defluff-0.3.2-linux-$(uname -m).zip -nv -O defluff.zip && \
    unzip defluff.zip && \
    mv defluff ./bin && \
    rm -f -- defluff.zip
RUN echo "Install pngout..." && \
    PNGOUT_VERSION=20150319 && \
    # PNGOUT_VERSION=20200115 && \
    echo "Using pngout version: $PNGOUT_VERSION" && \
    # ARCH=$(uname -m) && \
    # case "$ARCH" in \
    #     x86_64)    ARCH="amd64" ;; \
    #     aarch64)   ARCH="aarch64" ;; \
    #     armv7l)    ARCH="armv7" ;; \
    #     i686)      ARCH="i686" ;; \
    #     *)         echo "Unsupported arch: $ARCH" && exit 1 ;; \
    # esac && \
    # echo "Using architecture: $ARCH" && \
    wget "https://www.jonof.id.au/files/kenutils/pngout-$PNGOUT_VERSION-linux-static.tar.gz" -nv -O pngout.tar.gz && \
    tar -xvf pngout.tar.gz && \
    mv "./pngout-$PNGOUT_VERSION-linux-static/$(uname -m)/pngout-static" ./bin/pngout && \
    rm -rf -- pngout.tar.gz "./pngout-$PNGOUT_VERSION-linux-static/"
RUN echo "Install pngrewrite..." && \
    wget http://entropymine.com/jason/pngrewrite/pngrewrite-1.4.0.zip -nv -O pngrewrite.zip && \
    unzip pngrewrite.zip -d pngrewrite && \
    make -C pngrewrite && \
    mv pngrewrite/pngrewrite ../bin && \
    rm -rf -- pngrewrite.zip pngrewrite
COPY imgo ./bin/

FROM ubuntu:22.04 AS stage-runner
RUN apt-get update && \
    apt-get -y --no-install-recommends install \
        advancecomp \
        gifsicle \
        imagemagick \
        libimage-exiftool-perl \
        libjpeg-progs \
        libpng-dev \
        optipng \
        pngnq && \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get -y --no-install-recommends install \
        libc6:i386 && \
    rm -rf /var/lib/apt/lists/*
COPY --from=stage-builder --chmod=0755 --chown=0:0 /imgo-build/bin/* /usr/local/bin/
ENTRYPOINT ["imgo"]
