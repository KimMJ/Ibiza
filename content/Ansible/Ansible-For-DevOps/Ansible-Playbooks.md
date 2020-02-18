---
title: "Ansible Playbooks"
menuTitle: "Ansible Playbooks"
date:  2020-02-13T20:59:01+09:00
weight: 5
draft: false
tags: ["ansible", "ansible-playbooks"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

## Power plays

다른 여느 configuration management solution처럼 `Ansible`은 configuration file을 설명하는데 메타포를 사용한다.
이를 `playbooks`라고 부르고 여기에는 특정한 서버나 특정 서버 그룹에서 실행되는 tasks(`Ansible`의 용어에서는 `play`)의 리스트가 있다.
미식 축구에서 팀은 게임에서 이기기 위해 사전 정의된 playbook을 플레이의 기반으로 실행하고 따른다.
`Ansible`에서 우리는 `playbook`(서버가 특정한 configuration state로 가기 위해 실행해야 하는 스텝들의 리스트)을 작성하고 서버 위에서 `play`되도록 할 것이다.

`Playbook`은 configuration을 정의하는 상황에서는 자주 쓰이고 사람이 읽을 수 있는 간단한 문법을 가진 `YAML`로 작성되어있다.
`Playbook`은 다른 `playbook`에 포함될 수 있고 특정 metadata와 옵션들은 다른 play를 하도록 할 수 있으며 또는 `playbook`이 서버마다 다른 시나리오로 동작하게 할 수도 있다.

`ad-hoc` 명령어는 그 자체로 `Ansible`을 powerful하게 만들어준다.
`playbook`은 `Ansible`을 최고의 server provisioning과 configuration management tool로 만들어준다.

대부분의 DevOps 사람들이 `Ansible`에 매료된 이유는 shell scripts를 쉽게 직접 ansible play로 변경할 수 있기 때문이다.
다음의 스크립트가 있다고 가정해보자.
이는 RHEL/CentOS 서버에 Apache를 설치하는 것이다.

```bash
# Install Apache
yum install --quiet -y httpd httpd-devel
# Copy configuration files
cp /path/to/config/httpd.conf /etc/httpd/conf/httpd.conf
cp /path/to/config/httpd-vhosts.conf /etc/httpd/conf/httpd-vhosts.conf
# Start Apache and configure it to run at boot
service httpd start
chkconfig httpd on
```

shell script를 실행하려면(이 경우에 파일 이름은 `shell-script.sh`이다), command line에서 직접 호출하면 된다.

```bash
# (From the same directory in which the shell script resides)
$ ./shell-script.sh
```

**Ansible Playboook**

```yaml
---
- hosts: all
  tasks:
  - name: Install Apache.
    command: yum install --quiet -y httpd httpd-devel
  - name: Copy configuration files.
    command: >
      cp /path/to/config/httpd.conf /etc/httpd/conf/httpd.conf
  - command: >
      cp /path/to/config/httpd-vhosts.conf /etc/httpd/conf/httpd-vhosts.conf
  - name: Start Apache and configure it to run at boot.
    command: service httpd start
  - command: chkconfig httpd on
```

`Ansible` Playbook을 실행하려면(이 경우 파일 이름은 `playbook.yml`이다), `ansible-playbook` 명령어로 호출할 수 있다.

```bash
# (From the same sirectory in which the playbook resides)
$ ansible-playbook playbook.yml
```

`Ansible`은 표준 shell command를 작성할 수 있고(수 십년간 사용해왔던 명령어들) 시간만 있다면 playbook을 사용하도록 빠르게 바꿀 수 있고 `Ansible`의 유용한 기능의 장점을 사용하여 configuration을 rebuild할 수 있어 강력한 툴이다.

위의 playbook에서 `Ansible`의 `command` module을 사용하여 standard shell commands를 실행시켰다.
또한 우리는 각 play에 `name`을 부여하여 playbook을 실행했을 때 play가 사람이 읽을 수 있는 결과를 스크린 또는 로그에 띄울 수 있도록 한다.
command module은 다른 트릭들을 가지고 있지만 지금 우리는 shell script가 `Ansible` playbook으로 귀찮은 작업 없이 바로 변환이 가능하고 확신한다.

{{% notice note %}}

`>`는 `command:` module 바로 뒤에 와서 YAML이 "자동으로 다음의 indented line을 하나의 긴 string으로 줄바꿈은 스페이스로 분리하며 변환"하도록 해준다.
이는 어떤 케이스에선 readability를 향상시키는데 도움을 준다.
유효한 YAML 문법을 통해 configuration을 설명하는 방법에는 많은 것들이 있고 이런 방법들은 나중에 Appendix B - YAML Conventions and Best Practices 섹션에서 깊게 다루어 볼 것이다.  
이 책은 세가지 task-formatting 테크딕들을 살펴볼 것이다.
하나 또는 두개의 간단한 parameter가 있는 task는 `Ansible`의 shorthand syntax가 사용될 것이다(예: `yum: name=apache2 state=installed`).
더 긴 command 입력이 필요한 `command`나 `shell`의 대부분의 경우에는 위에서 언급한 `>` 테크닉을 사용할 것이다.
여러 parameter가 필요한 task들은 YAML object notation이 사용된다.
이는 각 줄의 key와 variable을 대치할때 사용된다.

{{% /notice %}}

위의 playbook이 정확히 shell script와 같은 동작을 하지만 이를 `Ansible`의 built-in modules로 어려운 일을 해결할 수 있다.

**Revised Ansible Playbook - Now with idempotence!**

```yaml
---
- hosts: all
  sudo: yes
  tasks:
  - name: Install Apache.
    yum: name={{ item }} state=present
    with_items:
    - httpd
    - httpd-devel
  - name: Copy configuration files.
    copy:
      src: "{{ item.src }}"
      dest: "{{ item.dest }}"
      owner: root
      group: root
      mode: 0644
    with_items:
    - {
        src: "/path/to/config/httpd.conf",
        dest: "/etc/httpd/conf/httpd.conf"
    }
    - {
        src: "/path/to/config/httpd-vhosts.conf",
        dest: "/etc/httpd/conf/httpd-vhosts.conf"
    }
  - name: Make sure Apache is started and configure it to run at boot.
    service: name=httpd state=started enabled=yes
```

이제 뭔가 되어가고 있다.
이제 이 playbook을 차근차근 밟아보자.

1. 처음에 `---`는 이 문서를 YAML syntax를 가지고 사용했다고 표시한 것이다.
   마치 HTML의 맨 위에 `<html>`을 쓰는것 또는 PHP code block 제일 위에 `<?php`를 넣는것과 같다.
2. 둘째 줄의 `- hosts: all`은 첫(이 경우는 유일하게) `play`를 정의한 것이고 `Ansible`이 알고있는 `all` hosts에서 play를 실행하도록 한다.
3. 셋째 줄에서 `sudo: yes`는 `Ansible`이 모든 명령어를 `sudo`를 통해 실행하도록 하고 따라서 모든 명령어는 root 유저로 실행될 것이다.
4. 네번째 줄에서 `tasks:`는 `Ansible`이 다음의 task 목록들을 이 playbook의 일부로 실행하도록 하는 것이다.
5. 첫번째 task는 `name: Install Apache...`로 시작하고 name은 서버에서 어떤 동작을 하는 module은 아니다.
   그냥 사람이 읽을 수 있는 description을 제공한다.
   `Install Apache`를 보는 것은 `yum name=httpd state=installed`를 보는 것보다 상대적으로 더 연관성이 있어 보인다.
   그러나 name 줄을 완전히 지워버버려 아무 문제도 발생하지 않는다.
   * `yum` module을 사용하여 Apache를 설치하였다.
     `yum -y install httpd httpd-devel`을 사용하는 것 대신 `Ansible`에게 정확히 우리가 원하는 상태가 뭔지 알려주었다.
     `Ansible`은 `items` 배열에서 우리가 넣은 값들을 가져올 것이다.
     (`{{ variable }}`는 `Ansible` playbook의 variable을 참조한다)
     우리는 `yum`이 `state=present`를 통해 우리가 정의한 패키지가 설치되어있다고 확신할 수 있지만 `state=latest`로 하면 최신 버전이 깔려있도록 할 수도 있고 `state=absent`를 하면 패키지가 설치되지 않은 상태가 되도록 할 수도 있다.
   * `Ansible`은 `with_items`를 이용하여 간단한 리스트를 tasks에 주입할 수 있다.
     item의 list를 하단에 정의하면 각 라인은 play에 하나씩 전달될 것이다.
     이 경우에 각 아이템은 `{{ item }}` variable로 대체되었다.
6. 두번째 task는 다시 사람이 읽을 수 있는 name을 설정하는 것으로 시작한다.
   (원한다면 지울 수 있다.)
   * 우리는 `copy` module을 사용하여 파일을 source(우리의 local workstation)에서 destination(관리중인 서버)로 복사할 것이다.
     소유권과 권한(`owner`, `group`, `mode`)을 포함한 file metadata같은 더 많은 variable들을 전달할 수도 있다.
   * 이 경우 변수 치환을 위해 multiple elements를 사용한 배열을 쓸 것이다.
     이 때 `{ var1: value, var2: value }` 문법을 사용하여 각 variable에 대한 element를 정의할 수 있다.
     (원하는 만큼 variable을 정의할 수 있고 또는 nested level로 variable을 정의할 수 있다.)
     play에서 variable을 언급하면 item의 variable에는 `.`을 통해 접근할 수 있고 따라서 `{{ item.var1 }}`을 통해 첫번째 variable에 접근할 수 있다.
     우리의 예시에서 `item.src`는 각 item의 src에 접근하는 것이다.
7. 세번째 task는 사람이 읽을 수 있는 포멧으로 정의된 이름을 사용한다.
   * 우리는 `service` module을 사용하여 특정 service의 원하는 상태를 기술할 것이다.
     이 경우에는 Apache의 http daemon인 `httpd`이다.
     우리는 이것이 실행중이길 원하고 따라서 `state=started`로 설정하였고 또 시스템이 시작되었을 때 실행되길 원하기 때문에 `enabled=yes`로 설정하였다.
     (`chkconfig httpd on`과 동일하다.)

명령어의 리스트를 변환한 것의 가장 좋은 점은 `Ansible`이 계속해서 모든 우리의 서버의 상태를 추적한다는 것이다.
playbook을 처음 실행하면 이는 Apache가 설치되었고 동작되었는지 확인하고, custom configuration이 제위치에 있는지 확인하여 서버를 provision한다.

더 좋은 점은 **두번째** 실행했을 때 서버가 제대로 된 상태에 있다면 실제로 아무것도 하지도 않고 우리에게 아무것도 변경된 것이 없다고 말해준다.
따라서 이 짧은 playbook을 통해, 우리는 provision할 수 있고 Apache web server에 대해 적절한 configuration이 되었음을 확인할 수 있다.
게다가 playbook을 `--check` 옵션으로 실행하면(아래의 다음 섹션에서 확인할 수 있다) configuration이 우리가 playbook에서 정의한 것과 일치하는지를 서버에서 실제 task를 돌리지 않고도 검증할 수 있다.

configuration을 업데이트하고 싶거나 다른 httpd 패키지를 설치하고 싶으면 file을 local에서 수정하거나 패키지를 `with_items` 리스트안에 넣고 다시 playbook을 실행하면 된다.
하나든 수천개의 서버든지 그 configuration은 우리의 playbook에 맞게 업데이트될 것이다.
그리고 `Ansible`은 우리에게 어떤 것이 변하였는지 알려줄 것이다.
(각각의 production server에 ah-hoc change를 만들지는 않았을 것이다. 그렇지 않은가?)

## Running Playbooks with `ansible-playbook`

위의 예시로 playbook을 실행한다면(`all` hosts로 실행하게 되어있다), playbook은 `Ansible` inventory file에 정의된 모든 host에 대해 실행될 것이다(챕터 1의 basic inventory file 예시를 확인해보아라).

### Limiting playbooks to particular hosts and groups

`hosts:`를 바꿔서 playbook이 특정한 그룹이나 각각의 hosts에만 동작할 수 있도록 설정할 수 있다.
해당 값은 `all` hosts, inventory에 정의된 `group`, 여러 group들 (e.g. `webservers, dbservers`, 개별 서버(e.g. `at1.example.com`, 혼합된 host들로 설정할 수 있다.
또한 `*.example.com`과 같은 wildcard를 사용하여 최상위 도메인 중 매칭되는 모든 도메인으로 설정할 수 있다.

또한 `ansible-playbook` 명령어를 통해 playbook이 실행될 hosts를 제한할 수 있다.

```bash
$ ansible-playbook playbook.yml --limit webservers
```

이 경우(inventory file이 `webserver` group을 포함한다고 가정한다), playbook이 `hosts: all`로 설정되어 있거나 `webservers` group외의 hosts들을 포함한다고 하더라도 `webservers`에 정의된 hosts에서만 동작한다.

또한 playbook을 특정 hosts에만 동작하게 할 수 있다.

```bash
$ ansible-playbook playbook.yml --limit xyz.example.com
```

실행시키기 전에 playbook에 의해 영향을 받는 hosts들이 실제 어떤것인지 확인하고 싶으면 `--list-hosts`를 사용하면 된다.

```bash
$ ansible-playbook playbook.yml --list-hosts
```

결과는 다음과 같을 것이다.

```plain-text
playbook: playbook.yml

  play #1 (all): host count=4
    127.0.0.1
    192.168.24.2
    foo.example.com
    bar.example.com
```

(`count`는 inventory에 정의된 서버의 숫자이고 그 아래는 inventory에 정의된 모든 hosts의 리스트이다.)

### Setting user and sudo options with `ansible-playbook`

playbook의 `hosts` 안에 어떤 `user`도 정의되어 있지 않으면 `Ansible`은 특정 host에 대해 inventory file에서 정의한 user로 접속한다고 가정하며, 그 다음 local user account name으로 변경할 것이다.
`--remote-user (-u)` 옵션을 통해서 원격 play에 사용될 remote user를 명시적으로 정의할 수 있다.

```bash
$ ansible-playbook playbook.yml --remote-user=johndoe
```

어떤 상황에서는 원격 서버에서 `sudo`를 통해 명령어를 수행하기 위해 sudo password를 입력해야할 필요가 있을 것이다.
이런 상황에서는 `--ask-sudo-pass (-K)` 옵션이 필요할 것이다.
또한 `--sudo`를 사용하여 명시적으로 playbook 안의 모든 tasks를 강제로 sudo 권한으로 실행하게 할 수 있다.
마지막으로 `--sudo-user (-U)`옵션을 통해 `sudo`로 tasks를 실행할 sudo user(default는 root)를 지정할 수 있다.

예를 들어, 다음의 명령어는 playbook을 sudo로 실행할 것이고, task에서 `janedoe`라는 sudo user를 쓸 것이고, `Ansible`은 sudo password를 입력하게 할 것이다.

```bash
$ ansible-playbook playbook.yml --sudo --sudo-user=janedoe --ask-sudo-pass
```

key-based 인증방식을 사용하여 서버에 접속하지 않는다면(챕터 1에서 그렇게 했을 때 security implication에 대한 경고사항을 읽어라), `--ask-pass`를 사용할 수 있다.

### Other options for `ansible-playbook`

`ansible-playbook` 명령어는 다른 옵션들도 사용할 수 있다.

* `--inventory=PATH (-i PATH)`: custom inventory file을 정의한다.
  (default는 default Ansible inventory file이고 보통은 `/etc/ansible/hosts`에 위치해 있다.)
* `--verbose (-v)`는 Verbose mode이다.
  (성공한 옵션들에 대한 output을 토함한 모든 output을 보여준다.)
  `-vvvv`를 통해 매 분마다 자세하게 볼 수 있다.
* `--extra-vars=VARS (-e VARS)`: playbook에서 사용되는 variables를 `"key=value, key=value"`의 형태로 정의할 수 있다.
* `--forks=NUM (-f NUM)`: fork하는 수이다(integer).
  이 값을 5보다 크게하여 `Ansible`이 task를 동시에 실행하는 서버의 수를 늘릴 수 있다.
* `--connection=TYPE (-c TYPE)`: 사용할 connection의 type이다.
  (default는 `ssh`이다.
  가끔은 `local`로 playbook을 local machine에서 실행할 수 있고 또는 cron을 통해 원격 서버에서 실행할 수 있다.)
* `--check`: playbook을 Check Mode ("Dry Run")으로 실행한다.
  playbook안에 정의된 모든 task는 모든 hosts에 대해 확인될 것이지만 실제로 실행하지는 않는다.

`ansible-playbook`을 최대한 활용하기 위해서 중요한 다른 옵션과 configuration variable이 있다.
그러나 여기 목록들로도 지금 챕터에서 우리의 서버와 가상 머신에 playbook을 실행하는데 충분한 것들이다.

{{% notice notes %}}

이 챕터의 나머지는 더 현실적인 `Ansible` playbook을 사용할 것이다.
이 챕터의 모든 예시는 [Ansible for DevOps GitHub repository]()에 있고, 이를 clone하여 컴퓨터에 저장하고(또는 online으로 코드를 띄워서) 뒤의 단계를 더 쉽게 할 수 있다.

{{% /notice %}}

## Real-world playbook: CentOS Node.js app server

물론 여전히 옛날 Apache 서버에서 static web page를 포스트하려는 사람에게는 유용할지 모르겠지만, 첫번째 예시는 real-world 시나리오에 적합하지는 않다.
실제로 오늘날 production infrastructure를 관리하는 데 사용되는 것과 관련된 더 많은 것들을 할 수 있는, 좀 더 복잡한 playbook을 실행할 것이다.

첫번째 playbook은 CentOS를 Node.js를 이용하여 설정할 것이다.
그리고나서 간단한 Node.js application을 설치하고 실행할 것이다.
서버는 매우 간단한 architecture로 되어있다.

```ascii
+-------------------------------------------------+
|                                                 |
|               Node.js Server/VM                 |
|                                                 |
+-------------------------------------------------+
|                                                 |
|  +-------------------------------------------+  |
|  |                                           |  |
|  |        Custom Node.js application         |  |
|  |                                           |  |
|  +-------------------------------------------+  |
|                                                 |
|  +-------------------------------------------+  |
|  |                                           |  |
|  |              Node.js + NPM                |  |
|  |                                           |  |
|  +-------------------------------------------+  |
|                                                 |
|  +-------------------------------------------+  |
|  |                                           |  |
|  |            CeonOS 6.4 (Linux)             |  |
|  |                                           |  |
|  +-------------------------------------------+  |
|                                                 |
+-------------------------------------------------+

```

시작하기에 앞서 우리의 playbook을 포함하는 YAML 파일(이 예시에서는 `playbook`)을 생성해야 한다.
간단하게 가보자.

```yaml
---
- hosts: all
  tasks:
```

먼저 playbook이 동작하게 될 hosts들의 set(`all`)를 정의한다.
(playbook을 특정 groups와 hosts에 제한하는 섹션을 상단에서 확인하라.)
그리하여 뒤의 task들이 해당 hosts에서 실행할 것들이라고 정의한다.

### Add extra repositories

extra repositories(yum이나 apt)를 추가하는 것은 admin들이 서버에서 다른 작업을 하기 전에 특정한 패키지가 사용 가능한지 또는 base installation보다 최신 버전이 있는지 확인하는 작업이다.

아래의 shell script에서 우리는 EPEL과 Remi repositories를 추가하여 Node.js나 필수 소프트웨어의 최신 버전을 받고 싶다.
(이 예시는 RHEL/CentOS 6.x에서 동작한다고 가정한다)

```bash
# Import EPEL GPG Key - see: https://fedoraproject.org/keys
wget https://fedoraproject.org/static/0608B895.txt \
  -O /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

# Import Remi GPG key - see: http://rpms.famillecollet.com/RPM-GPG-KEY-remi
wget http://rpms.famillecollet.com/RPM-GPG-KEY-remi \
  -O /etc/pki/rpm-gpg/RPM-GPG-KEY-rmi
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi

# Install EPEL and Remi repos.
rpm -Uvh --quiet \
  http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh --quiet \
  http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# Install Node.js (npm plus all its dependencies).
yum --enablerepo=epel install node
```

이 shell script는 rpm command를 사용하여 EPEL과 Remi repository GPG keys를 import한다.
그러면 repositoriy들이 추가되고 마침내 Node.js가 설치된다.
이는 간단한 deployment에서는 잘 작동하지만 이미 이전에 실행했었다면(즉, 두개의 repository와 그것의 GPG key가 추가되었다면) 이 모든 명령어를 다 실행하는 것(어떤것은 시간이 걸릴수도 있고 연결이 연결이 잘 안된다면 모든 스크립트가 멈출수도 있다)은 어리석은 짓이다.

{{% notice note %}}

몇가지 단계를 스킵하고싶으면 GPG key를 추가하는 것을 스킵할 수 있고 단순히 command를 `--nogpgcheck`(`Ansible`에서는 yum module의 `disabled_gpg_check` parameter를 `yes`로 설정한다)으로 실행하기만 하면 된다.
하지만 이를 활성화 하는 것이 좋은 생각이다.
GPG는 `GNU Privacy Guard`로, developer와 package distributor가 그들의 package에 서명하는 것이다.
(따라서 이 패키지가 원작자가 만든 것이며 수정이나 변경이 없었음을 확인해준다)
정말 우리가 뭘 하고있는지 알기 전까진 GPG key 체크같은 security setting을 disable하지 말아라.

{{% /notice %}}

`Ansible`은 좀 더 튼튼하다.
좀 더 verbose할지 몰라도 더 정형화된 방법으로 같은 동작을 수행하며 이해하기 쉽고 나중에 설명할 `Ansible`의 다른 기능들과 variable을 사용할 수 있다.

```yaml
- name: Import EPEL and Remi GPG keys.
  rpm_key: "key={{ item }} state=present"
  with_items:
  - "https://fedoraproject.org/static/0608B895.txt"
  - "http://rpms.famillecollect.com/RPM-GPG-KEY-remi"

- name: Install EPEL and Remi repos.
  command: "rpm -Uvh --force {{ item.href }} creates={{ item.creates }}"
  with_items:
  - {
    href: "http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.prm",
    creates: "/etc/yum.repos.d/remi.repo"
  }

- name: Disable firewall (since this is a dev environment).
  service: name=iptables state=stopped enabled=no

- name: Install Node.js and npm.
  yum: name=npm state=present enablerepo=epel

- name: Install Forever (to run our Node.js app).
  npm: name=forever global=yes state-latest
```

한 단계씩 살펴보자.

1. `rpm_key`는 매우 간단한 `Ansible` module로 RPM key를 URL이나 file, 이미 존재하는 key의 key id로부터 가져온다.
   그리고 key가 present이거나 absent(`state` parameter)가 되도록 한다.
   우리는 Fedora project의 EPEL과 Remi Repository 두 key를 import하고 싶다.
2. `Ansible`이 built-in rpm module을 가지고 있지 않기 때문에 우리는 rpm 명령어를 사용할 것이다.
   하지만 `Ansible`의 `command` module을 사용하여 우리는 두가지를 얻을 수 있다.
   1. `creates` pamameter로 `Ansible` 명령어를 실행하지 않을 때를 알려준다.
      (이 경우 `Ansible`에게 `rpm` command가 성공하면 어떤 파일이 존재하게 되는지 알려준다)
   2. multidimensional array를 사용하여(`with_items`) URL을 정의하고 `creates`로 결과 파일을 체크한다.
3. Node.js가 없으면 `yum`은 Node.js를 설치(Node의 package manager인 `npm`도 함께)한다.
   그리고 EPEL repo가 `enablerepo` parameter를 통해 검색될 수 있도록 한다.
   (`disablerepo`를 통해 명시적으로 repository를 `disable`할 수도 있다)
4. NPM이 설치되었기 때문에 `Ansible`의 `npm` module로 Node.js utility를 설치할 것이고 `forever`로 우리의 app을 실행하고 계속 동작하도록 할 것이다.
   `global`을 `yes`로 설정하면 NPM은 `forever` node moulde을 `/usr/lib/node_modules/`에 설치할 것이고 따라서 모든 user가 Node.js app을 시스템에서 사용할 수 있을 것이다.

이제 Node.js app server 셋업의 시작점에 와있다.
이제 간단한 Node.js app을 셋업하여 80포트에서 HTTP request를 받아보자.

### Deploy a Node.js app

다음 단계는 간단한 Node.js app을 우리의 서버에 설치하는 것이다.
먼저, `playbook.yml`이 위치한 폴더에 새 폴더 `app`을 생성하고 정말 간단한 Node.js app을 생성할 것이다.
폴더 안에서 새 파일 `app.js`를 생성하고 다음의 내용을 입력한다.

```js
// Load the express module
var express = require('express'),
app = express.createServer();

// Respond to requests for / with 'Hello World'.
app.get('/', function(req, res){
  res.send('Hello World!');
});

//Listen on port 80 (like a true web server).
app.listen(80);
console.log('Express server started successfully.');
```

문법이나 이것이 Node.js라는 것에 대해서는 걱정하지 말아라.
우리는 단지 빠르게 배포할 수 있는 예시가 필요한 것이다.
이 예시는 Python, Perl, Java, PHP 또는 다른 언어로 작성되지 않았다.
Node는 매우 간단한 언어(JavaScript)이기 때문에 간단하고 가벼운 환경에서 동작할 수 있고 서버를 테스트하거나 생성하는 데 사용하는 쉽고 좋은 언어이다.

이 작은 app이 Express(Node를 위한 http framework)에 의존성을 가지기 때문에, 우리는 NPM에게 `app.js`가 위치한 폴더와 같은 곳에 있는 `package.json`파일로 이 dependency에 대해 알려주어야 한다.

```js
{
  "name": "examplenodeapp",
  "description": "Example Express Node.js app.",
  "author": "Jeff Geerling <geerlingguy@mac.com>",
  "dependencies": {
    "expres": "3.x.x"
  },
  "engine": "node >= 0.10.6"
}
```

이제 다음을 playbook에 추가하고 전체 app을 서버에 복사한다.
그리고 NPM이 필요한 dependency들을 다운로드 받도록 한다(이 경우 `express`).

```yaml
- name: Ensure Node.js app folder exists.
  file: "path={{ node_apps_location }} state=directory"

- name: Copy example Node.js app to server.
  copy: "src=app dest={{ node_apps_location }}"

- name: Install app dependencies defined in package.json.
  npm: path={{ node_apps_location }}/app
```

먼저, 우리는 `file` module을 통해 우리의 app이 설치될 곳에 디렉토리가 있는지 확인할 것이다.
각 command에 사용된 `{{ node_apps_location }}` variable은 playbook, inventory의 최상단의 `vars` section 또는 `ansible-playbook`으로 호출한 command line에서 정의할 수 있다.

두번째로 우리는 전체 app 폴더를 `Ansible`의 `copy` command를 사용하여 복사할 것이다.
이는 똑똑하게 단일 파일과 디렉토리를 구별하며 `scp`나 `rsync`처럼 디렉토리 내부를 돌며 동작한다.

{{% notice note %}}

`Ansible`의 `copy` module은 단일 또는 작은 그룹의 파일에 대해 잘 동작하고, 자동으로 디렉토리를 순회한다.
파일의 갯수가 수백개가 될 경우 또는 디렉토리 개위가 깊은 경우엔 `copy`는 교착상태에 빠질 것이다.
이러한 상황에서는 `synchronize` module로 전체 디렉토리를 복사할 수 있고 또는 `unarchive`로 archive를 복사하고 이를 서버에서 expand할 수 있다.

{{% /notice %}}

세번째로 app에 대한 path에 관한 추가적인 arguments 없이 `npm`을 다시 사용한다.
이는 NPM이 package.json 파일을 읽고 모든 dependency들이 존재하는지 확인하는 것이다.

이제 거의 다 끝이 났다!
마지막 단계는 app을 실행하는 것이다.

### Launch a Node.js app

우리는 이제 (이전에 설치한)`forever`을 통해 app을 실행시킬 것이다.

```yaml
- name: Check list of running Node.js apps.
  command: forever list
  register: forever_list
  changed_when: false
- name: Start example Node.js app.
  command: "forever start {{ node_apps_location }}/app/app.js"
  when: "forever_list.stdout.find('{{ node_apps_location }}/app/app.js') == -1"
```

첫 play에서 우리는 두가지 새로운 것을 한다.

1. `register`는 새로운 variable `forever_list`를 생성하여 다음 play에서 언제 play를 실행해야하는지 결정하는 용도로 사용한다.
   `register`는 정의된 command에 variable name을 넣어서 output(stdout, stderr)를 보관한다.
2. `changed_when`은 `Ansible`이 명시적으로 이 play가 서버에 변경사항을 줄 것이라고 말해준다.
   이 경우 우리는 `forever list` command가 절대로 서버에 변경사항을 주지 않기 때문에 그냥 `false`를 설정한다.
   이 경우 서버는 command가 실행될 때 전혀 변경되지 않을 것이다.

두번째 play는 실제로 `forever`를 이용하여 app을 시작한다.
우리는 `node{{ node_apps_location }}/app/app.js`를 호출해서도 app을 시작할 수 있지만 프로세스를 쉽게 컨트롤할 수 없고 `Ansible`이 이 play에 hanging이 되는것을 막기 위해서는 `nohup`이나 `&`을 써야한다.

`forever`는 자신이 관리하는 Node app을 추적하고 우리는 `forever`의 `list` 옵션을 사용하여 동작중인 app의 리스트를 확인할 수 있다.
처음 이 playbook을 실행하면 list는 비어있을 것이다.
하지만 나중에 실행했을 때에는 app이 실행중이라면 우리는 이 app의 다른 인스턴스를 생성하고 싶지는 않다.
이런 상황을 피하려면 우리는 `Ansible`에게 언제 우리가 app을 시작하고 싶어하는지를 `when`을 통해 알려주면 된다.
특히 우리는 `Ansible`에게 app의 path가 `forever list` output에 없을 때에만 실행하라고 했다.

### Node.js app server summary

여기서 우리는 80 port로 오는 HTTP request에 대해 "Hello World!"를 출력하는 간단한 Node.js app을 설치하는 playbook을 완성하였다.

이 playbook을 server에서 동작하게 하려면(우리의 경우 Vagrant 또는 수동으로 새로운 VM을 테스트용도로 생성하면 된다) 다음의 명령어를 사용한다(`node_apps_location` variable을 command를 통해 넘겨라)

```bash
$ ansible-playbook playbook.yml --extra-vars="node_apps_location=/usr/local/opt/node"
```

우리의 playbook이 서버를 configuring하고 app을 대포하는 것을 마쳤다면 브라우저를 통해(`curl`, `wget`을 사용해도 된다) `http://hostname/`에 접속해보아라.
다음과 같은 결과를 볼 수 있다.

간단하지만 매우 강력하다.
우리는 50줄도 안되는 YAML로 Node.js application server 전체를 configure했다.

{{% notice notes %}}

전체 Node.js app server playbook은 이 책의 code repository인 <https://github.com/geerlingguy/ansible-for-devops>의 `nodejs` 디렉토리에서 확인할 수 있다.

## Real-world playbook: Ubuntu LAMP server with Drupal
