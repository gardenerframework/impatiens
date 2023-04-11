# 宗旨

本文主要提供一种基于生产环境部署文档的实验环境说明和验证，请首先阅读[[k8s生产集群部署](..%2Fk8s%E7%94%9F%E4%BA%A7%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2)]
中的所有章节来然后再看实验

# 企业网

按照
[[网络规划](..%2Fk8s%E7%94%9F%E4%BA%A7%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2%2F1.%20%E7%BD%91%E7%BB%9C%E8%A7%84%E5%88%92)]
文档的说明，
将企业网定为实验环境所在宿主机的网络192.168.0.0/24

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(192.168.0.0/24, 192.168.0.0/24) {
    System(192.168.0.105, 192.168.0.105, 开发主机)
    System(192.168.0.50, 192.168.0.50, 虚拟机基准镜像制备机)
}

@enduml
```

其中

* 192.168.0.105是一台开发主机主要进行云管平台的各种开发
* 192.168.0.50是一台制备实验环境的制备机，主要用于各种实验主机的制备

# 容器云网络划分

| 网络用途  | cidr           |
|-------|----------------|
| 管理网   | 100.64.0.0/21  |
| 容器流量网 | 100.64.32.0/21 |
| 存储网   | 100.64.64.0/21 |

# 连接网关和设置SNAT规则

创建一个路由器主机当做管理网关使用，并设置管理网段的SANT为192.168.0.51从而支持管理网的非k8s集群主机出网

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

System(路由器, 路由器)
Boundary(192.168.0.0/24, 192.168.0.0/24, 企业网) {
    Container(192.168.0.51, 192.168.0.51)
}

Boundary(100.64.0.0/21, 100.64.0.0/21, 管理网) {
    Container(100.64.0.1, 100.64.0.1)
}
Boundary(100.64.32.0/21, 100.64.32.0/21, 流量网) {
    Container(100.64.32.1, 100.64.32.1)
}
Boundary(100.64.64.0/21, 100.64.64.0/21, 存储网) {
    Container(100.64.64.1, 100.64.64.1)
}

路由器 -u-> 192.168.0.51
路由器 -d-> 100.64.0.1
路由器 -d-> 100.64.32.1
路由器 -d-> 100.64.64.1
@enduml
```

```shell
iptables -t nat -A POSTROUTING -s 100.64.0.0/21 -j SNAT --to-source 192.168.0.51
iptables -t nat -A POSTROUTING -s 100.64.32.0/21 -j SNAT --to-source 192.168.0.51
iptables -t nat -A POSTROUTING -s 100.64.64.0/21 -j SNAT --to-source 192.168.0.51

iptables -t filter -I FORWARD -s 100.64.0.0/21 -j ACCEPT
iptables -t filter -I FORWARD -s 100.64.32.0/21 -j ACCEPT
iptables -t filter -I FORWARD -s 100.64.64.0/21 -j ACCEPT

iptables -t filter -I FORWARD -d 100.64.0.0/21 -j ACCEPT
iptables -t filter -I FORWARD -d 100.64.32.0/21 -j ACCEPT
iptables -t filter -I FORWARD -d 100.64.64.0/21 -j ACCEPT
```

# 准备部署容器云

按照网关规划文档说明，管理网的云管理系统网段为100.64.0.0/20，k8s集群网的网段为100.64.64.0/20，企业内网应用映射区的网段为100.64.128.0/20

## 在云管网映射跳板机

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

System(路由器, 路由器)
Boundary(192.168.0.0/24, 192.168.0.0/24, 企业网) {
    Boundary(eth0, eth0, 1个网卡多个ip) { 
        Container(192.168.0.51, 192.168.0.51)
        Container(192.168.0.52, 192.168.0.52)
    }
}

Boundary(100.64.0.0/20, 100.64.0.0/21, 管理网) {
    Container(100.64.0.1, 100.64.0.1)
    System(100.64.0.52, 100.64.0.52, 跳板机)
}


