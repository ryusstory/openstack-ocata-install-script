#!/bin/bash
. ~/admin-openrc

# INTERNET_INTERFACE=$(ip route get 8.8.8.8 | awk -F' ' '{print $(NF-2);exit}')
# INTERNET_SUBNET=$(ip route get 8.8.8.8 | awk -F' ' '{print $NF;exit}' | awk -F. '{print $(NF-3)"."$(NF-2)"."$(NF-1)".0";exit}')
# INTERNET_NETWORK=$(ip route get 8.8.8.8 | awk -F' ' '{print $NF;exit}' | awk -F. '{print $(NF-3)"."$(NF-2)"."$(NF-1)".0";exit}')/$(ip address show dev $(ip route get 8.8.8.8 | awk -F' ' '{print $(NF-2);exit}') | grep $(ip route get 8.8.8.8 | awk -F' ' '{print $NF;exit}') | awk -F'/' '{print $2}' | awk -F' ' '{print $1}')
# INTERNET_GATEWAY=$(ip route get 8.8.8.8 | awk -F' ' '{print $3}')
# 
# openstack network create --share --external --provider-physical-network provider --provider-network-type flat provider
# openstack subnet create --network provider --allocation-pool start=192.168.0.101,end=192.168.0.199 --dns-nameserver 168.126.63.1 --gateway 192.168.0.1 --subnet-range 192.168.0.0/24 provider
# openstack network create --share "external service"
# openstack subnet create --network "external service" --allocation-pool start=192.168.3.101,end=192.168.3.199 --dns-nameserver 168.126.63.1 --gateway 192.168.3.1 --subnet-range 192.168.3.0/24 "external service-subnet"
# openstack network create --share "internal service"
# openstack subnet create --network "internal service" --allocation-pool start=172.16.1.101,end=172.16.1.199 --dns-nameserver 168.126.63.1 --gateway 172.16.1.1 --subnet-range 172.16.1.0/24 "internal service-subnet"
# openstack network create --share "dmz service"
# openstack subnet create --network "dmz service" --allocation-pool start=172.16.10.101,end=172.16.10.199 --dns-nameserver 168.126.63.1 --gateway 172.16.10.1 --subnet-range 172.16.10.0/24 "dmz service-subnet"
# openstack router create router
# neutron router-interface-add router "external service-subnet"
# neutron router-gateway-set router provider
# openstack flavor create --vcpu 4 --ram 8192 --disk 111 --public "c4r8d111"

openstack network create --share --external --provider-physical-network provider --provider-network-type flat provider
openstack subnet create --network provider --allocation-pool start=192.168.0.101,end=192.168.0.199 --dns-nameserver 168.126.63.1 --gateway 192.168.0.1 --subnet-range 192.168.0.0/24 provider
openstack network create --share selfservice
openstack subnet create --network selfservice --allocation-pool start=10.0.0.101,end=10.0.0.199 --dns-nameserver 168.126.63.1 --gateway 10.0.0.1 --subnet-range 10.0.0.0/24 selfservice

openstack router create router
neutron router-interface-add router selfservice
neutron router-gateway-set router provider
openstack flavor create --vcpus 1 --ram 256 --disk 1 m1.nano

curl -O http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img
openstack image create "cirros" --file cirros-0.3.5-x86_64-disk.img --disk-format qcow2 --container-format bare --public

openstack security group create initrule
openstack security group rule create --protocol icmp $(openstack security group show initrule | grep -e " id " | awk '{print $4}')
openstack security group rule create --protocol tcp --dst-port 22 $(openstack security group show initrule | grep -e " id " | awk '{print $4}')
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack server create --flavor m1.nano --image cirros --nic net-id=$(openstack network show selfservice | grep " id " | awk '{print $4}') --security-group initrule --key-name mykey selfservice-instance
openstack server add floating ip selfservice-instance $(openstack floating ip create provider | grep floating_ip_address | awk '{print $4}')

