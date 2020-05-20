FROM quay.io/giantswarm/docker-kubectl:latest

ARG K8S_VERSION=v1.18.2

RUN apk add --no-cache jq bash

WORKDIR /app

COPY check_vpc_cidrs.sh /app/
RUN chmod +x /app/check_vpc_cidrs.sh

USER 1001

ENTRYPOINT ["/app/check_vpc_cidrs.sh"]