路由器 -u-> 192.168.0.51
路由器 -d-> 100.64.0.1
路由器 -[#green]u-> 192.168.0.52
路由器 -[#green]d-> 100.64.0.52

@enduml
```

完成在企业网开放一个ip(192.168.0.52)充当管理网跳板机的作用，该跳板机在管理网的ip是100.64.0.52。 这台跳板机也当做部署机来使用。

在实验中，假设没有找到双网口的跳板机，需要在路由器上进行端口映射
(需要在51绑定的网卡上再绑1个ip，否则192网段的出入会有2个网卡互相干扰路由)

```shell
iptables -t nat -I PREROUTING -d 192.168.0.52 -j DNAT --to 100.64.0.52
iptables -t nat -I POSTROUTING -s 100.64.0.52 -j SNAT --to-source 192.168.0.52

```

这样只要跳板机的流量从路由器上过，都会被映射为192.168.0.52，外网访问192.168.0.52也相当于访问了跳板机。跳板机出互联网的流量也使用192.168.0.52

## 在云管网映射内部7层应用负载均衡器

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

System(路由器, 路由器)
Boundary(192.168.0.0/24, 192.168.0.0/24, 企业网) {
    Boundary(eth0, eth0, 1个网卡多个ip) { 
        Container(192.168.0.51, 192.168.0.51)
        Container(192.168.0.52, 192.168.0.52)
        Container(192.168.0.53, 192.168.0.53)
    }
}

Boundary(100.64.0.0/20, 100.64.0.0/21, 管理网) {
    Container(100.64.0.1, 100.64.0.1)
    System(100.64.0.52, 100.64.0.52, 跳板机)
    System(100.64.0.53, 100.64.0.53, lb)
}


路由器 -u-> 192.168.0.51
路由器 -d-> 100.64.0.1
路由器  -u-> 192.168.0.52
路由器 -d-> 100.64.0.52
路由器  -u-> 192.168.0.53
路由器 -d-> 100.64.0.53

@enduml
```

在云管管和企业网内申请一个ip，部署一个nginx 7层代理。
该代理主要解决企业通过http访问管理网内部系统的问题(比如监控系统)，以及作为api server的核心代理给k8s集群使用

```shell
iptables -t nat -I PREROUTING -d 192.168.0.53 -j DNAT --to 100.64.0.53
iptables -t nat -I POSTROUTING -s 100.64.0.53 -j SNAT --to-source 192.168.0.53

```

## 修改路由规则，内网互相连接不通过nat转发

配置了snat和dnat规则后，管理、流量、存储网内部的ip互相ping会因为命中规则而导致进行地址转换。
比如从负载均衡(100.64.0.53)上ping一个存储网的ip(100.64.64.2)
基于`iptables -t nat -I POSTROUTING -s 100.64.0.53 -j SNAT --to-source 192.168.0.53`规则，源ip就会变成192网段的53。

存储网网关100.64.64.1 ping 100.64.64.2，
由于`iptables -t nat -A POSTROUTING -s 100.64.64.0/21 -j SNAT --to-source 192.168.0.51`规则的存在，
导致回包的源地址被映射为192网段的51，于是需要向raw表加入snat豁免

```shell
## 转发豁免
iptables -t raw -A PREROUTING -s 100.64.0.0/21 -d 100.64.32.0/21 -j NOTRACK
iptables -t raw -A PREROUTING -s 100.64.32.0/21 -d 100.64.0.0/21 -j NOTRACK

iptables -t raw -A PREROUTING -s 100.64.0.0/21 -d 100.64.64.0/21 -j NOTRACK
iptables -t raw -A PREROUTING -s 100.64.64.0/21 -d 100.64.0.0/21 -j NOTRACK

iptables -t raw -A PREROUTING -s 100.64.32.0/21 -d 100.64.64.0/21 -j NOTRACK
iptables -t raw -A PREROUTING -s 100.64.64.0/21 -d 100.64.32.0/21 -j NOTRACK

## 网管直接发包豁免
iptables -t raw -A OUTPUT -s 100.64.0.1 -d 100.64.0.1/21 -j NOTRACK
iptables -t raw -A OUTPUT -s 100.64.32.1 -d 100.64.32.1/21 -j NOTRACK
iptables -t raw -A OUTPUT -s 100.64.64.1 -d 100.64.64.1/21 -j NOTRACK

```

解决完后发现依然不通存储网的地址，这也很正常:
因为100.64.0.53按照默认路由向管理网网关发出数据包，网关内部按照路由将mac转为存储网网关的网卡发出，100.64.64.2收到后，确实发现mac来自存储网网关。
不过，回包的时候它发现自己不是有管理网的网卡(100.64.0.2)么，回包应该直接从这个网卡回。但是这个ip可不是来源ip，于是100.64.64.2觉得这个包出问题了，就没回应

# 开始创建首个master节点

创建首个master节点，按照以下ip在各个网络中分配网卡

| 网络用途  | 节点ip           |
|-------|----------------|
| 管理网   | 100.64.0.2/21  |
| 容器流量网 | 100.64.32.2/21 |
| 存储网   | 100.64.64.2/21 |