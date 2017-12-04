#!/bin/bash
. ~/admin-openrc

openstack network create --share --external \
  --provider-physical-network provider \
  --provider-network-type flat provider

openstack subnet create --network provider \
  --allocation-pool start=192.168.0.150,end=192.168.0.200 \
  --dns-nameserver 168.126.63.1 --gateway 192.168.0.1 \
  --subnet-range 192.168.0.0/24 provider

openstack network create selfservice
openstack subnet create --network selfservice \
  --allocation-pool start=10.0.0.100,end=10.0.0.200 \
  --dns-nameserver 168.126.63.1 --gateway 10.0.0.1 \
  --subnet-range 10.0.0.0/24 selfservice

openstack router create router

neutron router-interface-add router selfservice

neutron router-gateway-set router provider

openstack flavor create --vcpus 1 --ram 64 --disk 1 m1.nano
curl -O http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

openstack server create --flavor m1.nano --image cirros \
  --nic net-id=$(openstack network show selfservice | grep " id " | awk '{print $4}') --security-group default \
  --key-name mykey selfservice-instance

openstack server add floating ip selfservice-instance $(openstack floating ip create provider | grep floating_ip_address | awk '{print $4}')
