---
title: "Ad Hoc Commands"
menuTitle: "Ad Hoc Commands"
date:  2020-02-06T13:21:42+09:00
weight: 4
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

지난 챕터에서는 `Vagrant`와 간단한 `Ansible playbook`으로 local infrastructure를 테스트해보았다.
이번에는 간단한 `Ansible` ad-hoc command를 사용하여 하나의 명령어로 다수의 remote server에 명령을 보낼 것이다.

나중 챕터에서는 playbook에 대해 자세히 알아볼 것이지만, 지금은 어떻게 `Ansible`이 하나 이상의 서버에 대해 ad-hoc command로 빠르게 공통적인 일을 수행하는지, 데이터를 가져오는지에 대해 알아볼 것이다.

## Conducting an orchestra

각 개인 administrator가 관리하는 서버의 수는 수년간 급격하게 증가했다.
특히 virtualization과 cloud application의 발전은 표준처럼 되었다.

어느 때든 system administrator는 여러가지 업무가 있다.

* patch 적용과 `yum`, `apt`, 다른 package manager를 통한 update
* resource usage 확인 (disk space, memory, CPU, swap space, network)
* log file 확인
* system user와 group 관리
* DNS 설정, hosts 파일 관리 등
* 서버에 파일 업로드/다운로드
* application 배포하기 또는 application 유지
* server 재부팅
* cron jobs 관리

최근에는 이런 작업들이 조금이나마 자동화 되어있다.
하지만 실시간 진단같은 문제에는 사람의 손길이 필요하긴 하다.
또한 multi-server 환경은 복잡하여 각 server에 접속하는 것은 좋은 솔루션이 아니다.

`Ansible`은 admin이 ad-hoc command로 `ansible` 명령어를 사용하여 수백개의 서버에 동시에 명령을 전달할 수 있다.
챕터 1에서는 `Ansible` inventory file에 기록된 서버에 두개의 command를 실행했다.
이 챕터에서는 ad-hoc command와 multi-server 환경을 자세히 볼 것이다.
다른 `Ansible`의 강력한 기능들은 제쳐두고라도 이 챕터를 읽으면 더 효과적으로 server들을 관리할 수 있다.

## Build infrastructure with Vagrant for testing

우리의 production server에 영향을 주지 않고 설명을 하기 위해 이 챕터의 나머지 부분에서는 `Vagrant`의 multi-machine capabilites를 사용하여 몇개의 server들을 설정해볼 것이다.
이것들은 `Ansible`을 통해 관리될 것이다.

먼저 `Vagrant`에서 CentOS 7을 실행시키는 하나의 virtual machine을 사용할 것이다.
이 예시에서 우리는 `Vagrantfile`에 정의된 `Vagrant`의 기본 설정들을 사용할 것이다.
이 예시에서 우리는 `Vagratn`의 강력한 multi-machine management feature를 사용할 것이다.

![multi-machine management](/images/Ansible/multi-machine-management)

우린 3개의 VM을 생성할 것이다.
(두개의 app server, 하나의 database server)
이정도면 `Ansible`의 server management 능력을 확인해볼 수 있을 것이다.

local drive에 새로운 폴더를 생성하고 `Vagrantfile`을 생성한다.
이를 editor로 연 뒤 다음과 같이 입력한다.

```Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "256"]
  end

  # Application server 1.
  config.vm.define "app1" do |app|
    app.vm.hostname = "orc-app1.dev"
    app.vm.box = "geerlingguy/centos7"
    app.vm.network :private_network, ip: "192.168.60.4"
  end
  # Application server 2.
  config.vm.define "app2" do |app|
    app.vm.hostname = "orc-app2.dev"
    app.vm.box = "geerlingguy/centos7"
    app.vm.network :private_network, ip: "192.168.60.5"
  end

  # Database server.
  config.vm.define "db" do |db|
    db.vm.hostname = "orc-db.dev"
    db.vm.box = "geerlingguy/centos7"
    db.vm.network :private_network, ip: "192.168.60.6"
  end
end
```

