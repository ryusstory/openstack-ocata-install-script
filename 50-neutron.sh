#!/bin/bash
source ./config.sh
########## Neutron for controller
## Create DB
mysql -u root -p$DBPASS -e "CREATE DATABASE neutron; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS'; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';"
. ~/admin-openrc

/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c " openstack user create --domain default --password-prompt neutron"
expect {
  -nocase "password" {send "$NEUTRON_PASS\r"; exp_continue }
  -nocase "password" {send "$NEUTRON_PASS\r"; exp_continue }
  $prompt
}
EOE

openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://${HOST_name[0]}:9696
openstack endpoint create --region RegionOne network internal http://${HOST_name[0]}:9696
openstack endpoint create --region RegionOne network admin http://${HOST_name[0]}:9696
PKGS='openstack-neutron openstack-neutron-ml2 openstack-neutron-linuxbridge ebtables'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
cp /etc/neutron/neutron.conf /etc/neutron/backup.neutron.conf
sed -i '/^#/d' /etc/neutron/neutron.conf
sed -i '/^$/d' /etc/neutron/neutron.conf
sed -i "/\[database\]/a connection = mysql+pymysql://neutron:$NEUTRON_DBPASS@${HOST_name[0]}/neutron" /etc/neutron/neutron.conf
sed -i "/\[DEFAULT\]/a core_plugin = ml2\nservice_plugins = router\nallow_overlapping_ips = true\ntransport_url = rabbit://openstack:$RABBIT_PASS@${HOST_name[0]}\nauth_strategy = keystone\nnotify_nova_on_port_status_changes = true\nnotify_nova_on_port_data_changes = true" /etc/neutron/neutron.conf
sed -i "/\[keystone_authtoken\]/a auth_uri = http://${HOST_name[0]}:5000\nauth_url = http://${HOST_name[0]}:35357\nmemcached_servers = ${HOST_name[0]}:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS" /etc/neutron/neutron.conf
sed -i "/\[nova\]/a auth_url = http://${HOST_name[0]}:35357\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nregion_name = RegionOne\nproject_name = service\nusername = nova\npassword = $NOVA_PASS" /etc/neutron/neutron.conf
sed -i '/\[oslo_concurrency\]/a lock_path = /var/lib/neutron/tmp' /etc/neutron/neutron.conf
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/backup.ml2_conf.ini
sed -i '/^#/d' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/\[ml2\]/a type_drivers = flat,vlan,vxlan\ntenant_network_types = vxlan\nmechanism_drivers = linuxbridge,l2population\nextension_drivers = port_security' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/\[ml2_type_flat\]/a flat_networks = provider' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/\[ml2_type_vxlan\]/a vni_ranges = 1:1000' /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i '/\[securitygroup\]/a enable_ipset = true' /etc/neutron/plugins/ml2/ml2_conf.ini
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/backup.linuxbridge_agent.ini
sed -i '/^#/d' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/\[linux_bridge\]/a physical_interface_mappings = provider:$(ip a | grep -B 2 ${HOST_ip[0]} | grep UP | awk -F: {'print $2'} | tr -d ' ')" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/\[vxlan\]/a enable_vxlan = true\nlocal_ip = ${HOST_ip[0]}\nl2_population = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i '/\[securitygroup\]/a enable_security_group = true\nfirewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver' /etc/neutron/plugins/ml2/linuxbridge_agent.ini

cp /etc/neutron/l3_agent.ini /etc/neutron/backup.l3_agent.ini
sed -i '/^#/d' /etc/neutron/l3_agent.ini
sed -i '/^$/d' /etc/neutron/l3_agent.ini
sed -i '/\[DEFAULT\]/a interface_driver = linuxbridge' /etc/neutron/l3_agent.ini

cp /etc/neutron/dhcp_agent.ini /etc/neutron/backup.dhcp_agent.ini
sed -i '/^#/d' /etc/neutron/dhcp_agent.ini
sed -i '/^$/d' /etc/neutron/dhcp_agent.ini
sed -i "/\[DEFAULT\]/a interface_driver = linuxbridge\ndhcp_driver = neutron.agent.linux.dhcp.Dnsmasq\nenable_isolated_metadata = true" /etc/neutron/dhcp_agent.ini

