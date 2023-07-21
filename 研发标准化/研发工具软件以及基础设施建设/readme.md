# 开发所需的工具软件

## 员工库

员工库是包含团队成员的数据库，它通常采用一种标准的技术建设(比如LDAP)。这个数据库为开发所需的诸如git、maven等提供统一的账号认证功能，避免不同的系统需要开通不同的账号。
通常这个员工库在公司内部已经存在，各个开发设施需要对接已有的员工库。
但部分情况下公司或者没有统一员工库，或者使用过程中不满足团队的需要，因此推荐使用windows server的AD域控服务作为员工库。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发设施, 开发设施) {
    System(AD, Active Directory, 域控服务器)
}


@enduml
```

## 项目管理系统

项目管理系统用来记录和维护团队开发产品所需的需求、工作任务以及缺陷和问题。目前主流的开源免费系统是[禅道](https://www.zentao.net/)。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发设施, 开发设施) {
    System(AD, Active Directory, 域控服务器)
    System(zentoo, 禅道, 项目管理)
    
    zentoo -d-> AD
}


@enduml
```

## 代码管理系统

代码管理系统管理团队日常开发和维护的代码，开源免费的主流是[gitlab](https://about.gitlab.com/)。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发设施, 开发设施) {
    System(AD, Active Directory, 域控服务器)
    System(zentoo, 禅道, 项目管理)
    System(git, gitlab, 代码管理)
    
    zentoo -d-> AD: 员工账户认证
    git -d-> AD
    git -r-> zentoo: 代码提交后自动关联任务
}

@enduml
```

禅道目前可以配置git仓库的webhook，监听commit message中提及到的禅道需求、缺陷编号，实现git代码开发与任务的自动关联，下面引自禅道官方文档

```text
开发者在提交代码到git的时候，需要在备注里面注明此次修改相关的需求，或者任务，或者bug的id。比如下面的格式：
bug#123,234, 1234，也可以是bug:123,234 1234，id列表之间，用逗号和空格都可以。
story#123 task#123
bug, story, task是必须标注的
```

## 制品管理系统

团队开发过程中产生的中间组件(比如jar包)或者最终成品需要有一套系统来管理而不是直接存储在员工的个人计算机上。在以java开发、以容器运行的条件下，
主要是用[jfrog](https://jfrog.com/)和[docker harbor](https://goharbor.io/)。
jfrog主要管理非发布制品(snapshot版本)和发布制品(非snapshot版本)。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发设施, 开发设施) {
    System(AD, Active Directory, 域控服务器)
    System(zentoo, 禅道, 项目管理)
    System(git, gitlab, 代码管理)
    System(jfrog, jfrog, jar包管理)
    System(harbor, docker harbor, 容器镜像管理)
    
    zentoo -d-> AD: 员工账户认证
    git -d-> AD
    jfrog -d-> AD
    harbor -d-> AD
    
    git -r-> zentoo: 代码提交后自动关联任务
}

@enduml
```

## 流水线

流水线用于将团队开发的代码自动化地进行单元测试后发布到制品管理系统。目前流行的开源流水线是[jenkins](https://www.jenkins.io/)。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发设施, 开发设施) {
    System(AD, Active Directory, 域控服务器)
    System(zentoo, 禅道, 项目管理)
    System(git, gitlab, 代码管理)
    System(jfrog, jfrog, jar包管理)
    System(harbor, docker harbor, 容器镜像管理)
    System(jenkins, jenkins, 流水线)
    System(utest, 单元测试环境, 所需中间件等)
    
    zentoo -d-> AD: 员工账户认证
    git -d-> AD
    jfrog -d-> AD
    harbor -d-> AD
    jenkins -d-> AD
    
    git -r-> zentoo: 代码提交后自动关联任务
    
    jenkins -d-> git: 代码拉取
    jenkins -d-> jfrog: 制品推送 
    jenkins -d-> utest: 单元测试
    jenkins -d-> harbor: 制品推送
    
}

@enduml
```

# 建设落地

## 云化

研发的基础设施以及开发测试环境<font color=red>不推荐</font>直接安装在物理设备上，而是应当有一套云化的调度系统。
通过虚拟机或容器来承载基础设施的工具软件，通过远程的、分布式的存储来承载开发过程资产(比如代码、日常任务等)

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(2层网络边界, 2层网络边界) {
    Boundary(物理机1, 物理机) {
        System(git, git, 虚拟机)
        System(jenkins, jenkins, 虚拟机)
        System(k8s1, k8s node, 虚拟机)
    } 
    Boundary(物理机2, 物理机) {
        System(jfrog, jfrog, 虚拟机)
        System(ad, 域控, 虚拟机)
        System(k8s2, k8s node, 虚拟机)
    }
    Boundary(物理机3, 物理机) {
        System(jfrog2, ..., 虚拟机)
        System(ad2, ..., 虚拟机)
        System(k8s3, ..., 虚拟机)
    }
    Boundary(ceph, 分布式存储) {
        System(ceph1, 分布式存储节点, 物理机)
        System(ceph2, 分布式存储节点, 物理机)
        System(ceph3, 分布式存储节点, 物理机)
    }
}

@enduml
```