이 `Vagrantfile`은 세 server를 정의하고 각각 고유한 hostname, machine name, IP 주소를 부여한 것이다.
간단하게 하기 위해 셋 모두 CentOS 7을 사용한다.

터미널을 열고 `Vagrantfile`이 있는 폴더로 이동한다.
그 다음 `vagrant up`을 이용하여 세개의 VM을 생성한다.
이미 챕터 2에서 box를 다운로드 받았다면 5~10 내로 생성될 것이다.

진행되는 동안 서버에 대한 `Ansible`을 설명하도록 하겠다.

### Inventory file for multiple servers

관리하는 서버를 다루는 `Ansible`에 대해 이야기 할 것들이 많다.
하지만 대부분의 경우 서버를 시스템의 main Ansible inventory file(보통 `/etc/ansible/hosts`)에 추가하면 된다.
지난 챕터에서 파일을 생성하지 않았다면 돌아가서 파일을 생성해야한다.
또한 user가 해당 파일에 대해 read 권한이 있어야 한다.

다음을 파일에 추가한다.

```ansible-hosts
# Lines beginning with a # are comments, and are only included for
# illustration. These comments are overkill for most inventory files.

# Application servers
[app]
192.168.60.4
192.168.60.5

# Database server
[db]
192.168.60.6

# Group 'multi' with all servers
[multi:children]
app
db

# Variables that will be applied to all servers
[multi:vars]
ansible_ssh_user=vagrant
ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
```

1. 첫 번째 block은 우리의 application server들을 `app` group에 추가한다.
2. 두 번째 block은 database server를 `db` group에 추가한다.
3. 세 번째 block은 `Ansible`이 새 그룹 `multi`를 생성하고, child group으로 `app`과 `db`를 추가한 것이다.
4. 네 번째 block은 `multi` group에 variables를 추가한 것이다. 이는 `multi` group과 그 내부의 모든 children 서버에 적용된다.

{{% notice note %}}

나중 챕터에서 variables, group definition, group hiearchy, Inventory file topics에 대해 알아볼 것이다.
여기서는 어떻게 `Ansible`이 간단히 서버 정보를 다루는지 확인하고 빠르게 이를 이용할 것이다.

{{% /notice %}}

inventory file을 저장하고 `Vagrant`가 세개의 VM들을 성공적으로 build 하였는지 확인한다.
`Vagrant`가 성공하고 나면 이들을 `Ansible`에서 관리할 것이다.

## Your first ad-hoc commands

가장 먼저 해야할 것은 서버 안에서 체크할 것이다.
제대로 설정이 되었는지 확인하고, 올바른 날짜 및 시간이 설정 되었는지(우린 time synchronization과 관련된 에러를 경험하고 싶지 않다!), 어플리케이션을 실행하기에 충분한 리소스가 있는지 확인해 보자.

{{% notice note %}}

여기서 확인하는 것들은 production server에서 자동화 시스템으로 모니터링되어야 하는 것들이다.
재앙을 막는 가장 좋은 방법은 언제 올지 알고, 발생하기 전에 어떻게 문제점을 해결하는 것을 아는 것이다.
`Munin`, `Nagios`, `Cacti`, `Hyperic`과 같은 툴을 사용하여 서버에서의 과거와 현재의 리소스 사용량을 확인할 수 있다.
인터넷에서 웹사이트나 웹 어플리케이션을 돌리고 있다면 `Pingdom`이나 `Server Check in` 같은 외부 모니터링 솔루션이 필요하다.

{{% /notice %}}

### Discover Ansible's parallel nature

먼저, `Vagrant`가 설정한 VM들이 올바른 hostname을 가지고 있는지 확인할 것이다.
`Ansible`에서 `-a` argument를 "hostname"으로 줘서 모든 서버에 대해 hostname을 실행한다.

```bash
$ ansible multi -a "hostname"
```

