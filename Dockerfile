FROM centos:8

ARG K8S_VERSION=v1.18.2

RUN yum -y install wget && \
    wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

WORKDIR /app

COPY check_vpc_cidrs.sh /app/
RUN chmod +x /app/check_vpc_cidrs.sh

USER 1001

CMD ["/app/check_vpc_cidrs.sh"]