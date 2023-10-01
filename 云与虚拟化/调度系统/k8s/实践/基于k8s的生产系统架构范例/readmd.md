# 开发测试环境标准化模型

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Boundary(开发网络, 开发网络) {
    System(git, git)
    System(maven, maven)
    System(jenkins, jenkins)
    System(dockerRepo, docker repo)
    System(k8s_master, k8s master节点, 裸金属/虚拟机 * 3) #red
    System(k8s_worker, k8s worker, 裸金属/虚拟机 * n) #green
    System(elk, elk, 日志系统) #orange
    System(prometheus, prometheus, 观测系统) #purple
    System(grafana, grafana, 观测系统ui) #purple
    k8s_worker -r-> elk: 日志
    git --> jenkins
    maven --> jenkins
    jenkins --> dockerRepo
    jenkins -r-> k8s_master
    dockerRepo -r-> k8s_worker: 镜像
    k8s_worker -u-> k8s_master
    prometheus -l-> k8s_master: 观测
    prometheus -d-> k8s_worker: 观测
    grafana -l-> prometheus
    Boundary(传统中间件, 传统中间件) {
        System(mysql, mysql, vm)
        System(redis, redis, vm)
    }
    Boundary(云存储服务, 云存储服务) {
        System(对象存储, 对象存储)
        System(文件存储, 文件存储)
    }
}
@enduml
```

* 在开发环境中，开发遵循在jenkins流水线上打包编译发布的流程，jenkins需要从git和maven获取代码以及依赖并将容器化制品推送到
  docker repo(通常为docker harbor)
* 发布成功后，jenkins调用k8s api(或直接通过kubectl 将yaml导入k8s集群)的方式要求k8s发布应用负载
  (Deployment + Service + Ingress rule)
* k8s worker受控于k8s master管理，k8s master基于控制器和调度策略将pod(docker容器)发布到k8s worker上运行
* 发布完成后测试基于k8s worker上混合部署的ingress执行web应用功能检查和验收
* 同时，为了保证日志能够被收集以防pod死亡后无法观测到错误信息，使用elk收集k8s日志并使用prometheus进行环境监测，查看集群和pod的运行状态以及负载
* k8s在兼容传统中间件时表现的并不好，因此中间件等设备依然使用vm或裸金属服务器处理
* 通常内部如果已有其它云服务设施，理应已经具备对象存储，文件存储等公共存储系统，这些存储系统通常可以通过云的api接口进行调用和挂载

# 生产环境环境标准化模型

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Person(互联网流量, 互联网流量)
Person(运维, 运维)
System(CDN, CDN)
互联网流量 <-r-> CDN
Boundary(生产网络, 生产网络) {
    System(F5负载, F5负载)
    Boundary(安全防护设施, 安全防护设施) {
        System(DDoS流量清洗, DDoS)
        System(入侵检测, 入侵检测)
        System(WAF, WAF)
        System(防火墙, 防火墙)
    }
    System(git, git)
    System(jenkins, jenkins)
    System(dockerRepo, docker repo)
    System(k8s_master, k8s master节点, 裸金属/虚拟机 * 3) #red
    System(etcd,etcd, 裸金属/虚拟机 * 3) #red
    System(k8s_ingress, k8s ingress, 裸金属/虚拟机 * n)
    System(k8s_worker, k8s worker, 裸金属/虚拟机 * n) #green
    System(elk, elk, 日志系统) #orange
    System(prometheus, prometheus, 观测系统) #purple
    System(grafana, grafana, 观测系统ui) #purple
    System(alertManager, Alert Manager, 告警系统) #purple
    k8s_worker -r-> elk: 日志
    dockerRepo -r-> k8s_worker: 镜像
    k8s_worker -u-> k8s_master
    prometheus -l-> k8s_master: 观测
    prometheus -d-> k8s_worker: 观测
    Boundary(传统中间件, 传统中间件) {
        System(mysql, mysql, vm)
        System(redis, redis, vm)
    }
    Boundary(云存储服务, 云存储服务) {
        System(对象存储, 对象存储)
        System(文件存储, 文件存储)
    }
    git --> jenkins: 配置文件
    jenkins --> k8s_master: 上线流水线
    互联网流量 --> F5负载
    CDN --> F5负载
    F5负载 --> k8s_ingress
    F5负载 --> 对象存储
    k8s_ingress --> k8s_master
    k8s_master -l-> etcd: 元数据存储
    prometheus -u-> k8s_ingress: 观测
    grafana -l-> prometheus 
    alertManager -u-> prometheus: 指标监测
    alertManager -r-> 运维: 故障告警
}
@enduml
```