`Ansible`은 이 명령어를 세 서버 모두에 대해 실행하고, 결과를 리턴받는다.
(만일 `Ansible`이 하나의 서버에 도달하지 못할 경우 이는 해당 서버에 대해 error를 출력하지만 나머지 서버에 대해서는 계속해서 명령어를 수행한다.)

{{% notice note %}}

`Ansible`이 `No hosts matched`나 다른 inventory 관련 에러를 리턴하면 `ANSIBLE_HOSTS` 환경 변수를 설정해보아라.
`export ANSIBLE_HOSTS=/etc/ansible/hosts`를 하면 된다.
일반적으로 Ansible은 `/etc/ansible/hosts` 파일을 자동으로 읽지만 어떻게 Ansible을 설치했는지에 따라 명시적으로 `ANSIBLE_HOSTS`을 설정해야 할수도 있다.

{{% /notice %}}

명령어들이 각 서버에 대해서 예상했던 순서대로 실행되는 것은 아님을 확인할 수 있다.
명령어를 몇번 더 입력하여 순서를 확인해보자.

![ansible-multi-command](/images/Ansible/Ansible-for-DevOps/ansible-multi-command.png)

기본적으로 `Ansible`은 명령어를 process fork를 이용해서 병렬적으로 실행한다.
따라서 명령어는 좀 더 빨리 완료될 수 있다.
몇개의 서버만 관리한다면 하나씩 실행하는 것에 비해 속도 체감이 별로 안들지만 5-10개의 서버만 관리한다고 하더라도 `Ansible`의 parallelism(기본적으로 활성화되어있다)을 이용하면 엄청난 속도 절감 효과가 있을 것이다.

fork를 하나만 한다는 것을 의미하는 `-f 1` argument를 이용해서 동일한 명령어를 다시 입력해보자.
(일반적으로 각 서버에 대해 순서대로 실행할 때 쓴다)

![ansible-multi-command-serially](/images/Ansible/Ansible-for-DevOps/ansible-multi-command-serially.png)

동일한 명령어를 계속 반복해도 항상 같은 순서대로 결과가 나올 것이다.
이걸 사용할 일은 거의 없겠지만 값을 늘리는 일은 그래도 더 많을 것이다.
(`-f 10`이나 `-f 25`처럼 시스템과 네트워크 연결이 얼마나 감당 가능한지에 따라 수정할 수 있다)
이를 통해 수십 수백개의 서버에 대한 명령어 실행을 빠르게 할 수 있다.

{{% notice note %}}

대부분의 사람들은 action의 target을 command/action 자체보다 더 앞에 배치한다.
("X 서버에서, Y 명령어를 실행해라")
하지만 머랫속에서 반대로 작동한다면
("Y 명령러를 실행해라. X 서버에서.")
target을 arguments 다음에 배치할 수도 있다.
(`ansible -a "hostname" multi`)
이 둘은 완전히 일치하는 것이다.

{{% /notice %}}

## Learning about your environment

이제 우리는 `Vagrant`가 정상적으로 hostname을 설정한 것을 확인했다.
이제 다른것들을 확인해 보도록 하자.

먼저, application을 위한 hard disk space가 충분한지 확인해보자.

