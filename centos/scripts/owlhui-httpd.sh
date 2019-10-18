chcon -R -t httpd_sys_content_t /var/www/owlh
setsebool -P httpd_can_network_connect 1

export MYPUBIP=$(curl ifconfig.co)
sed -i "s/<MASTERIP>/$MYPUBIP/g" /var/www/owlh/conf/ui.conf
chmod 666 /var/www/owlh/conf/ui.conf
ln -s /var/www/owlh/nodes.html /var/www/owlh/index.html
#sysV
#service httpd start
chkconfig httpd on
#systemd
#systemctl start httpd

