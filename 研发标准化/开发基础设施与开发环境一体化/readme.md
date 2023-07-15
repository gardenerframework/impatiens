# 整合资源

使用K8S部署了研发基础设施后，整个开发环境相当于就完成了地基的建设，后续对业务线的资源支持可以通过不断地地将资源整合到开发基础设施的集群中。
就不再单独建设开发环境。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发设施, 开发设施) {
    System(master, k8s master, 主控节点)
    System(node1, k8s node, 工作节点)
    System(node2, k8s node, 工作节点)
    System(node3, ..., 工作节点)
    
    master <-- node1
    master <-- node2
    master <-- node3
}

@enduml
```

# 编程范例

在此给出一个开发人员常用的开发范例

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(办公网, 办公网) {
    System(个人pc, pc, 代码)
}

Boundary(开发设施, 开发设施) {
    Boundary(node2, k8s node, 工作节点) {
        Container(mysql, mysql, 数据库)
    }
    System(分布式存储, 分布式存储)
}

个人pc -r-> mysql
mysql -d-> 分布式存储

@enduml
```

在图中，开发人员在个人的pc上编写代码，编写完的代码自然需要数据库，缓存，消息队列等中间件。那么开发人员有以下选择

* 在自己的个人pc上安装对应的中间件，本地化使用
* 申请一个网络能访问的资源，通过办公网访问

两者中，本文推荐后者

# 开发资源申请的标准

在开发申请资源时，可以通过k8s的命令行工具或界面完成资源开通的子服务，其基本标准是

* 申请的资源不超过1C2G，除非在开发过程中需要执行海量数据或并发的测试
* 申请的资源应当自闭环，比如kafka自己包含zk
* 申请的资源挂载的磁盘大小不超过10GB，除非在开发过程中可能使用到海量数据

在保障机制上，应当对每一个团队的项目开设名称空间，并整体控制resource quota，从而实现资源使用的管控。
团队成员使用K8S的user、role等rbac对名称空间进行赋权。