```bash
$ ansible multi -a "df -h"
192.168.60.6 | success | rc=0 >>
Filesystem Size Used Avail Use% Mounted on
/dev/mapper/centos-root 19G 1014M 18G 6% /
devtmpfs 111M 0 111M 0% /dev
tmpfs 120M 0 120M 0% /dev/shm
tmpfs 120M 4.3M 115M 4% /run
tmpfs 120M 0 120M 0% /sys/fs/cgroup
/dev/sda1 497M 124M 374M 25% /boot
none 233G 217G 17G 94% /vagrant

192.168.60.5 | success | rc=0 >>
Filesystem Size Used Avail Use% Mounted on
/dev/mapper/centos-root 19G 1014M 18G 6% /
devtmpfs 111M 0 111M 0% /dev
tmpfs 120M 0 120M 0% /dev/shm
tmpfs 120M 4.3M 115M 4% /run
tmpfs 120M 0 120M 0% /sys/fs/cgroup
/dev/sda1 497M 124M 374M 25% /boot
none 233G 217G 17G 94% /vagrant

192.168.60.4 | success | rc=0 >>
Filesystem Size Used Avail Use% Mounted on
/dev/mapper/centos-root 19G 1014M 18G 6% /
devtmpfs 111M 0 111M 0% /dev
tmpfs 120M 0 120M 0% /dev/shm
tmpfs 120M 4.3M 115M 4% /run
tmpfs 120M 0 120M 0% /sys/fs/cgroup
/dev/sda1 497M 124M 374M 25% /boot
none 233G 217G 17G 94% /vagrant
```

현재 충분한 만큼의 공간이 있는 것처럼 보인다.
우리의 application은 가벼운 편이다.

두번째로 서버에 메모리가 충분한지 확인한다.

```bash
$ ansible multi -a "free -m"
192.168.60.4 | success | rc=0 >>
total used free shared buffers cached
Mem: 238 187 50 4 1 69
-/+ buffers/cache: 116 121
Swap: 1055 0 1055

192.168.60.6 | success | rc=0 >>
total used free shared buffers cached
Mem: 238 190 47 4 1 72
-/+ buffers/cache: 116 121
Swap: 1055 0 1055

192.168.60.5 | success | rc=0 >>
total used free shared buffers cached
Mem: 238 186 52 4 1 67
-/+ buffers/cache: 116 121
Swap: 1055 0 1055
```

메모리는 약간 타이트하다.
하지만 우리는 localhost에 3개의 VM을 돌리고 있음을 감안해야한다.

세 번째로 날짜 및 시간이 잘 맞춰졌는지 확인한다.

```bash
$ ansible multi -a "date"
192.168.60.5 | success | rc=0 >>
Sat Feb 1 20:23:08 UTC 2021

192.168.60.4 | success | rc=0 >>
Sat Feb 1 20:23:08 UTC 2021

192.168.60.6 | success | rc=0 >>
Sat Feb 1 20:23:08 UTC 2021
```

대부분의 어플리케이션은 각 서버의 시간 jitter에 약간은 견딜 수 있게 설계되어있지만 다른 서버들의 시간들을 가능한 가깝게 하는 것은 좋은 방법이고 이를 간단하게 할 수 있는것은 설정하는 것이 쉬운 Network Time Protocol을 사용하는 것이다.
나중에 이를 `Ansible`의 modules를 이용하여 힘쓰지 않고 프로세스를 진행해 볼 것이다.

{{% notice note %}}

특정 서버에 대해서 모든 환경적인 자세한 부분(`Ansible`의 lingo에서는 `facts`라고 한다)을 확인하고 싶으면 `ansible [host-or-group] -m setup`을 입력하면 된다.
이는 매 분마다 서버에 대한 자세한 사항들을 보여준다.
(file system, memory, OS, network interface 등이 포함된다)

{{% /notice %}}

## Make changes using Ansible modules

우리는 NTP daemon을 서버에 설치하여 시간을 동기화할 것이다.
`yum install -y ntp` 명령어를 각 서버에서 실행하는 대신 ansible의 `yum` module을 이용해서 같은것을 해볼 것이다.
(우리가 앞선 playbook 예제에서 했던 것과 같지만 이번에는 ad-hoc command를 사용할 것이다.)

```bash
$ ansible multi -b -m yum -a "name=ntp state=installed"
```

NTP가 이미 설치되어있기 때문에 세개의 "success" 메시지를 볼 수 있을 것이다.
이는 모든 작업이 순서대로 잘 되었음을 의미한다.

{{% notice note %}}

