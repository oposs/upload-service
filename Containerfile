# The build environment of the upload-service packages.
#
# ri-release-distro-packages builds the build-deps stage once per release
# with --build-arg BASE=<image of that release> and runs ./bootstrap,
# ./configure, make, make check and make install DESTDIR=/stage in it, with
# the checkout at /src. make downloads App::cpanminus and the modules named in
# PERL_MODULES from CPAN, so the image needs a downloader and the toolchain
# those modules build with. On the rpm releases the downloader is named by
# its path: AlmaLinux 9 ships curl-minimal, which conflicts with curl. The
# image is built without a context: it names packages and nothing else.
ARG BASE=docker.io/library/debian:13
FROM ${BASE} AS build-deps

RUN set -eu; \
    . /etc/os-release; \
    case " ${ID} ${ID_LIKE:-} " in \
    *" debian "*|*" ubuntu "*) \
        apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            autoconf automake make perl curl ca-certificates gzip tar unzip gcc libc6-dev libcrypt-dev; \
        rm -rf /var/lib/apt/lists/* ;; \
    *" rhel "*|*" fedora "*|*" centos "*) \
        dnf install -y autoconf automake make perl perl-devel /usr/bin/curl gzip tar unzip gcc; \
        dnf clean all ;; \
    *" alpine "*) \
        apk add --no-cache autoconf automake make perl perl-dev perl-utils build-base \
            curl wget perl-io-socket-ssl ca-certificates gzip tar unzip ;; \
    *) echo "Containerfile: no package list for ${ID}" >&2; exit 1 ;; \
    esac
