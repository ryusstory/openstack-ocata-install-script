# openstack-ocata-install-script
openstack ocata installation through "openstack installation guide" by shell script

this is just batch script, so there's no rollback mechanism on this script.
In my case, I tested these code in VMs that have snapshot.


```
yum install -y -q git
git clone https://github.com/ryusstory/openstack-ocata-install-script.git
cd openstack-ocata-install-script/
chmod +x *.sh
./00-pre.sh
```
00-pre.sh contains "ssh $ctr_hostname", but make sure prompt your controller's hostname.
Otherwise, running rabbitmq through 'localhost' hostname will throw an error.

run other scripts after running 00-pre.sh
```
./01-basic.sh && ./02-keystone.sh && ./03-glance.sh && ./04-nova.sh && ./05-neutron.sh && ./06-horizon.sh
```