`-b` 옵션은 `Ansible`이 sudo 권한으로 명령어를 실행할 수 있게 한다.
이는 우리의 `Vagrant` VM에서는 잘 작동하지만 sudo password를 요구로 하는 서버에 대해서는 `-k` 옵션도 지정하여 `Ansible`이 필요로 하는 sudo password를 입력해야한다.

{{% /notice %}}

이제 NTP daemon이 시작되었는지 확인하고 부팅 시 시작되도록 할 것이다.
우리는 `service ntpd start` 와 `chkconfig ntpd on` 두 명령어를 사용하기 보단 `Ansible`의 `service` module을 사용할 것이다.

```bash
$ ansible multi -b -m service -a "name=ntpd state=started enabled=yes"
```

모든 서버에서 다음과 같은 메시지를 출력할 것이다.

```
"changed": true,
"enabled": true,
"name": "ntpd",
"state": "started"
```

동일한 명령어를 다시 쳐도 `Ansible`이 nothing has changed라고 리포트하는 것 빼곤 모든 결과는 같을 것이고 이 경우 `changed` 값은 `false`가 될 것 이다.

`Ansible`의 module을 일반 shell command 대신 사용할 경우 `Ansible`이 제공하는 상화와 idempotency를 이용할 수 있다.
shell command를 실행시키더라도 이를 `Ansible`의 `shell`이나 `command` module로 감싸줘야 하지만(`ansible -m shell -a "date" multi`처럼), ad-hoc으로 실행하는 것들은 `Ansible` module을 사용할 필요는 없다.

마지막으로 체크해야하는 사항은 NTP server의 official time과 거의 일치하는지 확인하는 것이다.

```bash
$ ansible multi -b -a "service ntpd stop"
$ ansible multi -b -a "ntpdate -q 0.rhel.pool.ntp.org"
$ ansible multi -b -a "service ntpd start"
```

`ntpdate` 명령어를 실행하려면 `ntpd` service가 중지되어야 하기 때문에 service를 중지했고 명령어를 실행한 뒤 다시 서비스를 시작했다.

나의 테스트에서 모든 세 서버에서 3/100초 내에 차이를 보여줬다.
내 목적에는 충분한 것이었다.

## Configure groups of servers, or individual servers

우리의 가상 웹 어플리케이션은 Django를 사용할 것이며 따라서 우리는  Django와 그 dependency들을 설치해야한다.
Django는 official CentOS yum repository에 없지만 우리는 Python의 easy_install을 통해서 설치할 것이다.
(편리한 Ansible module이 있다.)

```bash
$ ansible app -b -m yum -a "name=MySQL-python state=present"
$ ansible app -b -m yum -a "name=python3-setuptools state=present"
$ ansible app -m pip -a "name=django executable=pip3"
```

우리는 `easy_install`을 통해 설치한 django를 `pip`를 통해서도 설치할 수 있다.
(`Ansible`의 `easy_install` module은 `pip`처럼 uninstall을 지원하 지않기 때문에 사용한다)
하지만 간단하게 하기 위해 `easy_install`을 사용하였다.

Django가 설치 되었고 제대로 동작하는지 확인해보자.

```bash
$ ansible app -a "python3 -c 'import django; print (django.get_version())'"

192.168.60.5 | CHANGED | rc=0 >>
3.0.3

192.168.60.4 | CHANGED | rc=0 >>
3.0.3
```

우리의 앱 서버가 정상적으로 동작하는 것처럼 보인다.
이제 우리는 database server에 대해 해볼 것이다.

{{% notice note %}}

이 챕터에서 한 대부분의 설정은 Ansible playbook으로 하는 것이 더 좋다.
(이 책의 뒷부분에서 더 자세히 다뤄볼 것이다.)
이 챕터는 `Ansible`을 통해 얼마나 쉽게 여러 서버를 관리할 수 있는지에 대해서 좀 더 집중할 것이다.
서버를 shell command를 통해 설정했다고 하더라도 `Ansible`은 굉장히 많은 시간을 줄여줄 수 있고 더 안전하고 효과적인 방법으로 모든 것들을 처리해줄 수 있다.