物理设备主要做2件事

* 作为虚拟机承载开发工具软件或者k8s工作节点
* 作为分布式存储的磁盘服务器使用

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(2层网络边界, 2层网络边界) {
    Boundary(容器云承载, 开发测试环境, 容器云承载) {
        System(应用代码1, 应用代码)
        System(应用代码2, 应用代码)
        System(中间件, 中间件)
    }
    
    Boundary(虚拟机承载, 开发基础设施工具软件, 虚拟机承载) {
        System(域控, 域控服务器, 虚拟机)
        System(禅道, 禅道, 虚拟机)
        System(harbor, docker仓库, 虚拟机)
        System(git, git, 虚拟机)
        System(流水线, jenkins, 虚拟机)
        System(jfrog, jfrog, 虚拟机)
        System(prometheus, prometheus, 虚拟机)
    }
    
    Boundary(ceph, 分布式存储) {
        System(分布式存储网关, 分布式存储网关)
        harbor --> 分布式存储网关
        域控 --> 分布式存储网关
        git --> 分布式存储网关
        流水线 --> 分布式存储网关
        jfrog --> 分布式存储网关
        prometheus --> 分布式存储网关
        禅道 --> 分布式存储网关
    }
    
    应用代码1 --> 分布式存储网关
    应用代码2 --> 分布式存储网关
    中间件 --> 分布式存储网关
}

@enduml
```

* 整个开发环境分为2个区，虚拟机来承载开发基础设施中工具软件，k8s来承载开发发布的应用代码和开通所需的中间件
* 在数据存储上，需要将K8S的pod以及虚拟机的底层数据磁盘对接到分布式的网络存储设施，这类设施通过多副本等机制保证
* 此外，etcd的数据可以直接存储在分布式存储中进行天然的多副本备份

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml


Boundary(bm1, 服务器) {
    Container(pod1, etcd, nfs)
}

Boundary(bm2, 服务器) {
    Container(pod2, etcd, nfs)
}

Boundary(bm3, 服务器) {
    Container(pod3, etcd, nfs)
}

Boundary(ceph, 分布式存储) {
    System(分布式存储网关, 分布式存储网关)
    pod1 --> 分布式存储网关
    pod2 --> 分布式存储网关
    pod3 --> 分布式存储网关

}

@enduml
```

## 重要数据的定期备份

常见的存储系统现在都支持数据快照的能力，通过定期的数据快照可以创建数据的回滚点和备份点。因此，对接到分布式存储的pod的数据，比如git的代码和元数据等可以通过这个机制实现定期的自动备份

除此之外，依然需要针对git代码执行定期全量备份，其方法是

* 在git的低峰时段对git目录创建压缩包
* 将压缩包拷贝到分布式存储的另一块独立存储位置

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(git, git) {
    System(定期备份程序, 定期备份程序)
}

Boundary(ceph, 分布式存储) {
    System(代码目录, 代码目录, 块存储)
    System(备份目录, 备份目录, 块存储)
}
    
定期备份程序 <-- 代码目录
定期备份程序 --> 备份目录

@enduml
```

## 管理面统一账户集成

在上文中基本要求了各个组件向员工库的集成，原则上K8S的管理界面，分布式存储的管理界面等，均需尽可能对接到员工库

# 开发资源申请的标准

在开发申请资源时，可以通过k8s的命令行工具或界面完成资源开通的子服务，其基本标准是

* 申请的资源不超过1C2G，除非在开发过程中需要执行海量数据或并发的测试
* 申请的资源应当自闭环，比如kafka的镜像中自己包含zk
* 申请的资源挂载的磁盘大小不超过10GB，除非在开发过程中可能使用到海量数据

在保障机制上，应当对每一个团队的项目开设名称空间，并整体控制resource quota，从而实现资源使用的管控。
团队成员使用K8S的user、role等rbac对名称空间进行赋权。

# 进一步阅读

[使用scrum执行研发基本流程](..%2F%E4%BD%BF%E7%94%A8scrum%E6%89%A7%E8%A1%8C%E7%A0%94%E5%8F%91%E5%9F%BA%E6%9C%AC%E6%B5%81%E7%A8%8B)