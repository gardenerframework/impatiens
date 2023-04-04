# 公共网络

在之前的文章中可以，为了支持vpc对等连接，所有路由其实都连入了一个以10.64.0.0/10作为cidr的公共网络

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Boundary(shared, 公共网络, 10.64.0.0/10) {
    Container(port1, vr-1, 10.64.0.2)
    Container(port2, vr-2, 10.64.0.3)
    Container(port3, vr-3, 10.64.0.4)
}
Boundary(vpc1, vpc-1) {
    System(router1, vr-1)
    router1 -d-> port1
}
Boundary(vpc2, vpc-2) {
    System(router2, vr-2)
    router2 -d-> port2
}
Boundary(vpc3, vpc-3) {
    System(router3, vr-3)
    router3 -d-> port3
}
@enduml
```

这个公共网络相当于具有了所有vpc都可以访问的能力，那么云的开发团队就可以选择在这个公共网络中做文章，将托管的云服务也放到这个公共网络中，
并通过在这个网络申请和使用浮动ip的做法让vpc的云主机进行访问

# 放置公共基础设施

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Boundary(shared, 公共网络, 10.64.0.0/10) {
    Boundary(vr子网, vr子网, 10.64.0.0/11) { 
        Container(port1, vr-1, 10.64.0.2)
        Container(port2, vr-2, 10.64.0.3)
        Container(port3, vr-3, 10.64.0.4)
    }
    Boundary(公共设施子网, 公共设施子网, 10.96.0.0/24) {
        Container(dns, dns, 10.64.0.5) #red
        Container(yum, yum repo, 10.64.0.6) #red
        Container(apt, apt repo, 10.64.0.7) #red
        Container(windows_server, Windows激活服务器, 10.64.0.7) #red
    }
}
Boundary(vpc1, vpc-1) {
    System(router1, vr-1)
    router1 -d-> port1
}
Boundary(vpc2, vpc-2) {
    System(router2, vr-2)
    router2 -d-> port2
}
Boundary(vpc3, vpc-3) {
    System(router3, vr-3)
    router3 -d-> port3
}
@enduml
```

公共网络中通常还会再切分成若干个子网，实际中不可能一个巨大的网段不分子网。在例子中假设vr一个子网，公共基础设施一个子网，彼此之间的路由节点就省略不画了。
公共设施子网里把虚拟机常用的东西放进去，包括dns，yum源，windows激活服务器等等，这些服务器对外暴露的都是公共设施子网的ip。
**对外暴露**的意思是，这些服务器也可能本身是挂载一个vr后面，并通过dnat挂载了公共网络的ip

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Boundary(shared, 公共网络, 10.64.0.0/10) {
    Boundary(vr子网, vr子网, 10.64.0.0/11) { 
        Container(port1, vr-1, 10.64.0.2)
        Container(port2, vr-2, 10.64.0.3)
        Container(port3, vr-3, 10.64.0.4)
    }
    Boundary(公共设施子网, 公共设施子网, 10.96.0.0/24) {
        Boundary(dns_net, dns网络, 10.0.0.0/8) {
            Container(10.0.0.1, 10.0.0.1)
            Container(dnslb, lb, 10.0.0.2) 
            Container(dns1, dns, 10.0.0.3) #red
            Container(dns2, dns, 10.0.0.4) #red
            10.0.0.1 <--> dnslb
            dnslb <--> dns1
            dnslb <--> dns2
        }
        10.64.0.5 <--> 10.0.0.1: dnat 10.0.0.2
        Container(yum, yum repo, 10.64.0.6) #red
        Container(apt, apt repo, 10.64.0.7) #red
        Container(windows_server, Windows激活服务器, 10.64.0.7) #red
    }
}
Boundary(vpc1, vpc-1) {
    System(router1, vr-1)
    router1 -d-> port1
}
Boundary(vpc2, vpc-2) {
    System(router2, vr-2)
    router2 -d-> port2
}
Boundary(vpc3, vpc-3) {
    System(router3, vr-3)
    router3 -d-> port3
}
@enduml
```

如图，dns可以部署在一个单独的二层广播域(比如一个云的vpc)，然后通过类似挂载浮动ip的方式将自己的服务暴露出来。
其它的也同理，相关的服务组件的集群部署在一个私有网络中，然后通过lb挂载浮动ip的形式对外暴露。
这样vpc内部首先先把dns给设置好，然后内部要被访问的服务的ip注册成dns的域名，随后将这些域名放到云主机的启动脚本或镜像内预置进去，云主机启动后就能和这些内部公共服务产生调用。