{{% /notice %}}

### Configure the Database servers

우리는 어플리케이션 서버를 `Ansible`의 main inventory에서 `app` group으로 정의하여 사용하였고 database server를 이와 비슷하게 `db` group으로 정의하여 설정할 것이다.

MariaDB를 설치하고 이를 실행시키고 서버의 방화벽에서 MariaDB의 deafult port인 3306을 허용시키자.

```bash
$ ansible db -b -m yum -a "name=mariadb-server state=present"
$ ansible db -b -m service -a "name=mariadb state=started enabled=yes"
$ ansible db -b -a "iptables -F"
$ ansible db -b -a "iptables -A INPUT -s 192.168.60.0/24 -p tcp -m tcp --dport 3306 -j ACCEPT"
```

여기서 app server에서 database를 연결하려고 시도할 경우 연결이 불가능하지만, 연결할 필요가 없다.
왜냐면 MariaDB를 계속해서 셋업해야하기 때문이다.
전형적으로 이를 서버에 접속하여 `mysql_secure_installation`을 통해 한다.
그러나 운좋게도 `Ansible`은 MariaDB server를 `mysql_*` module로 제어할 수 있다.
이제 app server에서 MySQL로 접속할 수 있게 허용할 것이다.
MySQL module은 `MySQL-python` module이 managed server에 설치되어있어야 한다.

{{% notice note %}}

왜 MySQL이 아닌 MariaDB인가?
RHEL 7과 CentOS 7는 MariaDB를 default supported MySQL-compatible database server로 지원한다.
MariaDB와 관련된 몇몇 툴들은 `MySQL*` 네이밍 규칙을 가진 예전 것들을 사용하며 MySQL로 하더라도 MariaDB를 하는것과 비슷할 것이다.

{{% /notice %}}

```bash
$ ansible db -b -m yum -a "name=MySQL-python state=present"
$ ansible db -b -m mysql_user -a "name=django host=% password=12345 priv=*.*:ALL state=present"
```
여기서 Django application을 app server에 생성하거나 배포할 수 있어야 한다.
그 뒤 database server에 username=django, password=12345로 접속할 수 있을 것이다.

{{% notice note %}}

여기서 사용한 MySQL configuration은  예시/개발 목적으로만 사용해야 한다.
MySQL의 안전하게 하려면 test database의 삭제와 root user account에 password를 추가하고, 3306 port로 접근하는 IP address들을 제한하는 등 몇가지 더 할 일들이 있다.
이 중 몇몇은 이 책의 뒷부분에서 다루도록 하겠지만, 당신의 서버를 보호하는 것은 당신의 책임이다.
제대로 보호했는지 확실히 하라.

{{% /notice %}}

### Make changes to just one server

축하한다! 이제 Django와 MySQL을 실행시킬 작은 웹 어플리케이션 환경을 가지게 되었다.
앱 서버 앞단에 요청을 분배시켜줄 로드밸런서도 없어 충분하지는 않다.
하지만 서버에 접속하지 않고도 빠르게 이것들을 설정할 것이다.
더 인상깊은 점은 어느 ansible command도 다시 실행할 수 있고, 이것이 어떤 차이점도 만들지 않는다는 것이다.
이런 것들은 `"changed": false`를 리턴할 것이고 기존의 설정이 변경되지 않았음을 알려준다.

이제 local infrastructure가 동작하는 동안 로그를 보다보면 두 앱 서버중 하나의 시간이 NTP daemon이 충돌나거나 어떤 이유로 멈췄을 경우 다른 서버와 일치하지 않을 수 있다.
빠르게 다음의 명령어를 통해 ntpd의 상태를 체크해보자.

```bash
$ ansible app -b -a "service ntpd status"
```

그리고 app server의 서비스들을 재시작한다.

```bash
$ ansible app -b -a "service ntpd restart" --limit "192.168.60.4"
```

