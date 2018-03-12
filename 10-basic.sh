#!/bin/bash
## 01-basic.sh
source ./config.sh
## disable firewall
yum remove -q -y firewalld
iptables -F
## NTP Installation
## 테스트 스크립트 편의상 0.0.0.0/0 으로 할당하였습니다. 원래는 해당 서브넷만 주셔야 합니다.
PKGS='chrony'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
echo "allow 0.0.0.0/0" >> /etc/chrony.conf
systemctl enable chronyd.service
systemctl start chronyd.service
## Add Repository
PKGS='centos-release-openstack-ocata'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
## Upgrade Package
if [ $QUIETYUM -eq 1 ]; then yum upgrade -q -y $PKGS; else yum upgrade -y $PKGS; fi
## Install openstack client
PKGS='python-openstackclient'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
## Install Selinux-policy
PKGS='openstack-selinux'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi

cat config.sh > basic.sh
cat << "EOZ" >> basic.sh
hostnamectl set-hostname $temp_hostname
# 컴퓨터 서버 수에 따라 호스트네임 추가
for ((i = 0; i <= $COMPUTENODE; i++))
do
    printf "%s\t%s\t%s \n" ${HOST_ip[$i]} ${HOST_name[$i]} >> /etc/hosts
done
#chrony 설치
PKGS='chrony'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
# chrony 설정
sed -i "/^server/ s/^#*/#/" /etc/chrony.conf
echo "server ${HOST_ip[0]} iburst" >> /etc/chrony.conf
systemctl enable chronyd.service
systemctl start chronyd.service
# remove firewalld
yum remove -q -y firewalld
iptables -F
## Add Repository
PKGS='centos-release-openstack-ocata'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
## Upgrade Package
if [ $QUIETYUM -eq 1 ]; then yum upgrade -q -y $PKGS; else yum upgrade -y $PKGS; fi
## Install openstack client
PKGS='python-openstackclient'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
## Install Selinux-policy
PKGS='openstack-selinux'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
EOZ

for ((i = 1; i <= $COMPUTENODE; i++))
do
    ssh ${HOST_name[$i]} 'bash -s' < basic.sh
done

########## Basic Openstack config for controller
## Install Mariadb
PKGS='mariadb mariadb-server python2-PyMySQL'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
echo "
[mysqld]
bind-address = ${HOST_ip[0]}
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
symbolic-links=0
!includedir /etc/my.cnf.d
" > /etc/my.cnf
sed -i "/\[Service\]/a LimitNOFILE=4096" /usr/lib/systemd/system/mariadb.service
systemctl daemon-reload
systemctl enable mariadb.service
systemctl start mariadb.service
echo -e "\n\n$DBPASS\n$DBPASS\ny\nn\ny\ny\n " | /usr/bin/mysql_secure_installation
#mysql -u root -p$DBPASS -e "set global max_connections = 4096;"

## Install RABBIT MQ 
PKGS='rabbitmq-server'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

## Install memcached
PKGS='memcached python-memcached'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
sed -i "s/::1/::1,${HOST_name[0]}/g" /etc/sysconfig/memcached
systemctl enable memcached.service
systemctl start memcached.service

