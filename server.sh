#!/bin/bash 
apt install openvpn easy-rsa -y
cp -r /usr/share/easy-rsa /etc/
cd /etc/easy-rsa
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-dh
./easyrsa build-server-full server nopass
openvpn --genkey secret /etc/easy-rsa/pki/ta.key
./easyrsa gen-crl
cp -rp /etc/easy-rsa/pki/{ca.crt,dh.pem,ta.key,crl.pem,issued,private} /etc/openvpn/

# config
echo "port 1194" > /etc/openvpn/server.conf
echo "proto udp4" >> /etc/openvpn/server.conf
echo "dev tun" >> /etc/openvpn/server.conf
echo "ca ca.crt" >> /etc/openvpn/server.conf
echo "cert issued/server.crt" >> /etc/openvpn/server.conf
echo "key private/server.key  # This file should be kept secret" >> /etc/openvpn/server.conf
echo "dh dh.pem " >> /etc/openvpn/server.conf
echo "topology subnet" >> /etc/openvpn/server.conf
echo "server 172.16.20.0 255.255.255.0" >> /etc/openvpn/server.conf
echo "ifconfig-pool-persist /var/log/openvpn/ipp.txt" >> /etc/openvpn/server.conf
echo "push \"redirect-gateway def1 bypass-dhcp\"" >> /etc/openvpn/server.conf
echo "push \"dhcp-option DNS 1.1.1.1\"" >> /etc/openvpn/server.conf
echo "push \"dhcp-option DNS 8.8.8.8\"" >> /etc/openvpn/server.conf
echo "client-to-client" >> /etc/openvpn/server.conf
echo "keepalive 10 120" >> /etc/openvpn/server.conf
echo "tls-auth ta.key 0 # This file is secret" >> /etc/openvpn/server.conf
echo "cipher AES-256-CBC" >> /etc/openvpn/server.conf
echo "persist-key" >> /etc/openvpn/server.conf
echo "persist-tun" >> /etc/openvpn/server.conf
echo "status /var/log/openvpn/openvpn-status.log" >> /etc/openvpn/server.conf
echo "log-append  /var/log/openvpn/openvpn.log" >> /etc/openvpn/server.conf
echo "verb 3" >> /etc/openvpn/server.conf
echo "explicit-exit-notify 1" >> /etc/openvpn/server.conf
echo "auth SHA512" >> /etc/openvpn/server.conf

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

ufw allow 1194/udp

# get interface name
IFACENAME=`ip link show | grep -v lo | awk -F: '$0 ~ "^[0-9]+:" {print $2}' | tr -d ' '`
UFW_RULES=`cat /etc/ufw/before.rules`

# comment out those lines if you don't want to allow internet access
echo "*nat" > /etc/ufw/before.rules
echo ":POSTROUTING ACCEPT [0:0]" >> /etc/ufw/before.rules
echo "-A POSTROUTING -s 172.16.20.0/24 -o $IFACENAME -j MASQUERADE" >> /etc/ufw/before.rules
echo "COMMIT" >> /etc/ufw/before.rules
echo "$UFW_RULES" >> /etc/ufw/before.rules

# ufw enable packet forwarding
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

ufw reload
systemctl enable --now openvpn-server@server

echo "DONE"
echo "NOW RUN client.sh with client names as args to generate clients and .ovpn files, for example:"
echo "client.sh jkowalski tsmith admin1 "
