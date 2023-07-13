# 员工库

员工库是包含团队成员的数据库，它通常采用一种标准的技术建设(比如LDAP)。这个数据库为开发所需的诸如git、maven等提供统一的账号认证功能，避免不同的系统需要开通不同的账号。
通常这个员工库在公司内部已经存在，各个开发设施需要对接已有的员工库。
但部分情况下公司或者没有统一员工库，或者使用过程中不满足团队的需要，因此推荐使用windows server的AD域控服务作为员工库。

```plantuml
@startuml
!include  https://plantuml.s3.cn-north-1.jdcloud-oss.com/C4_Container.puml

System(AD, Active Directory, 域控服务器)

@enduml
```

