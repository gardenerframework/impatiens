# 员工库

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

# 项目管理系统

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

# 代码管理系统

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

