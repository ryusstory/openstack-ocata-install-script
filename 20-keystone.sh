#!/bin/bash
source ./config.sh
########## Keystone for controller
mysql -uroot -p$DBPASS -e "CREATE DATABASE keystone; GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS'; GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';"
yum install -y openstack-keystone httpd mod_wsgi
# 기존 파일은 backup. 으로 저장 sed를 통해 #으로 시작하는 줄(주석)과 빈줄이 모두 삭제됩니다. 이후 모든 컨피그 파일 동일.
cp /etc/keystone/keystone.conf /etc/keystone/backup.keystone.conf
sed -i '/^#/d' /etc/keystone/keystone.conf
sed -i '/^$/d' /etc/keystone/keystone.conf
sed -i "/\[database\]/a connection = mysql+pymysql://keystone:$KEYSTONE_DBPASS@$ctr_hostname/keystone" /etc/keystone/keystone.conf
sed -i '/\[token\]/a provider = fernet' /etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password $ADMIN_PASS --bootstrap-admin-url http://$ctr_hostname:35357/v3/ --bootstrap-internal-url http://$ctr_hostname:5000/v3/ --bootstrap-public-url http://$ctr_hostname:5000/v3/ --bootstrap-region-id RegionOne
sed -i "s/^#ServerName www.example.com:80/ServerName $ctr_hostname/g" /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl restart httpd.service
## Creating Domain
echo "export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$ctr_hostname:35357/v3
export OS_IDENTITY_API_VERSION=3
" > ~/admin-openrc
. ~/admin-openrc
openstack project create --domain default --description "Service Project" service
