# 准备宿主机镜像

## 升级操作系统内核

选用centos7.9版本，将内核升级为最新:

* `yum -y update`: 执行yum存储库更新
* `rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org`: 导入内核库pgp公钥
* `yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm` 把repo激活
* `yum list available --disablerepo='*' --enablerepo=elrepo-kernel` 看一下那些内核版本可用，lt代表长期支持的，不要装"ml"
  版本的，那些都是测试版本

**警告**: k8s在3.10版本上有bug，大集群会挂掉

![内核.png](内核.png)

* `yum --enablerepo=elrepo-kernel install kernel-lt` 安装lt版本
* `reboot` 重启
* `vim /etc/default/grub` 修改grub文件: 修改GRUB_DEFAULT=0，0是开
* `grub2-mkconfig -o /boot/grub2/grub.cfg`令其生效

## 修改时区和语言

* `timedatectl`: 查看时区，比如下面的就是错的，需要改

```text
[root@192 ~]# timedatectl
      Local time: Fri 2023-04-07 09:19:45 EDT
  Universal time: Fri 2023-04-07 13:19:45 UTC
        RTC time: Fri 2023-04-07 13:19:46
       Time zone: America/New_York (EDT, -0400)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: yes
 Last DST change: DST began at
                  Sun 2023-03-12 01:59:59 EST
                  Sun 2023-03-12 03:00:00 EDT
 Next DST change: DST ends (the clock jumps one hour backwards) at
                  Sun 2023-11-05 01:59:59 EDT
                  Sun 2023-11-05 01:00:00 EST
```

* `timedatectl set-timezone Asia/Shanghai`: 修改时区UTC+8

```text
[root@192 ~]# timedatectl
      Local time: Fri 2023-04-07 21:22:06 CST
  Universal time: Fri 2023-04-07 13:22:06 UTC
        RTC time: Fri 2023-04-07 13:22:07
       Time zone: Asia/Shanghai (CST, +0800)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
```

## 安装docker

* `yum install -y yum-utils`: 安装yum工具包
* `yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo`: 添加docker ce的源
* `yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`: 安装docker和官网推荐的全家桶，
  **不要**用`yum install docker`，那个装的是旧版本(如下)

```text
[root@192 ~]# docker -v
Docker version 1.13.1, build 7d71120/1.13.1
```

如果出错是这样

![报错.png](报错.png)

可能是之前装了docker没删干净，执行`yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine`
删干净

* `docker -v`

```text
[root@192 ~]# docker -v
Docker version 23.0.3, build 3e7cbfd
```

* `systemctl start docker`: 启动服务
* `docker run hello-world`: 测试一下

![docker-hello-world.png](docker-hello-world.png)

需要注意的是，docker可能要上网拉镜像