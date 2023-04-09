set -e
echo "switch the swap off"
echo "------------------------------------------------------------"
swapoff -a
free -h
echo "------------------------------------------------------------"
echo "done if you see things like Swap:            0B          0B          0B"
echo "vi /etc/fstab and add # before /dev/mapper/centos-swap or things like that"