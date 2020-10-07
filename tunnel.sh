#!/bin/sh

if [[ $EUID -ne 0 ]]; then
   echo "You must be root to do this." 1>&2
   exit 100
fi

apt-get update
apt-get upgrade -y

#installing dependancies
apt-get install -y libnss3* libnspr4-dev gyp ninja-build git cmake libz-dev build-essential 
apt-get install -y pkg-config cmake-data net-tools libssl-dev dnsutils speedtest-cli psmisc
apt-get install -y dropbear stunnel4

#check dropbear is installed 
FILE=/etc/default/dropbear
if [ -f "$FILE" ]; then
    cp "$FILE" /etc/default/dropbear.bak

	sed -i '3 s/1/0/' "$FILE"
	sed -i '5 s/22/8000/' "$FILE"
	sed -i 's@DROPBEAR_EXTRA_ARGS=@DROPBEAR_EXTRA_ARGS="-p 80"@g' /etc/default/dropbear
	sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/banner.html"@g' /etc/default/dropbear
fi

#create dropbear banner
cat >> /etc/banner.html <<EOL
<html>
<body>
<b><h3><font color="#17A589">&#127480;&#127468; JARVIS SG SERVER &#127480;&#127468;</font>
<br>
<br>
<b><font color="#E74C3C">&#128683; NO SPAM &#128683</font></b><br>
<b><font color="#E74C3C">&#128683; NO DDOS &#128683</font></b><br>
<b><font color="#E74C3C">&#128683; NO HACKING &#128683</font></b><br>
<b><font color="#E74C3C">&#128683; NO CARDING &#128683</font></b><br>
<b><font color="#E74C3C">&#128683; NO TORRENT &#128683</font></b><br>
<b><font color="#E74C3C">&#128683; NO OVER DOWNLOADING &#128683</font></b><br>
<br>

<b><h4><font color="#E74C3C">&#9888;&#65039; අවවාදයයි! &#9888;&#65039;</font>
<br>
<font color="#FFFF00"> Torrent සදහා භාවිතා කිරීමෙන් වළකින්න. </font></h4></b><br>
<b><h4><font color="#66ff6d">&#128304; Configured By DINUKA CREATION &#128304;</font>
<br>
<font color="#66ff6d">&#127473;&#127472; WhatsApp : +44 7529 2042 52 &#127473;&#127472;</font></h4></b>
</body>
</html>
EOL
/etc/init.d/dropbear start

#create stunnel conf file	
FILE2=/etc/stunnel/stunnel.conf 
	if [ -f "$FILE2" ]; then
		cp /etc/stunnel/stunnel.conf etc/stunnel/stunnel.conf.bak
		
		cat >> /etc/stunnel/stunnel.conf <<EOL
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
connect = 8000
accept = 443
EOL
	else
		cat >> /etc/stunnel/stunnel.conf <<EOL
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
connect = 8000
accept = 443
EOL
	fi

# creationg keys
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 -subj "/C=AU/ST=./L=./O=./OU=./CN=./emailAddress=."
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

#Enable stunnel service
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 start

#compile and install badvpn
sudo dpkg --configure -a
git clone https://github.com/ambrop72/badvpn.git /root/badvpn
cd /root/badvpn/
cmake /root/badvpn/ -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_SERVER=1 -DBUILD_CLIENT=1 -DBUILD_UDPGW=1 -DBUILD_TUN2SOCKS=1 && make
make install
 
FILE4=/etc/rc.local
if [ -f "$FILE4" ]; then
    cp "$FILE4" /etc/rc.local.bak
	
	sed -i '$ i\badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 999 --client-socket-sndbuf 1048576' /etc/rc.local
	chmod +x /usr/bin/badvpn-udpgw
	badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 999 --client-socket-sndbuf 1048576 > /dev/null &
	chmod +x /etc/rc.local

	else
	echo "exit 0" > /etc/rc.local
	sed -i -e '$ i\badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 999 --client-socket-sndbuf 1048576' /etc/rc.local
	badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 999 --client-socket-sndbuf 1048576 > /dev/null &

fi

/etc/init.d/dropbear restart
/etc/init.d/stunnel4 restart

myip="$(dig +short myip.opendns.com @resolver1.opendns.com)"

echo "Installation has been completed!!"
echo " "
echo "--------------------------- Configuration Setup Server -------------------------"
echo "                            Copyright DINUKA CREATION                              "
echo "--------------------------------------------------------------------------------"
echo " "
echo "Server Information"
echo "   - IP address 	: ${myip}"
echo "   - Dropbear 		: 80"
echo "   - Stunnel 		: 443"
echo " "
echo "create users and enjoy.."
