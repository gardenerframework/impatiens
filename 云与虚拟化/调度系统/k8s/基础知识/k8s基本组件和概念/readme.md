# k8s简介

k8s是一个容器调度和管理系统，它管理底层的物理机(也可以是云主机)，将应用运转所需的容器调度到集群的虚拟机上，并保证容器按照既定的副本数工作。
当容器或底层设施发生问题时，再进行重新调度。

# k8s节点的主要类型

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

System(k8s_master, k8s master) #red
System(k8s_worker, k8s worker) #green
k8s_master <-r- k8s_worker
@enduml
```

k8s作为一个主机集群管理系统，分为k8s master和k8s worker两种节点类型。

* k8s master主要是集群的控制节点，通常不承担工作负载的调度
* k8s worker是集群的工作节点，运行工作负载

在规模较小的集群下，k8s master和worker可以合并在一起，变成这样

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(主机, 主机) {
    System(k8s_master, k8s master) #red
    System(k8s_worker, k8s worker) #green
}
@enduml
```

# k8s核心组件

![k8s核心组件.png](k8s核心组件.png)

这张图来自官网，我来稍微做下翻译

## 控制平面

k8s控制平台可以和上文中的"k8s master"画等号，它包括

* etcd: 至关重要的元数据存储数据库，etcd挂掉了 = 控制面板挂掉了，etcd丢数据了 = 集群里运行的应用负载等等之类的部署脚本，配置项之类的元数据有可能就没了。
  下面是官方原话。

```text
If your Kubernetes cluster uses etcd as its backing store, make sure you have a back up plan for those data.
```

* api server: 至关重要的接口，k8s的所有组件之间都是调用api server的功能，api挂了 = 控制平面挂了
* controller manager: k8s由一系列控制器，比如副本数控制器什么的，不同的控制器实现不同的集群功能，哪个挂了哪种功能就没了
* scheduler: 调度器，基于反亲和等一系列策略实现k8s的调度

## 工作节点

* kubelet: 相当于工作节点上的agent，负责pod的管理
* kube-proxy: 主要在k8s工作节点上实现k8s的"Service"资源的网络访问功能

组件间的协同逻辑大致是

* 要下管控指令给api server(比如创建pod)
* api server负责把指令持久化到etcd
* scheduler调api server取出要调度的pod并找到一台机器
* 告诉kubelet去创建pod
* pod状态由kubelet写回到api server并持久化到etcd

# k8s命令行工具

k8s的所有管理可以通过调api
server的接口完成([https://kubernetes.io/docs/concepts/overview/kubernetes-api/](https://kubernetes.io/docs/concepts/overview/kubernetes-api/))
，也就是你知道玩的明白，你可以用curl搞定一切。但是k8s知道你懒，所以提供了kubectl命令行工具。

# pod

pod是k8s种非常重要的一个对象，是k8s工作负载的最小调度单元

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(pod, pod) {
    Container(container1, 容器, 文件下载器)
    Container(container2, 容器, 比如是下载后的处理器)
    
    System(磁盘, 磁盘和目录)
    System(网络地址, 网络地址和端口)
    
    container1 -d-> 网络地址
    container2 -d-> 网络地址
    
    container1 -d-> 磁盘
    container2 -d-> 磁盘
}
@enduml
```

可以将pod类比一个小的虚拟机，它能容纳若干个应用容器，可以类比为虚拟机内的进程。这些应用容器共享pod内部的系统卷，网络协议栈。
在同一个pod中的容器彼此可以用localhost进行通信，这也就意味着容器彼此不能监听同样端口。同时两个容器也能读写同一个位置的文件。
不过说实话，我从来都是一个应用容器一个pod，没挑战过一堆容器放一个pod里。
实际生产中很少直接调api接口创建pod，而是创建它的管理型资源，比如Deployment，Job什么的。这些资源或者会保证pod的副本数，或者确保pod包含的容器运行成功。
pod有2中容器，一种叫init容器，是用来初始化的，init容器跑完了才是真的应用容器。

官网给了个例子很形象

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app.kubernetes.io/name: MyApp
spec:
  containers:
    - name: myapp-container
      image: busybox:1.28
      command: [ 'sh', '-c', 'echo The app is running! && sleep 3600' ]
  initContainers:
    - name: init-myservice
      image: busybox:1.28
      command: [ 'sh', '-c', "until nslookup myservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done" ]
    - name: init-mydb
      image: busybox:1.28
      command: [ 'sh', '-c', "until nslookup mydb.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for mydb; sleep 2; done" ]
```

初始化容器一直在等数据库和一个依赖服务可用，可用了才把应用容器跑起来

# 基于pod的控制器

pod很少被单独建立，而是通过Deployment、StatefulSet、DaemonSet、Job等资源声明创建，创建后被这些资源控制器管理。
这些资源控制器会检测pod的运行状态，保证pod按照声明的预期状态工作，比如副本数，需要运行成功几次等。

# Service

pod运行起来后会被要求彼此通信，此时注意，k8s不推荐之间使用pod的ip进行通信。
因为pod被认为是不稳定运行的资源，随时有可能因为硬件故障或者自身程序的问题崩溃而导致重新生成。
重新生成pod后，pod的ip地址会变化。因此**绝对**不能使用常规虚拟机启动后ip不变的观念来使用pod。
要在pod之间彼此通信，需要创建"Service"。

简单来说，Service代表pod要对外暴露的4层服务，它的一个样例yaml格式如下


```yaml

```



