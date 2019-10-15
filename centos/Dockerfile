ARG distro=centos

###############################################################################
# MULTI-STAGE BUILD: BASE
################################################################################
FROM centos:centos7 as base

RUN yum -y update \
 && yum -y install epel-release wget net-tools initscripts jq PyYAML swig

################################################################################
# MULTI-STAGE BUILD: BUILDER
################################################################################
FROM base as builder

RUN yum -y install git jq gcc PyYAML tar make cmake gcc-c++ flex bison swig \
                   python-devel lua-devel openssl-devel lz4-devel libpcap-devel \
                   pcre-devel libyaml-devel file-devel zlib-devel jansson-devel \
                   nss-devel libcap-ng-devel libnet-devel libnetfilter_queue-devel

################################################################################
# MULTI-STAGE BUILD: SURICATA
################################################################################
FROM builder as suricata

COPY ["owlhsuricata.sh", "/tmp/"]

RUN mkdir -p /usr/local/owlh/bin /usr/local/owlh/src/owlhnode \
 && cd /tmp \
 && chmod +x owlhsuricata.sh \
 && ./owlhsuricata.sh \
 && cd / \
 && tar czvf /tmp/suricata.tar.gz \
             /etc/suricata /usr/lib/python2.7/site-packages/suricata* \
             /usr/share/man/man1/suricata.1 /usr/share/doc/suricata /usr/bin/suricata*

################################################################################
# MULTI-STAGE BUILD: ZEEK
################################################################################
FROM builder as zeek

COPY [ "owlhzeek.sh", "/tmp/" ]

RUN cd /tmp \
 && chmod +x owlhzeek.sh \
 && ./owlhzeek.sh \
 && tar czvf /tmp/zeek.tar.gz /usr/local/zeek 

################################################################################
# BUILD: OWLH-NODE + WAZUH
################################################################################
FROM base

ARG OWLH_NODE_URL=http://repo.owlh.net/current-centos/owlhnode.tar.gz

COPY [ "owlhwazuh.sh", "/tmp/"]
COPY --from=suricata /tmp/suricata.tar.gz /tmp
COPY --from=zeek     /tmp/zeek.tar.gz     /tmp

RUN mkdir -p /usr/local/owlh/bin /usr/local/owlh/src/owlhnode \
 && mkdir /var/log/suricata \
 && yum -y install which libpcap \
 && cd /tmp \
 && wget ${OWLH_NODE_URL} \
 && tar xzf /tmp/owlhnode.tar.gz -C /usr/local/owlh/src/owlhnode \
 && tar xzf /tmp/suricata.tar.gz -C / \
 && tar xzf /tmp/zeek.tar.gz     -C /usr/local \
 && chmod +x owlhwazuh.sh \
 && ./owlhwazuh.sh \
 && rm -f /tmp/owlhnode.tar.gz \
 && rm -f /tmp/suricata.tar.gz \
 && rm -f /tmp/zeek.tar.gz     \
 && yum clean all \
 && rm -rf /var/cache/yum

ENV GOPATH=/usr/local/owlh/src/owlhnode
ENTRYPOINT /usr/local/owlh/src/owlhnode/owlhnode
