#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Start script from root"
  exit 1
fi


#system update & upgrade
apt-get update -y
apt-get upgrade -y

#installing software
apt-get install curl -y
apt-get install git -y
apt-get install ranger -y
apt-get install wget -y
apt-get install sudo -y
apt-get install gnupg2 -y

#timezone setup
timedatectl set-timezone Europe/Moscow

#creating new user
USERNAME=$(hostname)
PASSWORD=$(hostname)

useradd -m -s /bin/bash "$USERNAME"

echo "$USERNAME:$PASSWORD" | chpasswd

sudo usermod -aG sudo $USERNAME

#installing Wazuh-agent
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

apt-get update

Wazuhip="0.0.0.0"

WAZUH_MANAGER="$Wazuhip" apt-get install -y wazuh-agent

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

#installing zabbix-agent2
wget https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian12_all.deb

dpkg -i zabbix-release_latest_7.4+debian12_all.deb

apt update 

apt install -y zabbix-agent2

#root login restriction
sed -i 's|^root:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$|root:\1:\2:\3:\4:\5:/sbin/nologin|' /etc/passwd