cp /etc/neutron/metadata_agent.ini /etc/neutron/backup.metadata_agent.ini
sed -i '/^#/d' /etc/neutron/metadata_agent.ini
sed -i '/^$/d' /etc/neutron/metadata_agent.ini
sed -i "/\[DEFAULT\]/a nova_metadata_ip = ${HOST_name[0]}\nmetadata_proxy_shared_secret = $METADATA_SECRET" /etc/neutron/metadata_agent.ini

sed -i "/\[neutron\]/a url = http://${HOST_name[0]}:9696\nauth_url = http://${HOST_name[0]}:35357\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nregion_name = RegionOne\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS\nservice_metadata_proxy = true\nmetadata_proxy_shared_secret = $METADATA_SECRET" /etc/nova/nova.conf
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
systemctl enable neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service neutron-l3-agent.service
systemctl restart openstack-nova-api.service
systemctl restart neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
systemctl restart neutron-l3-agent.service

########## Neutron for compute
if [ $COMPUTENODE -eq 0 ]
then 
PKGS='ipset'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
cp /etc/neutron/neutron.conf /etc/neutron/backup2.neutron.conf
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/backup2.linuxbridge_agent.ini
sed -i "/\[vxlan\]/a enable_vxlan = true\nlocal_ip = ${HOST_ip[0]}\nl2_population = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/\[neutron\]/a url = http://${HOST_name[0]}:9696\nauth_url = http://${HOST_name[0]}:35357\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nregion_name = RegionOne\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS" /etc/nova/nova.conf
systemctl restart openstack-nova-compute.service
systemctl restart neutron-linuxbridge-agent.service
elif [ $COMPUTENODE -ge 1 ]
then
cat config.sh > neutron.sh
echo 'NODE_IP=' >> neutron.sh
cat << "EOZ" >> neutron.sh
PKGS='openstack-neutron-linuxbridge ebtables ipset'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS; else yum install -y $PKGS; fi
cp /etc/neutron/neutron.conf /etc/neutron/backup.neutron.conf
sed -i '/^#/d' /etc/neutron/neutron.conf
sed -i '/^$/d' /etc/neutron/neutron.conf
sed -i "/\[DEFAULT\]/a transport_url = rabbit://openstack:$RABBIT_PASS@${HOST_name[0]}\nauth_strategy = keystone" /etc/neutron/neutron.conf
sed -i "/\[keystone_authtoken\]/a auth_uri = http://${HOST_name[0]}:5000\nauth_url = http://${HOST_name[0]}:35357\nmemcached_servers = ${HOST_name[0]}:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS" /etc/neutron/neutron.conf
sed -i '/\[oslo_concurrency\]/a lock_path = /var/lib/neutron/tmp' /etc/neutron/neutron.conf
cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/backup.linuxbridge_agent.ini
sed -i '/^#/d' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i '/^$/d' /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/\[linux_bridge\]/a physical_interface_mappings = provider:$(ip a | grep -B 2 ${NODE_IP} | grep UP | awk -F: {'print $2'} | tr -d ' ')" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/\[vxlan\]/a enable_vxlan = true\nlocal_ip = ${NODE_IP}\nl2_population = true" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/\[securitygroup\]/a enable_security_group = true\nfirewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i "/\[neutron\]/a url = http://${HOST_name[0]}:9696\nauth_url = http://${HOST_name[0]}:35357\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nregion_name = RegionOne\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS" /etc/nova/nova.conf
systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl restart neutron-linuxbridge-agent.service
EOZ
for ((i = 1; i <= $COMPUTENODE; i++))
do
sed -i "/^NODE_IP/c\NODE_IP=\${HOST_ip[$i]}" neutron.sh
ssh ${HOST_name[$i]} 'bash -s' < neutron.sh
done
fi
neutron agent-list