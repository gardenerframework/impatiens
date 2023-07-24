# 综述

本文主要讲解开发团队所需的基本工具软件以及建设开发环境和测试环境的纲领

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

# 开发/测试环境

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(办公网, 办公网) {
    Person(测试, 测试)
}

Boundary(开发测试网络, 开发测试网络) {
    System(开发环境, 开发环境)
    System(测试环境, 测试环境)
}

测试 -d-> 开发环境
测试 -d-> 测试环境

@enduml
```

开发和测试环境原则上都需要从办公网能够直接访问，且根据统一规划，两个环境可以统一在同一个2层网络中。

## 开发的单元测试

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(办公网, 办公网) {
    Person(开发, 开发)
    System(本机代码, 本机代码)
}

Boundary(开发测试网络, 开发测试网络) {
    Boundary(开发环境, 开发环境) {
        Boundary(中间件, 中间件) {
            System(数据库, 数据库)
            System(缓存, 缓存)
        }
    }
}

开发 -d-> 本机代码
本机代码 -d-> 数据库
本机代码 -d-> 缓存

@enduml
```

开发在编写某个模块的代码时，通常会在自己的开发用主机上编写代码和运行，并要求链接数据库和缓存等中间件。
通常这些中间件和缓存或者由开发自己在自己的机器上安装，或者由开发环境的管理人员寻找资源予以分配。
在这时开发的单元测试在自己本机上进行。

待开发将代码通过流水线提交编译时，网络请求转为下图

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(办公网, 办公网) {
    Person(开发, 开发)
}

Boundary(开发测试网络, 开发测试网络) {
    System(jenkins, jenkins)
    Boundary(开发环境, 开发环境) {
        System(应用代码, 应用代码)
        Boundary(中间件, 中间件) {
            System(数据库, 数据库)
            System(缓存, 缓存)
        }
    }
}

开发 -d-> jenkins: 编译
jenkins -r-> 应用代码: 发布
应用代码 -d-> 数据库
应用代码 -d-> 缓存

@enduml
```

此时要求发布到开发环境的应用代码反向访问开发的个人主机是不现实的，因此应用代码只能访问位于开发环境内的中间件。
因此，本文<font color=red>推荐</font>从一开始就由开发环境的管理员为开发人员分配中间件。

## 测试环境

开发在编译和发布代码时往往只会考虑自己模块的测试，而不会考虑整个系统的测试。因此通常团队会有一个专门的环境用于等所有开发都发布代码后进行统一测试。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(办公网, 办公网) {
    Person(开发1, 开发) #red
    Person(开发2, 开发) #green
}

Boundary(开发测试网络, 开发测试网络) {
    System(jenkins, jenkins)
    Boundary(测试环境, 测试环境) {
        System(应用代码1, 应用代码) #red
        System(应用代码2, 应用代码) #green
        Boundary(中间件, 中间件) {
            System(数据库, 数据库)
            System(缓存, 缓存)
        }
    }
}

开发1 -d-> jenkins: 发布
开发2 -d-> jenkins: 发布
jenkins -d-> 应用代码1: 发布
jenkins -d-> 应用代码2: 发布
应用代码1 -d-> 数据库
应用代码1 -d-> 缓存

应用代码1 -r-> 应用代码2: 调用

应用代码2 -d-> 数据库

@enduml
```

在测试结束后，测试人员提交bug，开发人员上来查看bug和问题并尝试复现。
到此，开发人员和测试人员之间出现了资源争抢的状况，即测试人员需要等开发查看完左右问题并修复后再进行下一轮测试。
为了避免这种资源争抢问题，通常会建设多套测试环境

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(办公网, 办公网) {
    Person(测试, 测试) #red
    Person(开发, 开发) #green
}

Boundary(开发测试网络, 开发测试网络) {
    System(测试环境1, 测试环境1) #red
    System(测试环境2, 测试环境2) #green
}
测试 -d-> 测试环境1: 回归检查
开发 -d-> 测试环境2: 查看问题

