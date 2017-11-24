### 여기는 클라이언트의 설정들
### yum install > yum install --disablerepo='*' --enablerepo=osrepo
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

echo "[osrepo]
name=openstack local repo
baseurl=http://192.168.0.119/osrepo/
enabled=1
gpgcheck=0" > /etc/yum.repos.d/mypsql.repo

yum clean all && yum repolist
