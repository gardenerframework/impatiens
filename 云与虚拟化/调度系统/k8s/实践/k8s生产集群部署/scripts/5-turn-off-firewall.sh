set -e
echo "turning firewalld off"
systemctl stop firewalld
systemctl disable firewalld
