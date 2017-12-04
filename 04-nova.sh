#!/bin/bash
source ./config.sh
########## Nova for controller
## Create DB
mysql -u root -p$DBPASS -e "CREATE DATABASE nova_api; CREATE DATABASE nova; CREATE DATABASE nova_cell0; GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS'; GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';"
. ~/admin-openrc

/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "openstack user create --domain default --password-prompt nova"
expect {
  -nocase "password" {send "$NOVA_PASS\r"; exp_continue }
  -nocase "password" {send "$NOVA_PASS\r"; exp_continue }
  $prompt
}
EOE
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://$ctr_hostname:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://$ctr_hostname:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://$ctr_hostname:8774/v2.1

/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "openstack user create --domain default --password-prompt placement"
expect {
  -nocase "password" {send "$PLACEMENT_PASS\r"; exp_continue }
  -nocase "password" {send "$PLACEMENT_PASS\r"; exp_continue }
  $prompt
}
EOE
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://$ctr_hostname:8778
openstack endpoint create --region RegionOne placement internal http://$ctr_hostname:8778
openstack endpoint create --region RegionOne placement admin http://$ctr_hostname:8778
yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api
yum install openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler openstack-nova-placement-api
cp /etc/nova/nova.conf /etc/nova/backup.nova.conf
sed -i '/^#/d' /etc/nova/nova.conf
sed -i '/^$/d' /etc/nova/nova.conf

# !!! 뒤의 ratio는 overcommit을 위한 컨피그입니다. 설치 가이드에는 해당 내용이 없습니다.
# https://docs.openstack.org/arch-design/design-compute/design-compute-overcommit.html
sed -i "/\[DEFAULT\]/a my_ip = $ctr_ip\nenabled_apis = osapi_compute,metadata\ntransport_url = rabbit://openstack:$RABBIT_PASS@$ctr_hostname\nuse_neutron = True\nfirewall_driver = nova.virt.firewall.NoopFirewallDriver\ncpu_allocation_ratio = 16.0\ndisk_allocation_ratio = 2.0\nram_allocation_ratio = 2.0" /etc/nova/nova.conf
sed -i "/\[api_database\]/a connection = mysql+pymysql://nova:$NOVA_DBPASS@$ctr_hostname/nova_api" /etc/nova/nova.conf
sed -i "/\[database\]/a connection = mysql+pymysql://nova:$NOVA_DBPASS@$ctr_hostname/nova" /etc/nova/nova.conf
sed -i '/\[api\]/a auth_strategy = keystone' /etc/nova/nova.conf
sed -i "/\[keystone_authtoken\]/a auth_uri = http://controller:5000\nauth_url = http://$ctr_hostname:35357\nmemcached_servers = $ctr_hostname:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = nova\npassword = $NOVA_PASS" /etc/nova/nova.conf
sed -i "/\[vnc\]/a enabled = true\nvncserver_listen = \$my_ip\nvncserver_proxyclient_address = \$my_ip" /etc/nova/nova.conf
sed -i "/\[glance\]/a api_servers = http://$ctr_hostname:9292" /etc/nova/nova.conf
sed -i '/\[oslo_concurrency\]/a lock_path = /var/lib/nova/tmp' /etc/nova/nova.conf
sed -i "/\[placement\]/a os_region_name = RegionOne\nproject_domain_name = Default\nproject_name = service\nauth_type = password\nuser_domain_name = Default\nauth_url = http://$ctr_hostname:35357/v3\nusername = placement\npassword = $PLACEMENT_PASS" /etc/nova/nova.conf

echo "
<Directory /usr/bin>
   <IfVersion >= 2.4>
      Require all granted
   </IfVersion>
   <IfVersion < 2.4>
      Order allow,deny
      Allow from all
   </IfVersion>
</Directory>
" >> /etc/httpd/conf.d/00-nova-placement-api.conf
systemctl restart httpd

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
nova-manage cell_v2 list_cells
systemctl enable openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

########## Nova for compute
cat config.sh > nova.sh
cat << "EOZ" >> nova.sh
yum install -y openstack-nova-compute
cp /etc/nova/nova.conf /etc/nova/backup.nova.conf
sed -i '/^#/d' /etc/nova/nova.conf
sed -i '/^$/d' /etc/nova/nova.conf
sed -i "/\[DEFAULT\]/a my_ip = $cpt_ip\nenabled_apis = osapi_compute,metadata\ntransport_url = rabbit://openstack:$RABBIT_PASS@$ctr_hostname\nuse_neutron = True\nfirewall_driver = nova.virt.firewall.NoopFirewallDriver" /etc/nova/nova.conf
sed -i '/\[api\]/a auth_strategy = keystone' /etc/nova/nova.conf
sed -i "/\[keystone_authtoken\]/a auth_uri = http://$ctr_hostname:5000\nauth_url = http://$ctr_hostname:35357\nmemcached_servers = $ctr_hostname:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = nova\npassword = $NOVA_PASS" /etc/nova/nova.conf
sed -i "/\[vnc\]/a enabled = True\nvncserver_listen = 0.0.0.0\nvncserver_proxyclient_address = \$my_ip\nnovncproxy_base_url = http://controller:6080/vnc_auto.html" /etc/nova/nova.conf
sed -i "/\[glance\]/a api_servers = http://$ctr_hostname:9292" /etc/nova/nova.conf
sed -i '/\[oslo_concurrency\]/a lock_path = /var/lib/nova/tmp' /etc/nova/nova.conf
sed -i "/\[placement\]/a os_region_name = RegionOne\nproject_domain_name = Default\nproject_name = service\nauth_type = password\nuser_domain_name = Default\nauth_url = http://$ctr_hostname:35357/v3\nusername = placement\npassword = $PLACEMENT_PASS" /etc/nova/nova.conf
sed -i '/\[libvirt\]/a virt_type = qemu' /etc/nova/nova.conf
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service
EOZ

if [ $numofcompute -ge 1 ]
then
    sed -i "s/cpt_ip/cpt1_ip/g" nova.sh
    ssh $cpt1_hostname 'bash -s' < nova.sh
fi

if [ $numofcompute -ge 2 ]
then
    sed -i "s/cpt_ip/cpt2_ip/g" nova.sh
    ssh $cpt2_hostname 'bash -s' < nova.sh
fi
openstack hypervisor list
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
nova-status upgrade check