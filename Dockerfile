FROM debian:stretch-slim as builder
MAINTAINER Jagadesh <jagadesh@jemstep.com>

ENV LANG C.UTF-8
ENV DEBIAN_FRONTEND noninteractive
# install dependencies
RUN apt-get update && mkdir -p /usr/share/man/man1/ && apt-get install --no-install-recommends -y openjdk-8-jdk-headless wget\
 && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV VERSION=1.3.1.8
RUN mkdir -p /tmp /src && wget -nv https://github.com/yahoo/kafka-manager/archive/$VERSION.tar.gz -O /tmp/kafka-manager.tar.gz\
  && tar -xf /tmp/kafka-manager.tar.gz -C /src && cd /src/kafka-manager-$VERSION \
  && echo 'scalacOptions ++= Seq("-Xmax-classfile-name", "200")' >> build.sbt\
  && ./sbt update && ./sbt dist

FROM debian:stretch-slim

ENV LANG C.UTF-8
ENV VERSION=1.3.1.8
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && mkdir -p /usr/share/man/man1/ \
  && apt-get install --no-install-recommends -y openjdk-8-jdk-headless unzip\
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir /app
COPY --from=builder /src/kafka-manager-$VERSION/target/universal/kafka-manager-$VERSION.zip /tmp
RUN unzip -d /tmp /tmp/kafka-manager-$VERSION.zip && mv /tmp/kafka-manager-$VERSION/* /app/ \
 && rm -rf /tmp/kafka-manager* && rm -rf /app/share/doc
ADD entrypoint.sh /app/
ADD application.conf /app/conf/
ADD logback.xml /app/conf/

WORKDIR /app

EXPOSE 9000
ENTRYPOINT ["./entrypoint.sh"]
