#!/bin/bash
source ./config.sh
########## Glance for controller
. ~/admin-openrc
mysql -u root -p$DBPASS -e "CREATE DATABASE glance; GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS'; GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';"

/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "openstack user create --domain default --password-prompt glance"
expect {
  -nocase "password" {send "$GLANCE_PASS\r"; exp_continue }
  -nocase "password" {send "$GLANCE_PASS\r"; exp_continue }
  $prompt
}
EOE
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://$ctr_hostname:9292
openstack endpoint create --region RegionOne image internal http://$ctr_hostname:9292
openstack endpoint create --region RegionOne image admin http://$ctr_hostname:9292
yum install -y openstack-glance
cp /etc/glance/glance-api.conf /etc/glance/backup.glance-api.conf
sed -i '/^#/d' /etc/glance/glance-api.conf
sed -i '/^$/d' /etc/glance/glance-api.conf
sed -i "/\[database\]/a connection = mysql+pymysql://glance:$GLANCE_DBPASS@$ctr_hostname/glance" /etc/glance/glance-api.conf
sed -i "/\[keystone_authtoken\]/a auth_uri = http://$ctr_hostname:5000\nauth_url = http://$ctr_hostname:35357\nmemcached_servers = $ctr_hostname:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = glance\npassword = $GLANCE_PASS" /etc/glance/glance-api.conf
sed -i '/\[paste_deploy\]/a flavor = keystone' /etc/glance/glance-api.conf
sed -i '/\[glance_store\]/a stores = file,http\ndefault_store = file\nfilesystem_store_datadir = /var/lib/glance/images/' /etc/glance/glance-api.conf
cp /etc/glance/glance-registry.conf /etc/glance/backup.glance-registry.conf
sed -i '/^#/d' /etc/glance/glance-registry.conf
sed -i '/^$/d' /etc/glance/glance-registry.conf
sed -i "/\[database\]/a connection = mysql+pymysql://glance:$GLANCE_DBPASS@$ctr_hostname/glance" /etc/glance/glance-registry.conf
sed -i "/\[keystone_authtoken\]/a auth_uri = http://$ctr_hostname:5000\nauth_url = http://$ctr_hostname:35357\nmemcached_servers = $ctr_hostname:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = glance\npassword = $GLANCE_PASS" /etc/glance/glance-registry.conf
sed -i '/\[paste_deploy\]/a flavor = keystone' /etc/glance/glance-registry.conf
su -s /bin/sh -c "glance-manage db_sync" glance
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service
#curl -O http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
#openstack image create "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public
