FROM ubuntu:18.04

RUN apt update -y
RUN apt install -y wget libpcap0.8
RUN wget http://repo.owlh.net/current-debian/owlhinstaller.tar.gz
RUN mkdir /tmp/owlhinstaller
RUN tar -C /tmp/owlhinstaller -xvf owlhinstaller.tar.gz
RUN rm /tmp/owlhinstaller/config.json
ADD ./config.json /tmp/owlhinstaller/
RUN cd /tmp/owlhinstaller && ./owlhinstaller
RUN wget http://repo.owlh.net/current-debian/services/owlhui-httpd.sh
RUN sed -i 's/systemctl\ restart\ apache2//g' ./owlhui-httpd.sh
RUN chmod +x ./owlhui-httpd.sh && ./owlhui-httpd.sh
RUN sed -i 's/<MASTERIP>/localhost/g' /var/www/owlh/conf/ui.conf
ADD ./init.sh /
RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]
