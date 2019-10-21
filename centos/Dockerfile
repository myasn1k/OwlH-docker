###############################################################################
# MULTI-STAGE BUILD: BASE
################################################################################
FROM centos:centos7 as base

RUN yum -y update  \
 && yum -y upgrade \
 && yum -y install wget net-tools tcpdump socat tcpreplay initscripts jq PyYAML \
 && yum clean all \
 && rm -rf /var/cache/yum

################################################################################
# MULTI-STAGE BUILD: BUILDER
################################################################################
FROM base as builder

RUN yum -y install epel-release git jq gcc PyYAML tar make cmake gcc-c++ flex bison swig \
                   python-devel lua-devel openssl-devel lz4-devel libpcap-devel \
                   pcre-devel libyaml-devel file-devel zlib-devel jansson-devel \
                   nss-devel libcap-ng-devel libnet-devel libnetfilter_queue-devel \
 && yum clean all \
 && rm -rf /var/cache/yum

################################################################################
# MULTI-STAGE BUILD: SURICATA
################################################################################
FROM builder as suricata

COPY ["scripts/owlhsuricata.sh", "/tmp/"]

RUN mkdir -p /usr/local/owlh/bin /usr/local/owlh/src/owlhnode \
 && cd /tmp \
 && chmod +x owlhsuricata.sh \
 && ./owlhsuricata.sh \
 && cd / \
 && tar czvf /tmp/suricata.tar.gz /var/log/suricata/                   \
             /etc/suricata /usr/lib/python2.7/site-packages/suricata*  \
             /usr/share/man/man1/suricata.1 /usr/share/doc/suricata    \
             /usr/bin/suricata* /usr/lib64/libhtp.* /usr/lib64/libnet* \
             /usr/lib64/libjanss* 

################################################################################
# MULTI-STAGE BUILD: ZEEK
################################################################################
FROM builder as zeek

COPY [ "scripts/owlhzeek.sh", "/tmp/" ]

RUN cd /tmp \
 && chmod +x owlhzeek.sh \
 && ./owlhzeek.sh \
 && tar czvf /tmp/zeek.tar.gz /usr/local/zeek 

################################################################################
# BUILD: OWLH-NODE + WAZUH
################################################################################
FROM base

COPY [ "scripts/owlhwazuh.sh",     "/tmp/" ]
COPY [ "scripts/owlhui-httpd.sh",  "/tmp/" ]
COPY [ "conf/httpd-owlh.conf",     "/tmp/" ]
COPY [ "conf/supervisord.conf",    "/etc/supervisord.conf" ]
COPY [ "conf/supervisor.d/*.conf", "/etc/supervisor.d/" ]
COPY [ "scripts/bootstrap.sh",     "/config/bootstrap.sh" ]
COPY --from=suricata /tmp/suricata.tar.gz /tmp
COPY --from=zeek     /tmp/zeek.tar.gz     /tmp

ARG MASTERIP=localhost

STOPSIGNAL SIGRTMIN+3

RUN mkdir -p /usr/local/owlh/src/{owlhnode,owlhmaster} \
 && mkdir -p /var/log/{suricata,supervisor} \
 && mkdir -p /usr/local/zeek   \
 && mkdir -p /var/www/owlh     \
 && chmod 755 /var/www/owlh    \
 && yum -y install which libpcap policycoreutils dbus \
 && yum -y install httpd mod_ssl php                  \
 && yum -y install python-setuptools                  \
 && easy_install supervisor                           \
 && cd /tmp \
 && wget repo.owlh.net/current-centos/owlhnode.tar.gz   \
 && wget repo.owlh.net/current-centos/owlhmaster.tar.gz \
 && wget repo.owlh.net/current-centos/owlhui.tar.gz     \
 && tar xzf owlhnode.tar.gz   -C /usr/local/owlh/src/owlhnode   \
 && tar xzf owlhmaster.tar.gz -C /usr/local/owlh/src/owlhmaster \
 && tar xzf owlhui.tar.gz     -C /var/www/owlh                  \
 && tar xzf suricata.tar.gz   -C /                              \
 && tar xzf zeek.tar.gz       -C /                              \
 && chmod +x owlhwazuh.sh \
 && /bin/sh owlhwazuh.sh \
 && sed -i "s/<MASTERIP>/$MASTERIP/g" /var/www/owlh/conf/ui.conf \
 && cp /usr/local/owlh/src/owlhnode/conf/service/owlhnode.service     /etc/systemd/system \
 && cp /usr/local/owlh/src/owlhmaster/conf/service/owlhmaster.service /etc/systemd/system \
 && cp /tmp/owlhui-httpd.sh /var/www/owlh/conf/service/owlhui-httpd.sh \
 && cp /tmp/httpd-owlh.conf /etc/httpd/conf.d/owlh.conf \
 && /bin/sh /var/www/owlh/conf/service/owlhui-httpd.sh \
 && rm -f /tmp/owlhnode.tar.gz    \
 && rm -f /tmp/owlhmaster.tar.gz  \
 && rm -f /tmp/owlhui.tar.gz      \
 && rm -f /tmp/suricata.tar.gz    \
 && rm -f /tmp/zeek.tar.gz        \
 && rm -f /tmp/owlhwazuh.sh /tmp/owlhui-httpd.sh /tmp/httpd-owlh.conf \
 && /usr/local/zeek/bin/zeekctl deploy \
 && yum clean all \
 && rm -rf /var/cache/yum       \
 && systemctl enable owlhnode   \
 && systemctl enable owlhmaster
# && systemctl daemon reload
# && systemctl start  owlhnode   \
# && systemctl start  owlhmaster \

# OwlH Master & UI
EXPOSE 443
EXPOSE 8005
EXPOSE 50001
# OwlH Node
EXPOSE 50002
#
EXPOSE 50010-50020

ENTRYPOINT [ "/config/bootstrap.sh" ]