* 生产环境和开发测试环境是隔绝网络，不能允许开发测试的主机通过任意层次网络协议直接访问生产系统的可能
* 应当不存在代码在生产环境中直接编译的情况, git在此是为了配置文件版本管理
* jenkins仅作为上线流水线使用，目标是操作时间和操作人员留痕
* docker repo为成品库，只能推送一次，不允许更新
* k8s master的etcd独立部署以防和master节点之间的混用
* k8s ingress流量控制器独立部署用于分离南北向业务流量和东西向pod流量
* k8s worker进行failure-domain标记，至少分离为所在机柜级别的故障域
* elk系统需要部署为集群模式
* prometheus需要alert-manager配置告警规则和告警渠道，若需要钉钉告警等可能要自研
* grafana是prometheus的可视化展示系统，可以和prometheus合并部署(同样适用于alert manager)

进行容器虚拟化 + k8s调度的好处:

1. 容器化部署将所有以来环境封装到镜像内，有利于处理物理机部署因多种组件包不兼容导致的故障或甚至操作系统崩溃
2. k8s多副本机制保证容器的副本数，当容器因故障死亡或节点硬件故障后，会在集群内部找一个可用节点迁移容器，始终做到副本数统一
3. 网络模型简单，易于理解
4. 目前容器开源调度控制器中较为成熟的系统，全世界最多人使用，代码开源，可基于未来想要深入使用的版本拉取代码自行优化和开发，可控性强
5. 开源生态较多，多数功能直接拉取镜像即可使用
6. 目前华为自身的CCE容器云 + 信创服务器证明了k8s集群具备arm cpu的可适配性，对未来信创国产化适配提供了技术信心

缺陷:

没有云管平台，第一个版本需要使用kubectl命令行操作，需要研发云管平台或先使用rancher等开源dashboard过度

# 重要数据的存储与备份

在生产环境的部署模型中，git、jenkins、etcd、docker repo、prometheus、elk都需要硬盘存储以下数据

* git: 历史配置文件
* jenkins: 流水线脚本
* etcd: k8s集群核心元数据
* docker repo: 生产镜像
* prometheus: 监控点位时序记录
* elk: 历史日志

为了保证这些数据存储的稳定性，理应对接远程存储服务器

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml
Boundary(生产网络, 生产网络) {
    System(git, git)
    System(jenkins, jenkins)
    System(dockerRepo, docker repo)
    System(elk, elk, 日志系统) #orange
    System(prometheus, prometheus, 观测系统) #purple
    System(块存储设备, 块存储设备) #red
    System(对象存储, 对象存储) 
    
    git -d-> 块存储设备
    jenkins -d-> 块存储设备
    dockerRepo -d-> 块存储设备
    elk -[dashed]d-> 块存储设备
    elk --> 对象存储: 执行快照
    prometheus -d-> 块存储设备
}
@enduml
```

其中elk由于是分布式存储，因此可以选择依靠自己本机的硬盘完成日志存储使命。
此外ELK应当对接对象存储，通过ES的备份api向对象存储建立备份存储，并推送备份。
其余硬盘数据取决于块存储的备份措施以及各自推荐的备份方法。
在生产设施网中，原则上对象存储、文件存储都应当具备。

**警告**: 不推荐k8s的pod通过StorageClass等进行磁盘挂载持久化存储数据，pod持久化存储的文件应当放到文件服务器上或对象存储上，持久化的关系数据应当写入数据库，pod更多承担的是应用的计算任务。