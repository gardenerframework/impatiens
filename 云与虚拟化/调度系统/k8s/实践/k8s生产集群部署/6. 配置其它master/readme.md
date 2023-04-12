# 变更名称

```shell
hostnamectl set-hostname k8s-worker-2
reboot
```

# 拉镜像

```shell
docker pull registry.aliyuncs.com/google_containers/pause:3.6
docker tag registry.aliyuncs.com/google_containers/pause:3.6 registry.k8s.io/pause:3.6

```

# 将新的节点加入集群

把下面的执行了就行，token、hash、key之类的都是之前创建主节点的时候记下来的

```shell
kubeadm join 100.64.0.53:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:aeca62fe59a5bf550a6b9dd46ce29cea61787f0305d9d7dd6f0a0ae5f008de53 \
    --control-plane --certificate-key ee0b1aea0dfe382acd48ad72e73b807ec2f0182b1acee189cba6cd7b0d94665e \
    --cri-socket=unix:///var/run/cri-dockerd.sock \
    --v=5 \
    --apiserver-advertise-address=100.64.0.3
        
        
```

# 检查manifest

和第一个master一样，检查"/etc/kubernetes/manifests"目录下的配置文件都对不对，默认情况下没问题

