set -e
echo "turning firewalld off"
echo "------------------------------------------------------------"
systemctl stop firewalld
systemctl disable firewalld
