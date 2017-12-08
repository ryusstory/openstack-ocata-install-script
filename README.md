# openstack-ocata-install-script

환경 설명

 - CENTOS 7 x64 1708 
 
 - VMWARE WORKSTATION

 - VIRTUAL NETWORK : Bridge

```

yum install -y -q git
git clone https://github.com/ryusstory/openstack-ocata-install-script.git
cd openstack-ocata-install-script/
chmod +x *.sh

```
이후 config.sh 파일 환경에 맞게 수정 필요

QUIETYUM : yum 설치 부분에 QUIET 옵션 

INSTALL_HEAT : HEAT 설치 여부

INIT_OPENSTACK : 99-init.sh 스크립트 실행여부, cirros 이미지 > 프로바이더 네트워크까지 연동 필요시 내용 수정 필요 (기본은 iptime 공유기 기본 네트워크 설정 192.168.0.0/24)

COMPUTENODE : 컴퓨트 노드 수 . 0이면 All-In-One 형태로 설치. 해당 숫자만큼 아래 HOST_xx 내용 참조됨

HOST_ip, name, pass : [0] 항목에 controller 및 올인원 노드 정보, [1] 부터 compute 서버 내용.

```
QUIETYUM=1
INSTALL_HEAT=1
INIT_OPENSTACK=0
COMPUTENODE=0

HOST_ip[0]=192.168.0.11
HOST_name[0]=controller
HOST_pass[0]=qwe123

HOST_ip[1]=192.168.0.21
HOST_name[1]=compute1
HOST_pass[1]=qwe123

...
```

위와 같이 필요 내용 수정 후 실행

```
./00-pre.sh
```
