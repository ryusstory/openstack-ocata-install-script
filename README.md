# openstack-ocata-install-script

## 테스트 환경

 - CENTOS 7 x64 1708 (on VMWARE WORKSTATION)

 - 가상머신의 네트워크 타입 : bridge ( 공유기 네트워크에 직접 연결되기 위함 )

## 스크립트 다운로드 및 환경 설정

```
yum install -y -q git
git clone https://github.com/ryusstory/openstack-ocata-install-script.git
cd openstack-ocata-install-script/
chmod +x *.sh
```

### config.sh 파일 설명

다운로드 및 실행권한 부여 이후 config.sh 파일을 자신의 환경에 맞게 수정해야합니다.

 - **QUIETYUM** 

yum 설치 부분에 QUIET 옵션으로, 1로 설정하면 -quiet 옵션이 들어가 yum output이 최소화 됩니다.

 - **INSTALL_HEAT**

HEAT 설치 여부입니다. 1 이면 설치 스크립트에 heat 설치가 들어가게 됩니다.

 - **INIT_OPENSTACK**
오픈스택 가이드의 기본 "인스턴스 실행" 부분의 cirros 이미지 추가,네트워크 생성,연동, 인스턴스 실행을 해주는 스크립트
99-init.sh 실행여부 (현재는 192.168.0.0/24이 provider 네트워크로 잡혀 있으나 필요시 네트워크 부분 수정 필요)

 - **COMPUTENODE**
컴퓨트 노드 수로 0이면 All-In-One 형태로 설치. 해당 숫자만큼 아래 HOST_----[n] 내용이 참조됨.

 - **HOST_ip, name, pass**
서버별 내용을 배열 형태로 입력,[0]은 controller, [1] 부터 compute 서버의 내용 입력.

 - **xxxx_PASS**
스크립트에 쓰일 패스워드 파일. 오픈스택에서는 해쉬 형태로 권장하나 테스트 전용으로 기본형태의 패스워드만 사용
필요시 변경해서 사용

### config.sh 파일 설정 예시

#### Case 1

- [x] 호스트 서버 1 ( All-In-One )
- [ ] 호스트 서버 2+
- [x] Yum 최소 출력 (quiet 옵션)
- [x] HEAT 설치
- [x] 초기화 (Launch a instance)

만약, 위와 같은 옵션으로 스크립트를 실행하려면 아래 컨피그 처럼 설정하시면 됩니다.

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

#### Case 2

- [ ] 호스트 서버 1 ( All-In-One )
- [x] 호스트 서버 2+
- [x] Yum 최소 출력 (quiet 옵션)
- [x] HEAT 설치
- [x] 초기화 (Launch a instance)

만약, 위와 같은 옵션으로 스크립트를 실행하려면 아래 컨피그 처럼 설정하시면 됩니다.

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

HOST_ip[2]=192.168.0.22
HOST_name[2]=compute2
HOST_pass[2]=qwe123

...
```

## 스크립트 실행

위의 내용을 참고하여 수정이 완료되면 아래 00-pre.sh 를 실행하시면 됩니다.

```
./00-pre.sh
```
