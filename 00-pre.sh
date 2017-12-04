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
hostnamectl set-hostname $ctr_hostname
# daum repo
cat << "EOZ" >> daumrepo.sh
tar cvzf /etc/yum.repos.d/original.tar.gz /etc/yum.repos.d/*.repo
rm -rf /etc/yum.repos.d/*.repo
echo '[base]
name=CentOS-$releasever - Base
baseurl=http://ftp.daumkakao.com/centos/$releasever/os/$basearch/
gpgcheck=0 
[updates]
name=CentOS-$releasever - Updates
baseurl=http://ftp.daumkakao.com/centos/$releasever/updates/$basearch/
gpgcheck=0
[extras]
name=CentOS-$releasever - Extras
baseurl=http://ftp.daumkakao.com/centos/$releasever/extras/$basearch/
gpgcheck=0' > /etc/yum.repos.d/Daum.repo
yum clean all && yum repolist
EOZ

# 컴퓨터 서버 수에 따라 호스트네임 추가
yum install -y expect
echo "$ctr_ip $ctr_hostname" >> /etc/hosts
if [ $numofcompute -ge 1 ] ;then echo "$cpt1_ip $cpt1_hostname" >> /etc/hosts;fi
if [ $numofcompute -ge 2 ] ;then echo "$cpt2_ip $cpt2_hostname" >> /etc/hosts;fi

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "ssh-copy-id -f $ctr_hostname"
expect {
"yes/no" { send "yes\r"; exp_continue}
-nocase "password" {send "$ctr_pass\r"; exp_continue }
$prompt
}
EOE

if [ $numofcompute -ge 1 ]
then
/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "ssh-copy-id -f $cpt1_hostname"
expect {
"yes/no" { send "yes\r"; exp_continue}
-nocase "password" {send "$cpt1_pass\r"; exp_continue }
$prompt
}
EOE
fi

if [ $numofcompute -ge 2 ]
then
/usr/bin/expect <<EOE
set prompt "#"
spawn bash -c "ssh-copy-id -f $cpt2_hostname"
expect {
"yes/no" { send "yes\r"; exp_continue}
-nocase "password" {send "$cpt2_pass\r"; exp_continue }
$prompt
}
EOE
fi

if [ $numofcompute -ge 1 ]
then
    ssh $cpt1_hostname 'bash -s' < daumrepo.sh
fi
if [ $numofcompute -ge 2 ]
then
    ssh $cpt2_hostname 'bash -s' < daumrepo.sh
fi

ssh $ctr_hostname
