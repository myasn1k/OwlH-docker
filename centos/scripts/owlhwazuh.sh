MANAGER_IP="MANAGER_IP"
source env.conf

rpm --import http://packages.wazuh.com/key/GPG-KEY-WAZUH
cat > /etc/yum.repos.d/wazuh.repo <<\EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1
EOF
yum update
yum -y install wazuh-agent

if [ ! -d "/var/ossec" ]; then
    echo -e "\e[91mThere was a problem installing Wazuh-Agent, /var/ossec path doesn't exist\e[0m"
    exit 1
fi

sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo
sed -i "s/MANAGER_IP/$MANAGER_IP/" /var/ossec/etc/ossec.conf

cat >> /var/ossec/etc/ossec.conf <<\EOF
<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/suricata/eve.json</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/usr/local/zeek/logs/current/conn.log</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/usr/local/zeek/logs/current/dns.log</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/usr/local/zeek/logs/current/http.log</location>
  </localfile>
  <localfile>
    <log_format>syslog</log_format>
    <location>/usr/local/zeek/logs/current/ssl.log</location>
  </localfile>
</ossec_config>
EOF