@enduml
```

需要建设多少套测试环境视实际而定

# 建设落地

## 云化

从上文不难发现，开发所需的工具软件外加开发环境以及多套测试环境有待建设，这些环境的建设需要分配主机进行支撑。不过

* 这些环境的任意一项都无法将一套物理服务器用满(通常的物理服务器具有数十个cpu，数百的内存以及TB级别的硬盘)
* 环境之间的依赖组件可能发生冲突(例如安装中间件时，中间件的版本可能不一样)

因此，如果使用裸金属进行资源的承载，或者资源有较大程度的浪费，或者无法解决软件运行的冲突。因此应当采用云化的解决方案

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发测试网络, 开发测试网络) {
    Boundary(vm, vm)
    Boundary(k8s, k8s)
    Boundary(ceph, 云存储)
}

@enduml
```

在规划时，将开发测试网络内部的物理设备分为3个使用类型

* vm: 执行虚拟机虚拟化，这些虚拟机一般用来承载开发测试环境所需的工具软件，不承载具体的应用代码
* k8s: 执行容器虚拟化，它通常用来承载应用的代码以及所需的中间件
* 云存储: 执行存储虚拟化，它通常为vm和k8s的pod提供可靠的、多副本的存储，并且<font color=red>最好</font>
  能够提供诸如文件存储，对象存储等额外的存储能力。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发测试网络, 开发测试网络) {
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
    }
    
    Boundary(ceph, 分布式存储) {
        System(分布式存储网关, 云存储)
        harbor --> 分布式存储网关
        域控 --> 分布式存储网关
        git --> 分布式存储网关
        流水线 --> 分布式存储网关
        jfrog --> 分布式存储网关
        禅道 --> 分布式存储网关
    }
    
    应用代码1 --> 分布式存储网关
    应用代码2 --> 分布式存储网关
    中间件 --> 分布式存储网关
}

@enduml
```

此外，因为提供了统一的云存储，使得承载k8s的物理机的etcd能够直接使用云存储，进一步保障了k8s集群的稳定性

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
    System(分布式存储网关, 云存储)
    pod1 --> 分布式存储网关
    pod2 --> 分布式存储网关
    pod3 --> 分布式存储网关

}

@enduml
```

## 利用名称空间进行环境的隔离

在k8s内，可以通过名称空间(namespace)为开发环境以及多个测试环境进行隔离。管理员能够为名称空间分配资源配合并以及rbac限制用户的访问。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml


Boundary(k8s, k8s) {
    Boundary(dev, 产品-dev) {
        Container(pod1, pod, 开发)
    }
    Boundary(test_1, 产品-test-1) {
        Container(pod2, pod, 测试)
    }
    Boundary(test_2, 产品-test-2) {
        Container(pod3, pod, 测试)
    }
}

@enduml
```

## 保障观测性

首先，测试在运行的过程中出现的问题和bug不一定是代码的，需要建设可观测性的系统进行观测；
其次，可观测性是系统上线运行的必备条件，开发的代码必然要求对接线上的观测系统，因此测试可观测性同时也是测试的一环。
因此，在开发工具软件之外，还需要额外建设观测系统、日志收集系统和链路追踪系统，促使测试时就具有这些观测指标。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

Boundary(开发测试网络, 开发测试网络) {
    Boundary(容器云承载, 开发测试环境, 容器云承载) {
        System(应用代码1, 应用代码)
        System(应用代码2, 应用代码)
        System(中间件, 中间件)
    }
    
    Boundary(虚拟机承载, 开发基础设施工具软件, 虚拟机承载) {
        System(es, es+kibana, 日志收集) #red
        System(prometheus, prometheus, 监控) #red
        System(skywalking, skywalking, apm) #red
        System(域控, 域控服务器, 虚拟机)
        System(禅道, 禅道, 虚拟机)
        System(harbor, docker仓库, 虚拟机)
        System(git, git, 虚拟机)
        System(流水线, jenkins, 虚拟机)
        System(jfrog, jfrog, 虚拟机)
    }
    
    Boundary(ceph, 分布式存储) {
        System(分布式存储网关, 云存储)
        harbor --> 分布式存储网关
        域控 --> 分布式存储网关
        git --> 分布式存储网关
        流水线 --> 分布式存储网关
        jfrog --> 分布式存储网关
        禅道 --> 分布式存储网关
        es --> 分布式存储网关
        prometheus --> 分布式存储网关
        skywalking --> 分布式存储网关
    }
    
    应用代码1 --> 分布式存储网关
    应用代码2 --> 分布式存储网关
    中间件 --> 分布式存储网关
}

@enduml
```

在此，prometheus还可以进一步收集物理机的指标以及开发软件的虚拟机的指标。

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