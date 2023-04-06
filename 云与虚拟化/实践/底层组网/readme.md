# 物理网络

## 三网分割

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

System(节点, 节点)
Boundary(控制网络, 控制网络) {
    Container(控制网络网卡, 控制网络网卡, vlan-a, 10.0.0.2)
}
Boundary(虚拟机流量网络, 虚拟机流量网络) {
    Container(虚拟机流量网络网卡, 虚拟机流量网络网卡, vlan-b, 10.1.0.2)
}
Boundary(块存储流量网络, 块存储流量网络) {
    Container(块存储流量网络网卡, 块存储流量网络网卡, vlan-c, 10.2.0.2)
}

节点 -d-> 控制网络网卡
节点 -d-> 虚拟机流量网络网卡
节点 -d-> 块存储流量网络网卡

@enduml
```

从网络划分上，分为

* 控制网络: 云控制节点与云工作节点之间的控制程序通信用，比如心跳检测，指令下发，监控指标收集等
* 虚拟机流量网络: 用于虚拟机的虚拟网卡流量出入，由于选择vxlan的网络模型，因此需要配置ip地址
  (vlan模型不配，但是vlan模型用的少)
* 块存储流量网络: 用于虚拟机挂载的云硬盘与SAN存储或分布式存储之间的流量转发

在网段上，内网网段按照/16切成3个不同的子网即可，每个子网有6万多个ip够用了，如上图就按照10.0.0.0/16、10.1.0.0/16和10.2.0.0/16分别切成控制网、虚拟机流量网和块存储流量网。
具体选什么内网网址的时候有以下几个注意:

* 不要和浮动ip段冲突(一般不会冲突)
* 不要和企业内网的ip段冲突(否则企业内网的ip访问控制节点(ssh)
  或者对接一些企业内部系统的时候，配路由/nat的时候容易把脑子烧了)，最好是从企业机房可用的ip段中取一部分使用
* 3个网的ip段也不要彼此覆盖，因为部分程序(比如ceph)工作节点和管控节点之间还是要通过ip通信的，如果ip端有冲突容易发生问题

## 多AZ后的物理网络连接

在要跨AZ部署后两个AZ之间的vlan二层肯定不通，因此需要路由转发

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(AZ_1, az-1, 某机房) {
    System(节点, 节点)
    Container(专线1, 专线盒子)
    Container(路由1, 路由)
    Boundary(控制网络, 控制网络) {
        Container(控制网络网卡, 控制网络网卡, vlan-a, 10.0.0.2)
    }
    Boundary(虚拟机流量网络, 虚拟机流量网络) {
        Container(虚拟机流量网络网卡, 虚拟机流量网络网卡, vlan-b, 10.1.0.2)
    }
    Boundary(块存储流量网络, 块存储流量网络) {
        Container(块存储流量网络网卡, 块存储流量网络网卡, vlan-c, 10.2.0.2)
    }
    节点 -r-> 路由1: 跨AZ流量
    路由1 -r-> 专线1: 跨AZ流量
    
}

Boundary(AZ_2, az-2, 某机房) {
    System(节点2, 节点)
    Container(专线2, 专线盒子)
    Container(路由2, 路由)
    Boundary(控制网络2, 控制网络) {
        Container(控制网络网卡2, 控制网络网卡, vlan-x, 10.3.0.2)
    }
    Boundary(虚拟机流量网络2, 虚拟机流量网络) {
        Container(虚拟机流量网络网卡2, 虚拟机流量网络网卡, vlan-y, 10.4.0.2)
    }
    Boundary(块存储流量网络2, 块存储流量网络) {
        Container(块存储流量网络网卡2, 块存储流量网络网卡, vlan-z, 10.5.0.2)
    }
    节点2 -l-> 路由2: 跨AZ流量
    路由2 -l-> 专线2: 跨AZ流量
}
节点 -d-> 控制网络网卡
节点 -d-> 虚拟机流量网络网卡
节点 -d-> 块存储流量网络网卡

节点2 -d-> 控制网络网卡2
节点2 -d-> 虚拟机流量网络网卡2
节点2 -d-> 块存储流量网络网卡2

专线1 <-l-> 专线2

@enduml
```

通过这样使得两个集群的三层网络能互通，整个上层应用感知起来像是在一个网络中一样。如果为了高品质的跨ZA的虚拟机东西向流量，可以把专线分成2根

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(AZ_1, az-1, 某机房) {
    System(节点, 节点)
    Container(专线1, 专线盒子, 控制流量) #red
    Container(专线3, 专线盒子, 虚拟机流量) #orange
    Container(路由1, 路由) #green
    Boundary(控制网络, 控制网络) {
        Container(控制网络网卡, 控制网络网卡, vlan-a, 10.0.0.2)
    }
    Boundary(虚拟机流量网络, 虚拟机流量网络) {
        Container(虚拟机流量网络网卡, 虚拟机流量网络网卡, vlan-b, 10.1.0.2)
    }
    Boundary(块存储流量网络, 块存储流量网络) {
        Container(块存储流量网络网卡, 块存储流量网络网卡, vlan-c, 10.2.0.2)
    }
    节点 -r-> 路由1: 跨AZ流量
    路由1 -r-> 专线1: 跨AZ流量
    路由1 -u-> 专线3: 跨AZ流量
    
}