이 명령어에서 `--limit` argument는 명령어를 지정된 그룹 내에서 특정한 호스트에서만 실행하도록 제한하는 것이다.
`--limit`은 정확한 string 또는 regular expression을 쓸 수 있다.
(`~`를 prefix로 쓰면 된다)
위의 명령어는 `.4` 서버에서만 실행하고 싶다면 더 간단히 할 수 있다.
(`.4`로 끝나는 IP 주소가 하나만 있다고 확신해야 한다)
다음의 명령어는 정확히 같은 동작을 한다.

```bash
# Limit hosts with a simple pattern (asterisk is a wildcard).
$ ansible app -b -a "service ntpd restart" --limit "*.4"
# Limit hosts with a regular expression (prefix with a tilde).
$ ansible app -b -a "service ntpd restart" --limit ~".*\.4"
```

이 예시에서 우리는 IP 주소를 hostname 대신에 사용하였다.
하지만 많은 실제 시나리오에서는 `nyc-dev-1.example.com`처럼 hostname을 많이 사용하게 된다.
따라서 정규식을 활용하는 것이 더 유용할 것이다.

{{% notice note %}}

하나의 서버에 대해 명령어를 실행할때만 `--limit` 옵션을 주어라.
동일한 세트의 서버에 `--limit` 명령어를 자주 사용하게 된다면 이들을 inventory file에서 group으로 묶는 것을 고려해 보아라.
그 방법이 `ansible [my-new-group-name] [command]`를 사용할 수 있는 방법이고 타이핑을 줄일 수 있다.

{{% /notice %}}

## Manage users and groups

내가 `Ansible`의 ad-hoc command를 사용하는 일반적인 사용법은 user와 group 관리이다.
내가 user를 생성하며 home folder를 생성할지 말지와, 특정 유저를 특정 group에 추가하는 방법을 얼마나 많이 구글링했는지 모른다.

`Ansible`의 user와 group module은 이런 것들을 어느 Linux 에서나 꽤 간단하고 표준적인 방법으로 할 수 있게 해준다.

먼저, 간단히 server administrator를 위한 `admin` group을 app server에 추가하자.

```bash
$ ansible app -b -m group -a "name=admin state=present"
```

`group` module은 매우 간단하다.
group을 `state=absent`로 하면 삭제가 되고 group id는 `gid=[gid]`로 설정할 수 있으며 group이 system group인지 나타내려면 `system=yes`를 설정하면 된다.

이제 `johndoe`라는 user를 app server에 추가하고 생성한 group에 넣을 것이며 `/home/johndoe`에 home directory를 추가할 것이다.
(Linux 배포판에서 default location이다)

```bash
$ ansible app -b -m user -a "name=johndoe group=admin createhome=yes"
```

새로운 유저에 대해 자동으로 SSH key를 생성하고 싶다면 (존재하지 않는 경우) 같은 명령어를 `generate_ssh_key=yes`를 넣어 실행하면 된다.
또한 user의 UID를 `uid=[uid]`를 통해 설정할 수 있고, user의 shell을 `shell=[shell]`로 설정할 수 있으며 password를 `password=[encrypted-password]`로 설정할 수 있다.

account를 삭제하려면 어떻게 해야 할까?

```bash
$ ansible app -b -m user -a "name=johndoe state=absent remove=yes"
```

