#!/bin/bash
# usage:
# client.sh jkowalski tsmith admin1 
server_ip=`ip a | grep inet | grep -v inet6 | grep -v 172.16 | grep -v 127.0 | awk '{print $2}' | cut -d'/' -f 1`
echo "GENERATING CONFIGS FOR $server_ip openvpn server"

# this commands are already in server configuration script
# apt install easy-rsa -y
# cp -r /usr/share/easy-rsa /etc/

workingdir=`pwd`
cd /etc/easy-rsa

for client_name in "$@"; do
    echo "Generating for user: $client_name"
    client_dir=/etc/openvpn/client/$client_name
    ./easyrsa build-client-full $client_name nopass
    mkdir $client_dir
    cp -rp /etc/easy-rsa/pki/{ca.crt,issued/$client_name.crt,private/$client_name.key} $client_dir

    TA_FILE="/etc/openvpn/server/ta.key"
    CA_FILE="$client_dir/ca.crt"
    CRT_FILE="$client_dir/$client_name.crt"
    KEY_FILE="$client_dir/$client_name.key"
    OUTPUT=$workingdir/$client_name.ovpn

    cat /usr/share/doc/openvpn/examples/sample-config-files/client.conf | grep -v "^#.*$" | grep -v "^;.*$" | grep -v "\.crt" | grep -v "cipher" | grep -v "client.key" | grep -v '^$' | sed "s/my-server-1/$server_ip/g" > $OUTPUT

    {
            echo "auth SHA512"
            echo "data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC"
            echo "<tls-auth>"
            cat "$TA_FILE"
            echo "</tls-auth>"
            echo "<ca>"
            cat "$CA_FILE"
            echo "</ca>"
            echo "<cert>"
            cat "$CRT_FILE"
            echo "</cert>"
            echo "<key>"
            cat "$KEY_FILE"
            echo "</key>"
    } >> $OUTPUT
done

cd $workingdir