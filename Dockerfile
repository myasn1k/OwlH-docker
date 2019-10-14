ARG distro=centos

################################################################################
# MULTI-STAGE BUILD: BASE
################################################################################
FROM centos:centos7 as base

RUN yum -y update \
 && yum -y install epel-release wget net-tools initscripts jq PyYAML swig

################################################################################
# MULTI-STAGE BUILD: BUILDER
################################################################################
FROM base as builder

RUN yum -y install git jq openssl-devel PyYAML lz4-devel gcc libpcap-devel pcre-devel libyaml-devel file-devel zlib-devel jansson-devel nss-devel libcap-ng-devel libnet-devel tar make libnetfilter_queue-devel lua-devel cmake make gcc-c++ flex bison python-devel swig

################################################################################
# MULTI-STAGE BUILD: SURICATA
################################################################################
FROM builder as suricata

ARG OWLH_SURICATA_URL=http://repo.owlh.net/current-centos/services/owlhsuricata.sh

RUN mkdir -p /usr/local/owlh/bin /usr/local/owlh/src/owlhnode \
 && cd /tmp \
 && wget ${OWLH_SURICATA_URL} \
 && chmod +x owlhsuricata.sh \
 && ./owlhsuricata.sh

RUN cd / && tar czvf /tmp/suricata.tar.gz $(find . -name "suricata*"|grep -v /run|grep -v /var)

################################################################################
# MULTI-STAGE BUILD: ZEEK
################################################################################
FROM builder as zeek

ARG OWLH_ZEEK_URL=http://repo.owlh.net/current-centos/services/owlhzeek.sh

RUN yum -y install curl && cd /tmp \
 && curl ${OWLH_ZEEK_URL} > /tmp/owlhzeek.tmp \
 && head -n $(expr $(wc -l /tmp/owlhzeek.tmp|awk '{print $1}') - 3) /tmp/owlhzeek.tmp | grep -v source > /tmp/owlhzeek.sh \
 && cd /tmp && chmod +x owlhzeek.sh \
 && ./owlhzeek.sh

RUN tar czvf /tmp/zeek.tar.gz /usr/local/zeek 

################################################################################
# BUILD: OWLH-NODE + WAZUH
################################################################################
FROM base

ARG OWLH_WAZUH_URL=http://repo.owlh.net/current-centos/services/owlhwazuh.sh
ARG OWLH_NODE_URL=http://repo.owlh.net/current-centos/owlhnode.tar.gz

# Owlh Node
RUN cd /tmp \
 && wget ${OWLH_NODE_URL} \
 && mkdir -p /usr/local/owlh/bin /usr/local/owlh/src/owlhnode \
 && tar xzf owlhnode.tar.gz -C /usr/local/owlh/src/owlhnode \
 && rm -f /tmp/owlhnode.tar.gz

# Suricata
COPY --from=suricata /tmp/suricata.tar.gz /tmp
RUN mkdir /var/log/suricata \
 && cd / \
 && tar xzf /tmp/suricata.tar.gz \
 && chkconfig --add owlhsuricata \
 && chkconfig owlhsuricata on \
 && service owlhsuricata start \
 && rm -f /tmp/suricata.tar.gz

# Zeek
COPY --from=zeek /tmp/zeek.tar.gz /tmp
RUN tar xzf /tmp/zeek.tar.gz -C /usr/local \
 && rm -f /tmp/zeek.tar.gz

# Wazuh
RUN cd /tmp \
 && wget ${OWLH_WAZUH_URL} \
 && chmod +x owlhwazuh.sh \
 && ./owlhwazuh.sh

ENV GOPATH=/usr/local/owlh
ENTRYPOINT /usr/local/owlh/src/owlhnode/owlhnode