`Ansible`의 `user` module을 통해 `useradd`, `userdel`, `usermod`의 모든 것을 사용할 수 있으며 심지어 더 쉽다.
[공식 User module 가이드](http://docs.ansible.com/user_module.html)에 더 자세한 설명이 있다.

## Manage files and directories

또 다른 ad-hoc command의 일반적인 사용법은 remote file management이다.
`Ansible`은 host에서 remote server로 파일을 복사하는 것, 디렉토리를 생성하는 것, 파일과 디렉토리의 권한과 소유권을 관리하는 것, 파일과 디렉토리를 삭제하는 것이 매우 쉽다.

### Get information about a file

파일의 권한, MD5, 소유자를 확인하려면 `Ansible`의 `stat` module을 사용하면 된다.

```bash
$ ansible multi -m stat -a "path=/etc/environment"
```

이는 `stat` 명령어를 실행했을 때와 같은 정보를 보여주지만 JSON 형태로 출력해주어 좀 더 쉽게 parsing할 수 있게 된다.
(또는 나중에 playbook에서 조건을 걸어 어떤일을 할지 말지 결정할 수 있게 한다)

### Copy a file to the servers

아마도 `scp`나 `rsync`를 통해 파일과 디렉토리를 remote server로 복사해왔을 것이다.
`Ansible`은 `rsync` module을 가지고 있으며 대부분의 파일 복사관련 명령은 `copy` module로도 할 수 있다.

```bash
$ ansible multi -m copy -a "src=/etc/hosts dest=/tmp/hosts"
```

`src`는 파일이나 디렉토리가 될 수 있다.
마지막에 슬래쉬로 끝나게 되면 디렉토리의 내용들만 `dest`로 복사가 된다.
슬래쉬를 생략하면 내용과 디렉토리 그 자체가 `dest`로 복사된다.

`copy` module은 단일 파일 복사에 완벽하며 작은 디렉토리에서도 잘 작동한다.
수백개의 파일을 복사하려는 경우, 특히 서브 디렉토리가 많은 경우에는 `Ansible`의 `unarchive` module이나 `synchronize` module을 이용해서 복사하는 것을 고려해보면 좋을 것이다.

### Retrieve a file from the servers

`fetch` module은 `copy` module과 거의 비슷하게 동작하지만 반대인 것이 다르다.
가장 주요한 차이점은 파일이 local `dest`의 디렉토리로 일치하는 host의 파일을 가져온다.
예를 들어 다음의 명령어는 hosts file을 서버에서 가져오는 것이다.

```bash
$ ansible multi -b -m fetch -a "src=/etc/hosts dest=/tmp"
```

Fetch는 default로 각 서버의 `/etc/hosts` 파일을 destination folder 안에 host의 이름을 추가하여 저장할 것이다.
(우리의 경우 세 IP 주소이다)
따라서 `db` server의 hosts file은 `/tmp/192.168.60.6/etc/hosts`로 저장될 것이다.

`flat=yes`라는 파라미터를 추가하고 `dest`를 `dest=/tmp/`로 설정하여(슬래쉬로 끝내기) `Ansible`이 file을 직접 `/tmp` 디렉토리로 fetch할 수 있다.
하지만 filename은 반드시 유일해야 이것이 동작하고 따라서 여러 호스트에서 파일을 가져올 때는 적합하지 않다.
`flat=yes`는 하나의 호스트에서 파일을 가져올 때만 써야한다.

### Create directories and files

`file` module을 사용하여 파일과 디렉토리를 생성(`touch` 처럼)할 수 있고, 권한 관리와 파일과 디렉토리의 소유권을 관리, SELinux 속성 수정, symlink 생성을 할 수 있다.

디렉토리를 생성하는 방법이다.

```bash
$ ansible multi -m file -a "dest=/tmp/test mode=644 state=directory"
```

symlink를 생성하는 방법이다.

```bash
$ ansible multi -m file -a "src=/src/symlink dest=/dest/symlink owner=root group=root state=link"
```

### Delete directories and files

`state`를 `absent`로 설정하여 파일이나 디렉토리를 삭제할 수 있다.

```bash
$ ansible multi -m file -a "dest=/tmp/test state=absent"
```

`Ansible`을 통해 원격 파일을 관리하는 방법은 매우 많다.
우리는 짧게 `copy`와 `file` module을 살펴보았지만, 다른 `lineinfile`, `ini_file`, `unarchive`같은 file-management module의 문서도 읽어보도록 해라.
이 책에서는 이런 module에 대해 나중 챕터에서 다루도록 하겠다.
(playbooks와 함께.)

## Run operatioins in the background