ARG RELEASE_VERSION=3.1.8

FROM registry.suse.com/bci/bci-base:15.7 AS builder
ARG RELEASE_VERSION

RUN zypper -n install --no-recommends \
        gcc gcc-c++ make tar git curl ca-certificates \
        cmake pkg-config flex bison gawk \
        libopenssl-3-devel cyrus-sasl-devel systemd-devel \
        zlib-devel libyaml-devel postgresql-server-devel \
    && zypper -n clean

WORKDIR /src/fluent-bit/
COPY . ./

WORKDIR /src/fluent-bit/build/
RUN cmake -DFLB_RELEASE=On \
        -DFLB_JEMALLOC=On \
        -DFLB_TLS=On \
        -DFLB_SHARED_LIB=Off \
        -DFLB_EXAMPLES=Off \
        -DFLB_HTTP_SERVER=On \
        -DFLB_IN_EXEC=Off \
        -DFLB_IN_SYSTEMD=On \
        -DFLB_OUT_KAFKA=On \
        -DFLB_OUT_PGSQL=On \
        -DFLB_LOG_NO_CONTROL_CHARS=On \
        .. && \
    make -j "$(getconf _NPROCESSORS_ONLN)" && \
    mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log && \
    install bin/fluent-bit /fluent-bit/bin/

WORKDIR /src/fluent-bit/
RUN cp conf/fluent-bit.conf \
       conf/parsers.conf \
       conf/parsers_ambassador.conf \
       conf/parsers_java.conf \
       conf/parsers_extra.conf \
       conf/parsers_openstack.conf \
       conf/parsers_cinder.conf \
       conf/plugins.conf \
       /fluent-bit/etc/ && \
    /fluent-bit/bin/fluent-bit -J > /fluent-bit/etc/schema.json

FROM registry.suse.com/bci/bci-base:15.7 AS prep
RUN mkdir -p /target && \
    zypper --gpg-auto-import-keys -n --installroot /target install --no-recommends \
        libopenssl3 cyrus-sasl libsystemd0 libz1 libyaml-0-2 \
        libpq5 ca-certificates && \
    zypper --installroot /target clean --all && \
    rm -rf /target/var/cache/zypp /target/var/log/*

FROM registry.suse.com/bci/bci-micro:15.7 AS production
ARG RELEASE_VERSION
ENV FLUENT_BIT_VERSION=${RELEASE_VERSION}

COPY --from=prep /target /
COPY --from=builder /fluent-bit /fluent-bit

EXPOSE 2020

ENTRYPOINT ["/fluent-bit/bin/fluent-bit"]
CMD ["-c", "/fluent-bit/etc/fluent-bit.conf"]

FROM registry.suse.com/bci/bci-base:15.7 AS debug
ARG RELEASE_VERSION
ENV FLUENT_BIT_VERSION=${RELEASE_VERSION}-debug

RUN zypper -n install --no-recommends \
        libopenssl3 cyrus-sasl libsystemd0 libz1 libyaml-0-2 libpq5 ca-certificates \
        curl libcurl4 libbrotlicommon1 libbrotlidec1 \
        bash gdb valgrind strace ltrace \
        git vim less jq \
        bind-utils iputils tcpdump iproute2 net-tools \
        openssl sysstat \
        cmake make tar flex bison gcc gcc-c++ \
        libopenssl-3-devel cyrus-sasl-devel systemd-devel zlib-devel libyaml-devel postgresql-server-devel \
    && zypper -n clean

COPY --from=builder /fluent-bit /fluent-bit

EXPOSE 2020

CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
