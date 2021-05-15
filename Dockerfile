# ----------------------------------------------------------------
# 							BUILDER IMAGE
# ----------------------------------------------------------------
FROM centos:7 AS builder
LABEL maintainer="04neha.singh@gmail.com"

ARG VERSION="latest"
ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"


### Create user ###
RUN groupadd --gid 1000 cc \
  && useradd --uid 1000 --gid cc --shell /bin/bash --create-home cc

### Dependencies ###
RUN yum -y install git java-1.8.0-openjdk-devel
RUN yum install -y curl \
    git \
    wget \
    tar


# ### Download ###
RUN set -eux \
	&& if [ "${VERSION}" = "latest" ]; then \
			DATA="$( \
				curl -sS https://github.com/linkedin/cruise-control/releases \
				| tac \
				| tac \
				| grep -Eo 'href=".+[.0-9]+\.tar.gz"' \
				| awk -F'"' '{print $2}' \
				| sort -u \
				| tail -1 \
			)"; \
			echo "${DATA}"; \
			VERSION="$( echo "${DATA}" | grep -Eo '[.0-9]+[0-9]' )"; \
		fi \
	&& echo "${VERSION}" \
	&& echo "${VERSION}" > /VERSION \
	&& curl -sSL "https://github.com/linkedin/cruise-control/archive/${VERSION}.tar.gz" > /tmp/cc.tar.gz

### Extract ###
RUN set -eux \
	&& cd /tmp \
	&& tar xzvf cc.tar.gz \
	&& mv /tmp/cruise-control-* /tmp/cruise-control \
    && rm cc.tar.gz

### Setup git user and init repo ###
RUN set -eux \
	&& cd /tmp/cruise-control \
	&& git config --global user.email root@localhost \
	&& git config --global user.name root \
	&& git init \
	&& git add . \
	&& git commit -m "Init local repo." \
	&& git tag -a ${VERSION} -m "Init local version."

### Install dependencies ###
RUN set -eux \
	&& cd /tmp/cruise-control \
	&& ./gradlew jar \
	&& ./gradlew jar copyDependantLibs

### Download UI ###
RUN set -eux \
	&& UI="$( \
		curl -sSL https://github.com/linkedin/cruise-control-ui/releases/latest \
			| grep -Eo '".+cruise-control-ui-[.0-9]+.tar.gz"'\
			| sed 's/"//g' \
		)" \
	&& curl -sL "https://github.com${UI}" > /tmp/cc-ui.tar.gz \
	&& cd /tmp \
	&& tar xvfz cc-ui.tar.gz 

### Setup dist ###
RUN set -eux \
	&& mkdir -p /cc/cruise-control/build \
	&& mkdir -p /cc/cruise-control-core/build \
	&& cp -a /tmp/cruise-control/cruise-control/build/dependant-libs /cc/cruise-control/build/ \
	&& cp -a /tmp/cruise-control/cruise-control/build/libs /cc/cruise-control/build/ \
	&& cp -a /tmp/cruise-control/cruise-control-core/build/libs /cc/cruise-control-core/build/ \
	&& cp -a /tmp/cruise-control/config /cc/ \
	&& cp -a /tmp/cruise-control/kafka-cruise-control-start.sh /cc/ \
	&& cp -a /tmp/cruise-control-ui/dist /cc/cruise-control-ui \
	&& sed -i'' \
		's|^webserver.ui.diskpath=.*|webserver.ui.diskpath=/cc/cruise-control-ui/|g' \
		/cc/config/cruisecontrol.properties
# \
#	&& find /cc/ -name '*.csv' -print0 | xargs -0 -n1 rm -f \
#	&& find /cc/ -name '*.txt' -print0 | xargs -0 -n1 rm -f

### Copy out Kafka CruiseControlMetricsReporter  ###
RUN set -eux \
	&& VERSION="$( cat /VERSION )" \
	&& ls -lap /tmp/cruise-control/cruise-control-metrics-reporter/build/libs/ \
	&& cp /tmp/cruise-control/cruise-control-metrics-reporter/build/libs/cruise-control-metrics-reporter-*.jar /cruise-control-metrics-reporter.jar

# ------------------------------------------------------------------
#							 PRODUCTION IMAGE
# -------------------------------------------------------------------
FROM centos:7 as production
LABEL maintainer="04neha.singh@gmail.com"
ENV PORT 9091

EXPOSE 9091/tcp

### Install requirements ###
RUN yum remove bind-chroot bind-sdb-chroot && \
    yum -y update glibc && \
	yum -y install git java-1.8.0-openjdk-devel && \
	yum -y install bind-chroot bind-sdb-chroot && \
	yum clean all

ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"

### Copy files ###
COPY --from=builder /cc /cc
COPY --from=builder /VERSION /VERSION

WORKDIR /cc
USER cc

HEALTHCHECK CMD curl --fail http://localhost:9091/ || exit 1

### Startup ###
CMD ["./kafka-cruise-control-start.sh config/cruisecontrol.properties 9091"]
