set -e
echo "install new kernel"
echo "------------------------------------------------------------"
yum -y update
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install kernel-lt
echo "------------------------------------------------------------"
echo "kernel updated. reboot then vim the /etc/default/grub then grub2-mkconfig -o /boot/grub2/grub.cfg"
