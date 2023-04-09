set -e
echo "installing docker-ce"
echo "------------------------------------------------------------"
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "------------------------------------------------------------"
echo "docker-ce installed"
echo "------------------------------------------------------------"
docker -v
echo "------------------------------------------------------------"
echo "starting docker service"
echo "------------------------------------------------------------"
systemctl enable docker
systemctl start docker