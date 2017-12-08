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
다운로드 및 실행권한 부여 이후 config.sh 파일을 자신의 환경에 맞게 수정해야합니다.

QUIETYUM : yum 설치 부분에 QUIET 옵션으로, 1로 설정하면 -quiet 옵션이 들어가 yum output이 최소화 됩니다.

INSTALL_HEAT : HEAT 설치 여부입니다. 1 이면 설치 스크립트에 heat 설치가 들어가게 됩니다.

INIT_OPENSTACK : 99-init.sh 스크립트 실행여부로 오픈스택 가이드의 기본 "인스턴스 실행" 부분의 cirros 이미지 추가, 프로바이더 네트워크까지 연동 필요시 내용 수정 필요 (현재는 192.168.0.0/24이 provider 네트워크로 잡힘)

COMPUTENODE : 컴퓨트 노드 수로 0이면 All-In-One 형태로 설치. 해당 숫자만큼 아래 HOST_----[n] 내용이 참조됨.

HOST_ip, name, pass : 노드별 내용을 배열 형태로 입력,[0]은 controller, [1] 부터 compute 서버로 입력.


 - Case 1

만약, ALL IN ONE 설치, yum 설치시 최소 출력, HEAT 설치, 초기화 제외로 설치하려면 아래와 같이 설정됩니다.

```
QUIETYUM=1
INSTALL_HEAT=1
INIT_OPENSTACK=0
COMPUTENODE=0

HOST_ip[0]=192.168.0.11
HOST_name[0]=controller
HOST_pass[0]=qwe123

...
```

 - Case 2

만약, 컨트롤러+컴퓨트 서버2, yum 설치 기본 출력, HEAT 설치, 초기화 설정 포함 시 

```
QUIETYUM=0
INSTALL_HEAT=1
INIT_OPENSTACK=1
COMPUTENODE=2

HOST_ip[0]=192.168.0.11
HOST_name[0]=controller
HOST_pass[0]=qwe123

HOST_ip[1]=192.168.0.21
HOST_name[1]=compute1
HOST_pass[1]=qwe123

HOST_ip[1]=192.168.0.22
HOST_name[1]=compute2
HOST_pass[1]=qwe123

...
```

위와 같은 형태로 수정이 완료되면 아래 00-pre.sh 를 실행하시면 모든 절차가 진행됩니다.

```
./00-pre.sh
```
