# kubeadm join后kubelet拿到不正确的配置文件

问题: kubeadm join后，kubelet会获取

```yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd #使用systemd
address: 100.64.0.2 #kublet工作在管理网网卡
maxPods: 110 #一个节点最多多少个pod，默认值就是110
```

即第一个节点写入的kubelet的配置，这个配置如果写了ip，其它的节点加入就都废了

# woker kubelet加入api server报"Unauthorized"

问题: 使用kubeadm安装完工作节点后无法加入api server，说未授权。

* 可能的原因: kubelet的证书中的cn名称有问题，与kubelet要使用的节点名称不一致

* 解决办法:

1. 改节点名称

```shell
hostnamectl set-hostname k8s-worker-1
```

2. 检查kubeadm使用的配置文件的注册名要和上面的一致

```yaml
# 加入集群的配置
kind: JoinConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
#...
nodeRegistration:
  name: k8s-worker-1 #这里写上节点名称
#...
```

3. yum remove kubelet后重装，重新加入集群

