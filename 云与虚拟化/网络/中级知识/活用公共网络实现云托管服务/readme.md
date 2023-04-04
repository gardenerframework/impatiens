# 公共网络

在之前的文章中可以，为了支持vpc对等连接，所有路由其实都连入了一个以100.64.0.0/10作为cidr的公共网络，并可以通过snat让vpc内的所有机器都访问这个网络中的ip。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Boundary(shared, 公共网络, 100.64.0.0/10) {
    Container(port1, vr-1, 100.64.0.2)
    Container(port2, vr-2, 100.64.0.3)
    Container(port3, vr-3, 100.64.0.4)
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
Boundary(shared, 公共网络, 100.64.0.0/10) {
    Boundary(vr子网, vr子网, 100.64.0.0/11) { 
        Container(port1, vr-1, 100.64.0.2)
        Container(port2, vr-2, 100.64.0.3)
        Container(port3, vr-3, 100.64.0.4)
    }
    Boundary(公共设施子网, 公共设施子网, 100.96.0.0/24) {
        Container(dns, dns, 100.64.0.5) #red
        Container(yum, yum repo, 100.64.0.6) #red
        Container(apt, apt repo, 100.64.0.7) #red
        Container(windows_server, Windows激活服务器, 100.64.0.7) #red
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
Boundary(shared, 公共网络, 100.64.0.0/10) {
    Boundary(vr子网, vr子网, 100.64.0.0/11) { 
        Container(port1, vr-1, 100.64.0.2)
        Container(port2, vr-2, 100.64.0.3)
        Container(port3, vr-3, 100.64.0.4)
    }
    Boundary(公共设施子网, 公共设施子网, 100.96.0.0/24) {
        Boundary(dns_net, dns网络, 10.0.0.0/8) {
            Container(10.0.0.1, 10.0.0.1)
            Container(dnslb, lb, 10.0.0.2) 
            Container(dns1, dns, 10.0.0.3) #red
            Container(dns2, dns, 10.0.0.4) #red
            10.0.0.1 <--> dnslb
            dnslb <--> dns1
            dnslb <--> dns2
        }
        100.64.0.5 <--> 10.0.0.1: dnat 10.0.0.2
        Container(yum, yum repo, 100.64.0.6) #red
        Container(apt, apt repo, 100.64.0.7) #red
        Container(windows_server, Windows激活服务器, 100.64.0.7) #red
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

# 云托管服务与中间件

云可不止提供虚拟机，打开任何一个公有云的服务目录都能看到一堆内容。这些内容都是由云产研团队开发出来并提供给租户使用。
在此以一个简单的数据库服务为例。
假设数据库开发团队自己需要利用iaas团队提供的虚拟机，云硬盘和以及网络团队提供的lb和浮动ip能力，
这样听起来数据库开发团队不是从0开始造轮子(然而实际中是不是这么回事就仁者见仁了)，有助于产品的快速开发和上线

## 资源托管

既然要用云主机作为数据库的载体，数据库开发团队第一个面对的就是要不要将云主机建在用户的vpc内。总所周知，如果要在租户的vpc内创建云主机，那么就不得不面临几个问题

* 租户能不能看见这台云主机？能看到就意味着他能给这台云主机关机，重启，重置操作系统等，这肯定不是数据库开发团队想要的
* 给租户创建的云主机要不要占用租户的配额？配额的意思是租户在公有云上一共能建多少云主机。从租户的角度出发，他并没有打算去创建云主机。
  如果数据库的开发团队为了数据库的多活建了3台云主机，租户的配额就减少3，这个是不是合理
* 调用云主机一般要求租户付费，从接口调用往往直接扣代金劵，于是云主机首先会执行一次付费，于是云数据库的付费要怎么做？
* 同样的问题存在于云硬盘、lb等资源的配额和可见的问题

目前看起来至少在租户空间内去创建云资源不是个好主意

于是云数据库团队选择了一种类似下面的方案

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Boundary(shared, 公共网络, 100.64.0.0/10) {
    Boundary(vr子网, vr子网, 100.64.0.0/11) { 
        Container(port1, vr-1, 100.64.0.2)
        Container(port2, vr-2, 100.64.0.3)
        Container(port3, vr-3, 100.64.0.4)
    }
    Boundary(公共设施子网, 公共设施子网, 100.96.0.0/24) {
        Container(yum, yum repo, 100.64.0.6) #red
        Container(apt, apt repo, 100.64.0.7) #red
        Container(windows_server, Windows激活服务器, 100.64.0.7) #red
    }
    Boundary(数据库子网, 数据库子网, 100.97.0.0/24) {
        Container(100.97.0.2, 100.97.0.2)
    }
}
Boundary(云数据库vpc, 云数据库vpc, 10.0.0.0/16) {
    System(vrmysql, vr-mysql)
    Boundary(云数据库子网1, 云数据库子网, 10.0.0.0/24) {
        Container(10.0.0.2, 10.0.0.2, mysql主库)
        Container(10.0.0.3, 10.0.0.3, mysql从库)
        10.0.0.3 -l-> 10.0.0.2
    }
    100.97.0.2 <-u-> vrmysql: nat: 10.0.0.2
    10.0.0.2 <-u-> vrmysql
    10.0.0.3 <-u-> vrmysql
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

云数据库开发团队选择自己成为云的一个租户，然后和云iaas产研谈了一个不错的内部折扣用于自己云主机、硬盘以及网络资源的成本和一个较大的配额以及欠费不停机的特权后，开通了一个vpc。

这个vpc的作用就是承载租户的数据库，将所有准备用于数据库的云主机建在这个vpc内，从而使得使用方第一无法操作和登录这些云主机，也不会占用租户的云主机配额，
更重要的是不会造成租户的多次付费(云主机付费一次，云数据库又付费一次)。
同时，云数据库开发团队标4G卖2G，并巧妙的监控云主机的cpu使用率，发现2G快用满时再真的扩到4G(中间商赚差价)。

他们通过调用云的openApi在自己的网络中创建云主机，挂载云硬盘，存储自己的私有镜像，一切都是公有云已经提供好的，大幅提高了开发效率。
在云主机开发完毕后，他们选择为主库挂载一个浮动ip。不过这个浮动ip别的租户可使用不了，属于他们被云产研额外开通的浮动ip池子，区间是100.97.0.0/24。
也就是总而言之先给你253个，等你卖的火爆的不行了，云产研可以再分配一个新的ip段。毕竟一个新产品上线其实总是生死未知不是吗。
然后他们再调用dns服务的接口，向100网段的dns写入一个新的域名，比如"instance-001.internal.mysql.somecloud.com"。
为了保证正确的租户能访问到这个实例(假设vpc-1能够访问)，开发团队又调用了一些公有云的特权接口查询了vpc-1的浮动ip，在vr-mysql上写上acl

* accept 100.64.0.2
* drop all

最后这个内部域名显示在控制台上，租户复制黏贴并在自己的代码中使用

于是租户代码到云数据库的网络路径如下(代码所在主机 -> 100.97.0.2)

* 代码所在主机主机 -> vr1:

```json
{
  "src": "主机ip",
  "dst": "100.97.0.2"
}
```

* vr1 -> snat: ? -> 100.64.0.2

```json
{
  "src": "100.64.0.2",
  "dst": "100.97.0.2"
}
```

* vr1 -> 100.64.0.1(走默认网关)

```json
{
  "src": "100.64.0.2",
  "dst": "100.97.0.2"
}
```

* 100.64.0.1 -> 100.97.0.1(可能有多次路由)

```json
{
  "src": "100.64.0.2",
  "dst": "100.97.0.2"
}
```

* 100.97.0.1 -> 100.97.0.2(子网内直接转发)

```json
{
  "src": "100.64.0.2",
  "dst": "100.97.0.2"
}
```

* 100.97.0.2 -> dnat: 100.97.0.2 -> 10.0.0.2

```json
{
  "src": "100.64.0.2",
  "dst": "10.0.0.2"
}
```

当主库挂了的时候，云数据库的产研确保从库追平了主库后，执行fip挂载切换，将100.97.0.2挂到10.0.0.3上实现主从自动切换，租户的代码一行都不需要改造，同时域名也不需要重新注册，完美～

# 总结

公共网络的存在和所有连接到这个网络的路由器使得所有租户能够访问云厂商提供的一系列托管服务，也给云产研的非iaas开发团队提供了利用iaas资源同时又不干扰租户的能力；
当然，其它开发团队也可以采用自己习惯的开发模式，总之最终将对租户暴露的ip通过路由和地址映射搞到公共网络内即可。