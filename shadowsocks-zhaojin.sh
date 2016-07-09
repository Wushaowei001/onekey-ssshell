#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear
echo
echo "#############################################################"
echo "# One click Install Shadowsocks-Libev With SSShell          #"
echo "# Author: JulySnow <603723963@qq.com>                       #"
echo "# Thanks: @zd423 <zdfans.com> @glzhaojin <zhaoj.in>         #"
echo "#############################################################"
echo

if [[ $EUID -ne 0 ]]; then
    echo "Error:This script must be run as root!" 1>&2
    exit 1
fi

if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi

apt-get -y update
apt-get -y upgrade
echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >>/etc/apt/sources.list
echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" >>/etc/apt/sources.list
apt-get -y install sudo
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
sudo apt-get -y update
sudo apt-get -y install oracle-java8-installer
apt-get -y install python-pip m2crypto git vim
apt-get -y install build-essential
cd /root
git clone -b stable https://github.com/jedisct1/libsodium
cd /root/libsodium
./configure
make
make install
ldconfig
cd /root/
git clone https://github.com/breakwa11/shadowsocks-libev
cd shadowsocks-libev
apt-get install -y wget unzip curl build-essential autoconf libtool libssl-dev asciidoc
apt-get -y --no-install-recommends install xmlto
./configure
sudo make
sudo make install
apt-get -y install libpcap*
ldconfig
if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ] ; then
# 64 Bits
cd /lib64
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap.so
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap-pcap100.so
cd /usr/lib
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap.so
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap-pcap100.so
else
cd /lib
wget https://github.com/JulySnow/onekey-ssshell/raw/master/libjnetpcap-pcap100.so
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap.so
cd /usr/lib
wget https://github.com/JulySnow/onekey-ssshell/raw/master/libjnetpcap-pcap100.so
wget https://github.com/glzjin/ssshell-jar/raw/master/libjnetpcap.so
fi
mkdir /root/ssshell
cd /root/ssshell
git clone -b manyuser https://github.com/breakwa11/shadowsocks.git
wget https://github.com/glzjin/ssshell-jar/raw/master/ssshell_f.jar -O /root/ssshell/ssshell.jar 
wget https://github.com/glzjin/ssshell-jar/raw/master/ssshell.conf -O /root/ssshell/ssshell.conf
pip install speedtest-cli
chmod 600 /root/ssshell/ssshell.conf

cat >>/etc/supervisor/conf.d/ssshell.conf<< EOF
[program:ssshell]
command=java -jar ssshell.jar
directory=/root/ssshell
autostart=true
autorestart=true
user=root
EOF


cat >>/etc/security/limits.conf<< EOF
* soft nofile  512000
* hard nofile 1024000
* soft nproc 512000
* hard nproc 512000
EOF


cat >>/etc/sysctl.conf<<EOF
fs.file-max = 1024000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla
EOF


sed -i "s/exit 0/ulimit -n 512000/g" /etc/rc.local
cat >>/etc/rc.local<<EOF
supervisorctl restart all
exit 0
EOF

echo "ulimit -n 512000" >>/etc/default/supervisor
echo "ulimit -n 512000" >>/etc/profile
source /etc/default/supervisor
source /etc/profile
sysctl -p
ulimit -n 51200


host="127.0.0.1"
read -p "输入MySQL,IP地址或者域名: " host

username="root"
read -p "输入MySQL,用户名: " username

password="root"
read -p "输入MySQL,登录密码: " password
db="shadowsocks"
read -p "输入MySQL,数据库名: " db

IP=$(curl -s -4 icanhazip.com)
if [[ "$IP" = "" ]]; then
IP=$(curl -s -4 ipinfo.io/ip)
fi

nodeid=1
read -p "请输入此节点在面板中的ID号: " nodeid
version=3
nic=eth0

sed -i  "s/addresshere/${host}/" /root/ssshell/ssshell.conf 
sed -i "s/addressnamehere/${db}/" /root/ssshell/ssshell.conf 
sed -i "s/addressusernamehere/${username}/" /root/ssshell/ssshell.conf 
sed -i "s/addressuserpassword/${password}/" /root/ssshell/ssshell.conf 
sed -i "s/iphere/${IP}/" /root/ssshell/ssshell.conf 
sed -i "s/nodeidhere/${nodeid}/" /root/ssshell/ssshell.conf 
sed -i "s/versionhere/${version}/" /root/ssshell/ssshell.conf 
sed -i "s/nichere/${nic}/" /root/ssshell/ssshell.conf 

supervisorctl reload
supervisorctl restart all
ulimit -n 51200

echo
echo "#############################################################"
echo "# One click Install Shadowsocks-Libev With SSShell          #"
echo "# Author: JulySnow <603723963@qq.com>                       #"
echo "# Thanks: @zd423 <zdfans.com> @glzhaojin <zhaoj.in>         #"
echo "#############################################################"
echo
echo "安装成功！"
echo "查看日志:supervisorctl tail -f ssshell stderr"
echo "SSShell 制作:赵今 <zhaoj.in>"
echo "脚本: 七月飞雪"