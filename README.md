# openstack-ocata-install-script

**해당 내용은 오픈스택 공식 가이드에 기초하여 만든 설치 스크립트입니다.**

openstack ocata installation through "openstack installation guide" by shell script

 - tested Centos 7 1708

**롤백 매커니즘이 없는 스크립트로 중간에 문제가 생길 경우 되돌릴 수 없습니다.**

**제 경우 초기상태 스냅샷을 뜬 VM을 통해 테스트 했습니다.**

This is just batch script, so there's no rollback mechanism on this script.

In my case, I tested these code in VMs that have snapshot.


```
yum install -y -q git
git clone https://github.com/ryusstory/openstack-ocata-install-script.git
cd openstack-ocata-install-script/
chmod +x *.sh
./00-pre.sh
```
**00-pre.sh 스크립트에 hostname으로 접속하는 스크립트가 포함은 되어있지만**

**실행 자체는 컨트롤러의 호스트네임이 프롬프트된 상태로 실행하여야 합니다.**

**위의 내용을 지키지 않으시면, rabbitmq 에서 호스트네임으로 인한 에러가 발생합니다.**

00-pre.sh contains "ssh $ctr_hostname" command but make sure prompt your controller's hostname.

Otherwise, running rabbitmq through 'localhost' hostname will throw an error.


**00-pre.sh 실행 이후 나머지 스크립트를 실행하시면 됩니다.**

run other scripts after running 00-pre.sh

```
./01-basic.sh && ./02-keystone.sh && ./03-glance.sh && ./04-nova.sh && ./05-neutron.sh && ./06-horizon.sh
```
