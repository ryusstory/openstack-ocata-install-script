#!/bin/bash
source ./config.sh
# DB
mysql -u root -p$DBPASS -e "CREATE DATABASE heat; GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' IDENTIFIED BY '$HEAT_DBPASS'; GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' IDENTIFIED BY '$HEAT_DBPASS';"
. ~/admin-openrc

/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "openstack user create --domain default --password-prompt heat"
expect {
  -nocase "password" {send "$HEAT_PASS\r"; exp_continue }
  -nocase "password" {send "$HEAT_PASS\r"; exp_continue }
  $prompt
}
EOE
openstack role add --project service --user heat admin

openstack service create --name heat --description "Orchestration" orchestration
openstack service create --name heat-cfn --description "Orchestration"  cloudformation
openstack endpoint create --region RegionOne orchestration public http://$ctr_hostname:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration internal http://$ctr_hostname:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne orchestration admin http://$ctr_hostname:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne cloudformation public http://$ctr_hostname:8000/v1
openstack endpoint create --region RegionOne cloudformation internal http://$ctr_hostname:8000/v1
openstack endpoint create --region RegionOne cloudformation admin http://$ctr_hostname:8000/v1
openstack domain create --description "Stack projects and users" heat

/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "openstack user create --domain heat --password-prompt heat_domain_admin"
expect {
  -nocase "password" {send "$HEAT_DOMAIN_PASS\r"; exp_continue }
  -nocase "password" {send "$HEAT_DOMAIN_PASS\r"; exp_continue }
  $prompt
}
EOE
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin
openstack role create heat_stack_owner
openstack role create heat_stack_user

yum install -y openstack-heat-api openstack-heat-api-cfn openstack-heat-engine

sed -i "/\[database\]/a connection = mysql+pymysql://heat:$HEAT_DBPASS@$ctr_hostname/heat" /etc/heat/heat.conf
sed -i "/\[DEFAULT\]/a transport_url = rabbit://openstack:$RABBIT_PASS@$ctr_hostname\nheat_metadata_server_url = http://$ctr_hostname:8000\nheat_waitcondition_server_url = http://$ctr_hostname:8000/v1/waitcondition\nstack_domain_admin = heat_domain_admin\nstack_domain_admin_password = $HEAT_DOMAIN_PASS\nstack_user_domain_name = heat" /etc/heat/heat.conf
sed -i "/\[keystone_authtoken\]/a auth_uri = http://$ctr_hostname:5000\nauth_url = http://$ctr_hostname:35357\nmemcached_servers = $ctr_hostname:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = heat\npassword = $HEAT_PASS" /etc/heat/heat.conf
sed -i "/\[trustee\]/a auth_type = password\nauth_url = http://$ctr_hostname:35357\nusername = heat\npassword = $HEAT_PASS\nuser_domain_name = default" /etc/heat/heat.conf
sed -i "/\[clients_keystone\]/a auth_uri = http://$ctr_hostname:35357" /etc/heat/heat.conf
sed -i "/\[ec2authtoken\]/a auth_uri = http://$ctr_hostname:5000" /etc/heat/heat.conf

su -s /bin/sh -c "heat-manage db_sync" heat

systemctl enable openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
systemctl start openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
