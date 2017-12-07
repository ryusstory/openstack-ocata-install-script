#!/bin/bash
source ./config.sh
. ~/admin-openrc
yum install -y openstack-dashboard
cp /etc/openstack-dashboard/local_settings /etc/openstack-dashboard/backup.local_settings
sed -i '/^#/d' /etc/openstack-dashboard/local_settings
sed -i '/^$/d' /etc/openstack-dashboard/local_settings
sed -i "s/OPENSTACK_HOST = '127.0.0.1'/OPENSTACK_HOST = '$ctr_hostname'/g" /etc/openstack-dashboard/local_settings
sed -i "/ALLOWED_HOSTS/c\ALLOWED_HOSTS = ['*']" /etc/openstack-dashboard/local_settings
sed -i "/django.core.cache.backends.memcached.MemcachedCache,/a         'LOCATION': '$ctr_hostname:11211','" /etc/openstack-dashboard/local_settings
echo "SESSION_ENGINE = 'django.contrib.sessions.backends.cache'" >> /etc/openstack-dashboard/local_settings
sed -i '/OPENSTACK_KEYSTONE_URL/c\OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST' /etc/openstack-dashboard/local_settings
echo "OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True" >> /etc/openstack-dashboard/local_settings
echo 'OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,}
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
' >> /etc/openstack-dashboard/local_settings
sed -i 's/'enable_router': False,/'enable_router': True,/g' /etc/openstack-dashboard/local_settings
sed -i 's/'enable_quotas': False,/'enable_quotas': True,/g' /etc/openstack-dashboard/local_settings
sed -i 's/'enable_distributed_router': False,/'enable_distributed_router': True,/g' /etc/openstack-dashboard/local_settings
sed -i 's/'enable_ha_router': False,/'enable_ha_router': True,/g' /etc/openstack-dashboard/local_settings
sed -i 's/'enable_lb': False,/'enable_lb': True,/g' /etc/openstack-dashboard/local_settings
sed -i 's/'enable_firewall': False,/'enable_firewall': True,/g' /etc/openstack-dashboard/local_settings
sed -i 's/'enable_vpn': False,/'enable_vpn': True,/g' /etc/openstack-dashboard/local_settings
sed -i 's/'enable_fip_topology_check': False,/'enable_fip_topology_check': True,/g' /etc/openstack-dashboard/local_settings
sed -i '/TIME_ZONE/c\TIME_ZONE = "UTC"' /etc/openstack-dashboard/local_settings
#아래는 버그 관련
echo "WSGIApplicationGroup %{GLOBAL}" >> /etc/httpd/conf.d/openstack-dashboard.conf

systemctl restart httpd.service memcached.service