Boundary(AZ_2, az-2, 某机房) {
    System(节点2, 节点)
    Container(专线2, 专线盒子, 控制流量)  #red
    Container(专线4, 专线盒子, 虚拟机流量) #orange
    Container(路由2, 路由) #green
    Boundary(控制网络2, 控制网络) {
        Container(控制网络网卡2, 控制网络网卡, vlan-x, 10.3.0.2)
    }
    Boundary(虚拟机流量网络2, 虚拟机流量网络) {
        Container(虚拟机流量网络网卡2, 虚拟机流量网络网卡, vlan-y, 10.4.0.2)
    }
    Boundary(块存储流量网络2, 块存储流量网络) {
        Container(块存储流量网络网卡2, 块存储流量网络网卡, vlan-z, 10.5.0.2)
    }
    节点2 -l-> 路由2: 跨AZ流量
    路由2 -l-> 专线2: 跨AZ流量
    路由2 -u-> 专线4: 跨AZ流量
}
节点 -d-> 控制网络网卡
节点 -d-> 虚拟机流量网络网卡
节点 -d-> 块存储流量网络网卡

节点2 -d-> 控制网络网卡2
节点2 -d-> 虚拟机流量网络网卡2
节点2 -d-> 块存储流量网络网卡2

专线1 <-l-> 专线2
专线3 <-l-> 专线4

@enduml
```

也就是

* 目标cidr: 10.4.0.0/16 -> az-1的橘黄色专线
* 目标cidr: 10.1.0.0/16 -> az-2的橘黄色专线

**警告**: 弄专线是要钱的，请量力而行；另外可以等真正的虚拟机数量上来了再弄这个专线然后切路由不迟；

# 云公共网络

云的公共网络是一个三层网络，可用ip池为100.64.0.0/10，如果部署在与互联网隔绝的行业内网，则ip池可以将互联网的网段拿过来使用。

* 首先需要对地址池分段，不妨分出一段为100.64.0.0/13作为支持所有vpc的路由接入的网络，
  这样vpc就能访问公共网络中提供的云服务(大概50万个可用ip)。
* 其次内部云服务用于浮动ip挂载的段可以按需分配，建议从100.72开始按照C段分配
* 第三100.64.0.0/13的路由(不是每个vpc的路由)需要在每个fip网络内创建接口(连入这个子网)这样才能进行两个网络的路由转发

云公共网络**必须**是一个基于隧道封装的overlay网络，否则考虑一下跨AZ的时候，公共网络的二层vlan tag填什么？

# 云公共网络与underlay网络的dnat转换

如果云公共网络背后的服务是虚拟机实现的，可以通过给虚拟机挂载云公共网络浮动ip的方法实现。但如果云公共网络背后的服务是物理机实现，则需要在整个交换网络中有一台能支持vxlan的3层交换机进行dnat转发。
具体如图所示，假设块存储流量网络中的存储设备提供了文件存储的能力，这个能力想要对所有VPC开放，支持租户在文件存储内创建自己的文件夹。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
System(vpc路由, vpc路由)
Boundary(vpc, vpc, vni-200) {
    Container(vmport, 172.16.0.7, 虚拟机)
    Container(router_p, 172.16.0.1, 路由接口)
    vmport <-r-> router_p
}
Boundary(云公共网络, 云公共网络, 100.64.0.0/10) {
    Boundary(vpc_r, vpc路由器网络, vni-300) {
        Container(router_p_p, 100.64.0.100, 路由接口)
        Container(router_p_r, 100.64.0.1, 网关接口) #red
        router_p <-r-> vpc路由
        vpc路由 <-r-> router_p_p
        router_p_p <-u-> router_p_r
    }
    System(vpc路由网关, 网关) #red
    router_p_r<-u->vpc路由网关
    Boundary(vpc_f, 存储服务网络, vni-400) {
        Container(router_p_r_2, 100.72.0.60, 网关接口) #red
        Container(100.72.0.5, 100.72.0.5, 文件存储)
        vpc路由网关 <-d-> router_p_r_2
        router_p_r_2 <--> 100.72.0.5
    }
}
Boundary(块存储网络, 块存储网络, 10.2.0.0/16) {
    System(10.2.0.9, 10.2.0.9, 文件存储接口) #green
}
System(交换机, 交换机, vxlan ip gateway) #green
100.72.0.5 <-d-> 交换机
交换机 <-r-> 10.2.0.9

@enduml
```




