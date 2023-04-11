set -e
echo "install cri-dockerd"
echo "------------------------------------------------------------"
yum install wget
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.1/cri-dockerd-0.3.1-3.el7.x86_64.rpm
yum install cri-dockerd-0.3.1-3.el7.x86_64.rpm -y
echo "------------------------------------------------------------"
systemctl enable cri-docker
service cri-docker start
ll /run/cri-dockerd.sock
echo "------------------------------------------------------------"
