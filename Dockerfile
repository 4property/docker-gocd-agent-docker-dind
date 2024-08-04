# Copyright 2024 Thoughtworks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM curlimages/curl:latest AS gocd-agent-unzip
USER root
ARG TARGETARCH
ARG UID=1000
RUN curl --fail --location --silent --show-error "https://download.gocd.org/binaries/24.3.0-19261/generic/go-agent-24.3.0-19261.zip" > /tmp/go-agent-24.3.0-19261.zip && \
    unzip -q /tmp/go-agent-24.3.0-19261.zip -d / && \
    mkdir -p /go-agent/wrapper /go-agent/bin && \
    mv -v /go-agent-24.3.0/LICENSE /go-agent/LICENSE && \
    mv -v /go-agent-24.3.0/*.md /go-agent && \
    mv -v /go-agent-24.3.0/bin/go-agent /go-agent/bin/go-agent && \
    mv -v /go-agent-24.3.0/lib /go-agent/lib && \
    mv -v /go-agent-24.3.0/logs /go-agent/logs && \
    mv -v /go-agent-24.3.0/run /go-agent/run && \
    mv -v /go-agent-24.3.0/wrapper-config /go-agent/wrapper-config && \
    WRAPPERARCH=$(if [ $TARGETARCH == amd64 ]; then echo x86-64; elif [ $TARGETARCH == arm64 ]; then echo arm-64; else echo $TARGETARCH is unknown!; exit 1; fi) && \
    mv -v /go-agent-24.3.0/wrapper/wrapper-linux-$WRAPPERARCH* /go-agent/wrapper/ && \
    mv -v /go-agent-24.3.0/wrapper/libwrapper-linux-$WRAPPERARCH* /go-agent/wrapper/ && \
    mv -v /go-agent-24.3.0/wrapper/wrapper.jar /go-agent/wrapper/ && \
    chown -R ${UID}:0 /go-agent && chmod -R g=u /go-agent

FROM docker.io/docker:dind
ARG TARGETARCH

LABEL gocd.version="24.3.0" \
  description="GoCD agent based on docker.io/docker:dind" \
  maintainer="GoCD Team <go-cd-dev@googlegroups.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="24.3.0-19261" \
  gocd.git.sha="3d8bed12557f0b310a4bce58f076abbfc2841ae9"

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-${TARGETARCH} /usr/local/sbin/tini

# force encoding
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
  apk --no-cache upgrade && \
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
  adduser -D -u ${UID} -s /bin/bash -G root go && \
  adduser go docker && \
  apk add --no-cache git openssh-client bash curl procps && \
  apk add --no-cache sudo && \
  # install glibc/zlib for the Tanuki Wrapper, and use by glibc-linked Adoptium JREs && \
    apk add --no-cache tzdata --virtual .build-deps curl binutils zstd && \
    GLIBC_VER="2.34-r0" && \
    ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ZLIB_URL="https://america.archive.pkgbuild.com/packages/z/zlib/zlib-1%3A1.3.1-2-x86_64.pkg.tar.zst" && \
    ZLIB_SHA256=4e44ca417663fbdbadd2aa975cb5f56c2fe771ca76bc1462f63760d813fe2458 && \
    curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
    SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" && \
    echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk && \
    apk add --no-cache --force-overwrite /tmp/glibc-${GLIBC_VER}.apk && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk && \
    apk add --no-cache /tmp/glibc-bin-${GLIBC_VER}.apk && \
    curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    apk add --no-cache /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.zst && \
    echo "${ZLIB_SHA256} */tmp/libz.tar.zst" | sha256sum -c - && \
    mkdir /tmp/libz && \
    zstd -d /tmp/libz.tar.zst --output-dir-flat /tmp && \
    tar -xf /tmp/libz.tar -C /tmp/libz && \
    mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib && \
    apk del --purge .build-deps glibc-i18n && \
    rm -rf /tmp/*.apk /tmp/libz /tmp/libz.tar* /var/cache/apk/* && \
  # end installing glibc/zlib && \
  curl --fail --location --silent --show-error "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.4%2B7/OpenJDK21U-jre_$(uname -m | sed -e s/86_//g)_linux_hotspot_21.0.4_7.tar.gz" --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-agent /docker-entrypoint.d /go /godata

ADD docker-entrypoint.sh /


COPY --from=gocd-agent-unzip /go-agent /go-agent
# ensure that logs are printed to console output
COPY --chown=go:root agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xml /go-agent/config/
COPY --chown=root:root dockerd-sudo /etc/sudoers.d/dockerd-sudo

RUN chown -R go:root /docker-entrypoint.d /go /godata /docker-entrypoint.sh && \
    chmod -R g=u /docker-entrypoint.d /go /godata /docker-entrypoint.sh

  COPY --chown=root:root run-docker-daemon.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
