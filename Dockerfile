# DOCKER-VERSION 0.3.4

FROM ubuntu:14.04

RUN apt-get update && apt-get install -yq nodejs npm

ADD . /src

RUN cd /src; npm install

EXPOSE 8080

CMD ["/usr/bin/nodejs", "/src/bin/server"]
