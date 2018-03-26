#!/bin/bash
## 01-basic.sh
source ./config.sh
########## Basic config for controller
## Internet Check
if ping -c 1 google.com >> /dev/null 2>&1; then
    echo "It's Online."
else
    echo "It's Offline. Sorry."
    exit 1
fi
## Hostname
hostnamectl set-hostname ${HOST_name[0]}

# 컴퓨터 서버 수에 따라 호스트네임 추가
for ((i = 0; i <= $COMPUTENODE; i++))
do
    printf "%s\t%s\t%s \n" ${HOST_ip[$i]} ${HOST_name[$i]} >> /etc/hosts
done

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

PKGS='expect'
if [ $QUIETYUM -eq 1 ]; then yum install -q -y $PKGS
else yum install -y $PKGS; fi

for ((i = 0; i <= $COMPUTENODE; i++))
do
/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "ssh-copy-id ${HOST_name[$i]}"
expect {
"yes/no" { send "yes\r"; exp_continue}
-nocase "password" {send "${HOST_pass[$i]}\r"; exp_continue }
$prompt
}
EOE
done
for ((i = 1; i <= $COMPUTENODE; i++))
do
ssh ${HOST_name[$i]} "hostnamectl set-hostname ${HOST_name[$i]}"
EOE
done

if [ $INSTALL_HEAT -eq 1 ]; then shfile=($(ls | grep -e "[0-9][0-9][-].*[.]sh" | grep -v "00-pre.sh" | sed 's/:.*//'))
else shfile=($(ls | grep -e "[0-9][0-9][-].*[.]sh" | grep -v "00-pre.sh" | grep -v "heat" | sed 's/:.*//'))
fi
if [ $INIT_OPENSTACK -eq 0 ]; then unset "shfile[${#shfile[@]}-1]"; fi

# copy config file for script
for ((i = 0; i <= $COMPUTENODE; i++))
do
    scp ./config.sh ${HOST_name[$i]}:
done

# run scripts
echo ${shfile[*]}
for i in "${shfile[@]}"
do
ssh ${HOST_name[0]} 'bash -s' < $i
done



