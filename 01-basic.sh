#!/bin/bash
## 01-basic.sh
source ./config.sh
## disable firewall
yum remove -y firewalld
iptables -F
## NTP Installation
## 테스트 스크립트 편의상 0.0.0.0/0 으로 할당하였습니다. 해당 서브넷만 주셔야 합니다.
yum install -y chrony
echo "allow 0.0.0.0/0" >> /etc/chrony.conf
systemctl enable chronyd.service
systemctl start chronyd.service
## Add Repository
yum install -y centos-release-openstack-ocata
## Upgrade Package
yum upgrade -y
# yum upgrade는 update에 --obsoletes 플래그를 추가한 것과 같습니다.
# 해당 내용은 update 명령어에서 obsoletes(오래된, 쓸모 없게 된) 플래그를 사용하면 필요없는 패키지를 
# 삭제한다고 나와 있습니다. 즉, upgrade는 update --obsoletes 효과를 나타낸다고 합니다. 
## Install openstack client
yum install -y python-openstackclient
## Install Selinux-policy
yum install -y openstack-selinux

cat config.sh > basic.sh
cat << "EOZ" >> basic.sh
hostnamectl set-hostname $cpt1_hostname
# 컴퓨터 서버 수에 따라 호스트네임 추가
echo "$ctr_ip $ctr_hostname" >> /etc/hosts
if [ $numofcompute -ge 1 ] ;then echo "$cpt1_ip $cpt1_hostname" >> /etc/hosts;fi
if [ $numofcompute -ge 2 ] ;then echo "$cpt2_ip $cpt2_hostname" >> /etc/hosts;fi

#chrony 설치
yum install -y chrony
# chrony 설정
sed -i "/^server/ s/^#*/#/" /etc/chrony.conf
echo "server $ctr_hostname iburst" >> /etc/chrony.conf
systemctl enable chronyd.service
systemctl start chronyd.service
# remove firewalld
yum remove -y firewalld
iptables -F
## Add Repository
yum install -y centos-release-openstack-ocata
## Upgrade Package
yum upgrade -y
## Install openstack client
yum install -y python-openstackclient
## Install Selinux-policy
yum install -y openstack-selinux
EOZ

if [ $numofcompute -ge 1 ]
then
    ssh $cpt1_hostname 'bash -s' < basic.sh
fi
if [ $numofcompute -ge 2 ]
then
    ssh $cpt2_hostname 'bash -s' < basic.sh
fi

########## Basic Openstack config for controller
## Install Mariadb
yum install -y mariadb mariadb-server python2-PyMySQL
echo "
[mysqld]
bind-address = $ctr_ip
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
symbolic-links=0
!includedir /etc/my.cnf.d
" > /etc/my.cnf
systemctl enable mariadb.service
systemctl restart mariadb.service
echo -e "\n\n$DBPASS\n$DBPASS\ny\nn\ny\ny\n " | /usr/bin/mysql_secure_installation
mysql -u root -p$DBPASS -e "set global max_connections = 4096;"

## Install RABBIT MQ 
yum install -y rabbitmq-server
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

## Install memcached
yum install -y memcached python-memcached
sed -i "s/::1/::1,$ctr_hostname/g" /etc/sysconfig/memcached
systemctl enable memcached.service
systemctl start memcached.service

