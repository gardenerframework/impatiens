set -e
echo "adding overlay & br_netfilter to modules-load.d"
echo "------------------------------------------------------------"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
echo "------------------------------------------------------------"
echo "load overlay & br_netfilter"
echo "------------------------------------------------------------"
modprobe overlay
modprobe br_netfilter
echo "------------------------------------------------------------"
lsmod | grep br_netfilter
lsmod | grep overlay
echo "------------------------------------------------------------"
echo "turn on ip_forward and bridge-nf-call-iptables system params"
echo "------------------------------------------------------------"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system
echo "------------------------------------------------------------"
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
echo "------------------------------------------------------------"