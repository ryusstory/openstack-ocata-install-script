## config.sh
#https://docs.openstack.org/ocata/install-guide-rdo/overview.html#example-architecture
#numofcompute는 컴퓨터 서버 개수. 0=올인원(현재 구현X), 1~2 = 컨트롤러1 + 컴퓨트n 개의 서버
numofcompute=1
ctr_ip=192.168.0.111
ctr_hostname=controller
ctr_pass=qwe123

cpt1_ip=192.168.0.121
cpt1_hostname=compute1
cpt1_pass=qwe123

cpt2_ip=192.168.0.122
cpt2_hostname=compute2
cpt2_pass=qwe123

#https://docs.openstack.org/ocata/install-guide-rdo/environment-security.html
DBPASS=DBPASS
ADMIN_PASS=ADMIN_PASS
DASH_DBPASS=DASH_DBPASS
GLANCE_DBPASS=GLANCE_DBPASS
GLANCE_PASS=GLANCE_PASS
KEYSTONE_DBPASS=KEYSTONE_DBPASS
METADATA_SECRET=METADATA_SECRET
NEUTRON_DBPASS=NEUTRON_DBPASS
NEUTRON_PASS=NEUTRON_PASS
NOVA_DBPASS=NOVA_DBPASS
NOVA_PASS=NOVA_PASS
PLACEMENT_PASS=PLACEMENT_PASS
RABBIT_PASS=RABBIT_PASS
HEAT_DBPASS=HEAT_DBPASS
