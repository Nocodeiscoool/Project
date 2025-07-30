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
read -p "Enter new user's name: " USERNAME
read -s -p "Enter password: " PASSWORD
echo
read -s -p "Confirm password: " PASSWORD_CONFIRM
echo

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
  echo "Error: passwords do not match."
  exit 1
fi

echo "Username: $USERNAME"

useradd -m -s /bin/bash "$USERNAME"

echo "$USERNAME:$PASSWORD" | chpasswd

sudo usermod -aG sudo $USERNAME


#installing zabbix-agent2
wget https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian12_all.deb

mkdir -p /run/zabbix

dpkg -i zabbix-release_latest_7.4+debian12_all.deb

apt update 

apt install -y zabbix-agent2

systemctl restart zabbix-agent2

systemctl enable zabbix-agent2 

sudo chown -R zabbix:zabbix /run/zabbix

read -p "Enter Zabbix server IP or hostname: " ZABBIX_SERVER
read -p "Enter hostname for the agent: " AGENT_HOSTNAME

CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"


if grep -q "^Server=" "$CONFIG_FILE"; then
  sed -i "s|^Server=.*|Server=$ZABBIX_SERVER|" "$CONFIG_FILE"
else
  echo "Server=$ZABBIX_SERVER" >> "$CONFIG_FILE"
fi

if grep -q "^ServerActive=" "$CONFIG_FILE"; then
  sed -i "s|^ServerActive=.*|ServerActive=$ZABBIX_SERVER|" "$CONFIG_FILE"
else
  echo "ServerActive=$ZABBIX_SERVER" >> "$CONFIG_FILE"
fi

if grep -q "^Hostname=" "$CONFIG_FILE"; then
  sed -i "s|^Hostname=.*|Hostname=$AGENT_HOSTNAME|" "$CONFIG_FILE"
else
  echo "Hostname=$AGENT_HOSTNAME" >> "$CONFIG_FILE"
fi

SERVICE_FILE="/lib/systemd/system/zabbix-agent2.service"

# Проверяем, есть ли уже нужные параметры
if ! grep -q "^RuntimeDirectory=zabbix" "$SERVICE_FILE"; then
    echo "RuntimeDirectory=zabbix" >> "$SERVICE_FILE"
fi

if ! grep -q "^RuntimeDirectoryMode=0755" "$SERVICE_FILE"; then
    echo "RuntimeDirectoryMode=0755" >> "$SERVICE_FILE"
fi

systemctl restart zabbix-agent2

#root login restriction
sed -i 's|^root:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$|root:\1:\2:\3:\4:\5:/sbin/nologin|' /etc/passwd
