set -e
echo "install golang"
echo "------------------------------------------------------------"
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum install golang
echo "------------------------------------------------------------"
echo "install cri-dockerd"
echo "------------------------------------------------------------"
yum install wget
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.1/cri-dockerd-0.3.1-3.el7.x86_64.rpm
yum install cri-dockerd-0.3.1-3.el7.x86_64.rpm -y
echo "------------------------------------------------------------"
