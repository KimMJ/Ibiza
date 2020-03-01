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
  become: yes
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
3. 셋째 줄에서 `become: yes`는 `Ansible`이 모든 명령어를 `sudo`를 통해 실행하도록 하고 따라서 모든 명령어는 root 유저로 실행될 것이다.
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
  become: yes
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
  - "http://rpms.famillecollet.com/RPM-GPG-KEY-remi"

- name: Install EPEL and Remi repos.
  command: "rpm -Uvh --force {{ item.href }} creates={{ item.creates }}"
  with_items:
  - {
    href: "http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm",
    creates: "/etc/yum.repos.d/remi.repo"
  }

- name: Ensure firewalld is stopped (since this is a test server).
  service: name=firewalld state=stopped

- name: Install Node.js and npm.
  yum: name=npm state=present enablerepo=epel

- name: Install Forever (to run our Node.js app).
  npm: name=forever global=yes state=present
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

이젠 Ansible `playbook`과 그것을 정의하는 YAML 문법에 친숙해져야 한다.
여기서 대부분의 예시는 CentOS, RHEL, Fedora 서버를 사용한다고 가정한다.
Ansible은 다른 Linux나 BSD같은 시스템에서도 잘 동작한다.
다음의 예시에서 Drupal website를 실행하기 위해 우리는 전통적인 LAMP(Linux, Apache, MySQL, PHP)를 Ubuntu 12.04에 셋업할 것이다.

```chart
+-----------------------------------------------------------+
|                                                           |
|                  Drupal LAMP Server / VM                  |
|                                                           |
+-----------------------------------------------------------+
|                                                           |
| +-------------------------------------------------------+ |
| |                                                       | |
| |                                                       | |
| |                 Drupal (application)                  | |
| |                                                       | |
| |                                                       | |
| +-------------------------------------------------------+ |
|                                                           |
| +--------------------------+ +--------------------------+ |
| |                          | |                          | |
| |       PHP 5.4.x          | |                          | |
| |                          | |        Mysql 5.6.x       | |
| |       Apache 2.2.x       | |                          | |
| |                          | |                          | |
| +--------------------------+ +--------------------------+ |
|                                                           |
| +-------------------------------------------------------+ |
| |                                                       | |
| |                      Ubuntu 12.04                     | |
| |                                                       | |
| |                        (Linux)                        | |
| |                                                       | |
| +-------------------------------------------------------+ |
|                                                           |
+-----------------------------------------------------------+
```

## Include a variables file, and discover `pre_tasks` and `handlers`

이 playbook에서 우리는 좀 더 playbook을 효과적으로 구성하는 것부터 시작할 것이다.
command line을 통해 전달해주어야 할 필수 variable들을 정의하는 대신, 분리된 `vars.yml`파일에서 Ansible이 사용할 variables를 따로 관리하여 playbook을 실행하도록 하자.

```yaml
- hosts: all

  vars_files:
  - vars.yml
```

하나 이상의 variable file을 가지면 main playbook file을 깨끗하게 해줄 것이고 모든 configurable variable을 한곳에 정리할 수 있다.
이 때, 우리는 어떤 variable도 추가하지 않아도 된다.
우리는 `vars.yml`을 나중에 정의할 것이다.
지금은 빈 파일을 생성하고 playbook의 다음 section인 `pre_task`를 진행해보자.

```yaml
  pre_tasks:
  - name: Update apt cache if needed.
    apt: update_cache=yes cache_valid_time=3600
```

Ansible은 main으로 실행할 task들이 실행되기 전과 이후에 `pre_tasks`와 `post_tasks`로 특정한 task를 실행할 수 있다.
이 경우에 우리는 playbook의 나머지가 실행되기 전에 apt cache가 업데이트 되어 우리의 서버에서 최신 버전의 패키지가 깔려있는지 확인을 하고 싶다.
우리는 Ansible의 `apt` module을 사용하여 지난 update 이후 3600초(1시간)보다 오래 경과했을 경우 cache를 업데이트 하라고 지시한다.

그런식으로 한 다음에 우리는 `handlers:`라는 새로운 section을 추가할 것이다.

```yaml
  handlers:
  - name: restart apache
    service: name=apache2 state=restarted
```

`handlers`는 그 그룹의 어느 task에서든지 `notify` 옵션을 추가하여 task 그룹 가장 마지막에 실행되는 특별한 종류의 task이다.
handler는 task들 중 하나가 handler에게 server에 변경사항을 만들 것(그리고 실패하지 않았음)이란걸 알릴 때만 호출되고 task 그룹의 가장 마지막에만 알림을 받는다.

이 hanlder를 호출하려면 `notify: restart apache` 옵션을 나머지 play에서 정의하면 된다.
우리는 이 handler를 정의하여 아래에 설명하듯 `apache2` service를 configuration이 변경되고 나서 재시작할 수 있도록 한다.

{{% notice notes %}}

variables처럼 handler와 task는 별도의 파일에 존재할 수 있고 playbook 안에서 이를 자그마하게 할 수 있다.
(이에 대해서는 챕터 6에서 다루어 볼 것이다.)
하지만 간결하게 하기 위해 이 챕터에서의 예시들은 하나의 playbook file에 모두 보여진다.
우리는 다른 playbook organization 방법에 대해 나중에 토론해 볼 것이다.

{{% /notice %}}

### Basic LAMP server setup

LAMP stack에 의존성을 가지는 application server를 구축하는 첫 단계는 실제 LAMP 쪽을 빌드하는 것이다.
이는 간단한 프로세스이지만 개별 서버에서 추가적인 약간의 작업이 필요하다.
Apache, MySQL, PHP를 설치하고 싶지만 우리는 또한 다른 dependency도 필요하고 또한 extra apt repository에서만 사용할 수 있는 PHP의 특정 버전(5.5) 버전이 필요하다.

```yaml
  tasks:
  - name: Get Software for apt repository management.
    apt: name={{ item }} state=installed
    with_items:
    - python-apt
    - python-pycurl
  - name: add ondrej repository for later versions of PHP.
    apt_repository: repo='ppa:ondrej/php5' update_cache=yes

  - name: "Install Apache, MySQL, PHP, and other dependencies."
    apt: name={{ item }} state=installed
    with_items:
    - git
    - curl
    - sendmail
    - apache2
    - php5
    - php5-common
    - php5-mysql
    - php5-cli
    - php5-curl
    - php5-gd
    - php5-dev
    - php5-mcrypt
    - php-apc
    - php-pear
    - python-mysqldb
    - mysql-server
  - name: Disable the firewall (since this is for local dev only).
    service: name=ufw state=stopped

  - name: "Start Apache, MySQL, and PHP."
    service: "name={{ item }} state=started enabled=yes"
    with_items:
    - apache2
    - mysql
```

이 playbook에서 우리는 각각 이름지어진 play에 간단한 prefix를 추가하기로 경정하였고 따라서 playbook의 progress가 실행될 때 더 쉽게 따라갈 수 있게 되었다.
일반적인 LAMP setup으로 시작할 것이다.

1. 두개의 helper library를 설치할 것이다.
   이것들은 python이 apt을 더 정확하게 관리할 수 있도록 한다.
   (`python-apt`, `python-pycurl`은 `apt-repository` module이 동작하는 데 필요하다)
2. Ubuntu 12.04의 default apt repository가 PHP 5.4.x(또는 이후 버전)를 포함하지 않기 때문에 PHP 5.4.25(이글을 작성하는 시점에서)과 나머지 PHP package들을 포함하는 ondrej의 `PHP5-oldstable` repository를 설치한다.
3. 우리의 LAMP server에 필요한 모든 package를 설치한다(Drupal을 실행하기 위한 php5 extension들도 설치한다).
4. 테스트 목적을 위해 firewall을 모두 disable한다.
   production server나 어떤 server가 인터넷에 노출되어 있으면 22, 80, 443 또는 필요한 port만 허용하는 엄격한 firewall을 사용해야 한다.
5. 모든 필요한 service를 시작하고 system boot 시 enable되도록 해야한다.

### Configure Apache

다음 단계는 Apache가 Drupal과 잘 동작할 수 있도록 설정하는 것이다.
기본적으로 Ubuntu 12.04의 Apache는 mod_rewrite enabled가 되어있지 않다.
이를 해결하기 위해 우리는 `sudo a2enmod rewrite` 명령어를 입력해야 하지만 Ansible은 `apache2_module` module로 이를 간단하게 할 수 있다.

추가적으로 VirtualHost entry를 추가하여 Apache에게 사이트 문서의 root가 어딘지 알려주고 사이트의 다른 옵션들을 알려주어야 한다.

```yaml
  - name: Enable Apache rewrite module (required for Drupal).
    apache2_module: name=rewrite state=present
    notify: restart apache

  - name: Add Apache virtualhost for Drupal 8 development
    template:
      src: "templates/drupal.dev.conf.j2"
      dest: "/etc/apache2/sites-available/{{ domain }}.dev.conf"
      owner: root
      group: root
      mode: 0644
    notify: restart apache

  - name: Symlink Drupal virtualhost to sites-enabled.
    file:
      src: "/etc/apache2/sites-available/{{ domain }}.dev.conf"
      dest: "/etc/apache2/sites-enabled/{{ domain }}.dev.conf"
      state: link
    notify: restart apache

  - name: Remove default virtualhost file.
    file:
      path: "/etc/apache2/sites-enabled/000-default"
      state: absent
    notify: restart apache
```

첫번째 명령어는 모든 필요한 Apache module들을 `/etc/apache2/mods-available`에서 `/etc/apache2/mods-enabled`로 symlink를 걸어 enable하는 것이다.

두번째 명령어는 우리가 templates 폴더 안에서 정의한 Jinja2 template을 Apache의 `sites-available` 폴더로 올바른 owner와 permission을 가지고 복사하는 것이다.
추가적으로 새로운 VirtualHost로 복사하는 것은 Apache가 변경사항을 가져오기 위해 재시작되어야 한다는 뜻이므로 `restart apache` handler에게 `notify`를 한다.

Jinja2 template(filename 마지막에 `.j2`라고 적혀있다)인 `drupal.dev.conf.j2`를 확인해보자.

```j2
<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  ServerName {{ domain }}.dev
  ServerAlias www.{{ domain }}.dev
  DocumentRoot {{ drupal_core_path }}
  <Directory "{{ drupal_core_path }}">
    Options FollowSymLinks Indexes
    AllowOverride All
  </Directory>
</VirtualHost>
```

이는 Apache VirtualHost definition의 거의 표준 형식이지만 우리는 거기에 Jinja2 template 변수들을 섞어넣었다.
Jinja2 template에서의 변수를 프린트하는 문법은 Ansible playbook의 문법과 동일하다. - 두개의 bracket(`{`)으로 변수의 이름을 감싼다. (`{{ varialbe }}`)

우리는 세가지 variable(`drupal_core_version`, `drupal_core_path`, `domain`)이 필요하여 이들을 전에 생성했던 `vars.yml` 파일에 추가해 주었다.

```yaml
# The core version you want to use (e.g. 6.x, 7.x, 8.0.x).
drupal_core_version: "8.0.x"

# The path where Drupal will be downloaded and installed.
drupal_core_path: "/var/www/drupal-{{ drupal_core_version }}-dev"

# The resulting domain will be [domain].dev (with .dev appended).
domain: "drupaltest"
```

이제 Ansible이 이 template을 위치시키게 될 play에 도달했을 때 Jinja2 template은 variable name을 value `8.0.x`와 `drupaltest`(또는 원하는 어떤 value)로 치환할 것이다.

마지막 두 task는(line 12-19) 방금 생성한 VirtualHost를 enable하고 더이상 사용하지 않는 default VirtualHost definition을 삭제할 것이다.

여기서부터 우리는 서버를 시작할 수 있지만 Apache는 우리가 정의한 VirtualHost가 아직 존재하지 않기 때문에(`{{ drupal_core_path }}`에 디렉토리가 아직 없다) 에러를 던질 것이다.
이는 `notify`를 사용하는 것이 중요한 이유이다. - 이 세 step이 끝나고 Apache를 재시작하기 위해 play를 추가하는 대신에(처음 playbook을 실행할 때는 에러가 발생할 것이다) notify는 task의 main group의 다른 모든 단계가 끝날때까지 기다린 뒤(server 세팅이 끝나기까지 시간을 준다) Apache를 재시작한다.

### Configure PHP with lineinfile

file management와 ad-hoc task execution에 관해 설명할 때 우리는 book에서의 `lineinfile`에 대해 짧게 언급했었다.
PHP의 configuration을 수정하는 것은 `lineinfile`의 simplicity와 usefulness를 설명하기에 매우 좋은 방법이다.

```yaml
  - name: Enable upload progress via APC.
    lineinfile:
      dest: "/etc/php5/apache2/conf.d/20-apcu.ini"
      regexp: "^apc.rfc1867"
      line: "apc.rfc1867 = 1"
      state: present
    notify: restart apache
```

Ansible의 `lineinfile` module은 간단한 task를 한다.
특정 text line이 파일에서 존재하는지(또는 존재하지 않는지) 확인한다.

이 예시에서 우리는 APC의 `rfc1867` option을 enable하여 Drupal이 APC의 파일 업로드 progress tracking을 사용하고 싶다.
(이걸 할수 있는 더 좋은 방법들이 있지만 우리의 간단한 서버를 위해선 이걸로도 충분하다)

먼저 `dest` parameter를 통해 `lineinfile`에게 파일의 위치를 알려주어야 한다.
그 다음 regular expression(Python-style)로 line이 어떻게 되어야 하는지를 정의한다.
(이 경우 line은 `apc.rfc1867`로 시작해야 한다. - 우리는 period를 escape해야 하는데 이는 regular expression에서 special character이기 때문이다)
그 다음 `lineinfile`에게 정확히 어떻게 resulting line이 되어야 하는지를 알려준다.
마지막으로 이 line이 present해야 한다고 명시적으로 언급한다.
(`state` parameter를 통해)

Ansible은 regular expression을 가지고 매칭되는 line이 있는지 본다.
있다면 Ansible은 line이 `line` parameter와 매칭되는지 확인한다.
매칭되지 않는다면 Ansible은 `line` parameter에 정의된 line을 추가한다.
Ansible은 추가하거나 line을 match `line`으로 변경해야하는 상황에서만 변경점을 report한다.

### Configure MySQL

다음 단계는 MySQL의 default test database를 삭제하고 Drupal installation에 사용할 (이전에 정의한 domain의 이름을 가진)database를 생성하는 것이다.

```yaml
  - name: Remove the MySQL test database.
    mysql_db: db=test state=absent
  
  - name: Create a database for Drupal.
    mysql_db: "db={{ domain }} state=present"
```

MySQL은 default로 `test`라 이름지어진 database를 설치하고 MySQL에 포함된 `mysql_secure_installation`의 일부 데이터베이스를 삭제하는 것을 권장한다.
MySQL을 configure하는 첫 단계는 이 database를 삭제하는 것이다.
그 다음 우리는 database를 `{{ domain }}`이란 이름으로 생성할 것이다 - database는 우리가 Drupal site에 사용할 domain가 동일하다.

{{% notice note %}}

Ansible은 많은 데이터베이스를 `out-of-the-box`로 제공하여 기본으로 이용할 수 있다.
(이 글을 작성하는 시점에는 `MongoDB`, `MySQL`, `PostgreSQL`, `Redis`, `Riak`가 있다)
MySQL의 경우 Ansible은 MySQLdb Python package(python-mysqldb)를 사용하여 database server의 connection을 관리하고 default root 계정 credentials를 사용한다고 가정한다.
(`root`가 username이고 passowrd는 없다)
이런 default를 그대로 두는 것은 명백히 잘못된 생각이다.
production server에서 첫번째 단계중 하나는 root account의 password를 바꾸고 root account를 localhost로만 제한하고 불필요한 user를 제거하는 것이어야 한다.  
만약 다른 credentials를 사용한다면 Ansible이 MySQL에 접속할 때 Ansible playbook이나 variable files에 password를 기록하는 방법이 아닌 접속시 사용할 `.my.cnf` 파일을 remote user의 home directory에 추가할 수 있다.
아니면 Ansible playbook을 실행할 때 MySQL의 username과 password를 입력하게 할 수 있다.
prompts를 사용하는 이 옵션은 이 책의 뒷부분에서 다룰 것이다.

{{% /notice %}}

### Install Composer and Drush

Drupal은 Drush의 형태로 commandl-line을 가지고 있다.
Drush는 Drupal과는 별개로 개발되고 있고 Drupal을 관리할 때 사용할 수 있는 CLI 명령어를 모두 제공한다.
Drush는 대부분의 현대 PHP 툴처럼 Composer의 dependency들을 설명해주는 파일인 `composer.json` 파일로 정의된 external dependency들이 있다.

여기서 우리는 단순히 Drupal을 다운로드하고 브라우저상으로 몇몇 setup을 수행하지만, playbook의 목적은 fully-automated가 되는 것이고, Drupal installation의 idempotent 속성을 부여하는 것이다.
따라서 우리는 Composer를 설치하고나서 Drush를 설치할 것이다.

```yaml
  - name: Install Composer into the current directory.
    shell: >
      curl -sS https://getcomposer.org/installer | php
      creates=/usr/local/bin/composer
  
  - name: Move Composer into globally-accessible location.
    shell: >
      mv composer.phar /usr/local/bin/composer
      creates=/usr/local/bin/composer
```

첫번째 명령어는 `composer.phar` PHP application archive를 생성하는 Composer의 php-based installer를 실행시킨다.
이 archive는 (shell command에서는 `mv`를 이용하여) `/usr/local/bin/compsoer`로 복사되고 이를 통해 간단히 `composer` 명령어만 사용하여 Drush의 dependency들을 설치할 수 있다.
각 명령어는 `/usr/local/bin/composer` 파일이 존재하지 않을 때에만 동작하도록 설정되어있다(`creates` parameter를 통해).

{{% notice notes %}}

왜 `command` 대신에 `shell`을 사용하는가?
Ansible의 `command` module은 host에서 명령을 실행할 때 많이 사용하는 option이다(Ansible의 module이 충분하지 않을 때).
그리고 이는 대부분의 시나리오에서 작동한다.
하지만 `command`는 remote shell `/bin/sh`를 통해 command를 실행할 수 없고 따라서 `<`, `>`, `|`, `&`같은 옵션과 `$HOME`같은 local environment variables가 작동하지 않는다.
`shell`은 command의 ouput을 다른 command로 pipe를 연결해주고 local environment에 접속할 수도 있다.  
remote로 shell command를 실행시키는 것을 도와주는 module은 두가지가 더 있다.
`script`는 shell scripts(하지만 shell script를 idempotent한 Ansible playbook로 바꾸는 것이 무조건 좋다)를 실행하고, `raw`는 raw commands를 SSH(다른 옵션을 사용하지 못할때만 사용해야한다)를 통해 실행한다.  
Ansible module을 모든 task에 사용하는 것이 가장 좋다.
만약 regular command line command를 사용해야만 한다면 `command` module을 먼저 시도해 보아라.
위에서 언급한 option들을 필요로 한다면 `shell`을 사용해라.
`script`나 `raw`는 최대한 사용하지 말아야 하고 이 책에서는 다루지 않을 것이다.

{{% /notice %}}

이제 GitHub를 사용하여 가장 최근 버전의 Drush를 install할 것이다.

```yaml
  - name: Check out drush master branch
    git:
      repo: https://github.com/drush-ops/drush.git
      dest: /opt/drush
  
  - name: Install Drush dependencies with Composer.
    shell: >
      /usr/local/bin/composer install
      chdir=/opt/drush
      creates=/opt/drush/vendor/autoload.php

  - name: Create drush bin symlink.
    file:
      src: /opt/drush/drush
      dest: /usr/local/bin/drush
      state: link
```

이 책의 앞부분에서 우리는 ad-hoc command를 통해 git repository를 clone하였다.
이번에는 `git` module을 사용하는 play를 정의하고 이를 통해 GitHub의 repository URL을 가지고 Drush를 clone할 것이다.
우리는 master branch를 사용할 것이기 때문에 `repo`(repository URL)과 `dest`(destination path) parameter를 넣어주어야 한다.

drush가 `/opt/drush`로 다운로드되고 나면, Composer를 사용하여 모든 필요한 dependency들을 설치한다.
이 경우 우리는 Ansible이 `composer install`를 `/opt/drush` 폴더에서 실행하길 원하고(이는 Composer가 자동으로 drush의 `composer.json` 파일을 검색하여 그렇게 된다) 따라서 우리는 parameter로 `chdir=/opt/drush`를 전달해주어야 한다.
Composer가 끝나고 나면 `/opt/drush/vendor/autoload.php`는 생성될 것이고 `creates` 파라미터를 사용하여 Ansible에게 파일이 이미 존재할 경우 이 단계를 건너뛰게 할 것이다(idempotency를 위해).

최종적으로 우리는 `/usr/local/bin/drush`에서 `/opt/drush/drush`로 symlink를 걸어주어 `drush` command가 시스템의 어느곳에서든지 실행할 수 있도록 하였다.

### Install Drupal with Git and Drush

우리는 다시 `git`을 사용하여 Drupal을 이전에 virtualhost configuration에서 정의한 대로 apache document root로 clone할 것이다.
그러고나서 Drupal의 installation을 drush를 통해 하고 다른 파일 permission issue들을 수정하여 Drupal이 VM에서 제대로 load되도록 설정할 것이다.

```yaml
  - name: Check out Drupal Core to the Apache docroot.
    git:
      repo: http://git.drupal.org/project/drupal.git
      version: "{{ drupal_core_version }}"
      dest: "{{ drupal_core_path }}"
  
  - name: Install Drupal.
    command: >
      drush si -y --site-name="{{ drupal_site_name }}" --acount-name=admin
      --account-pass=admin --db-url=mysql://root@localhost/{{ domain }}
      chdir={{ drupal_core_path }}
      creates={{ drupal_core_path }}/sites/default/settings.php
    notify: restart apache

  # SEE: https://drupal.org/node/2121849#comment-8413637
  - name: Set permissions properly on settings.php.
    file:
      path: "{{ drupal_core_path }}/sites/default/settings.php"
      mode: 0744

  - name: Set permissions on files directory.
    file:
      path: "{{ drupal_core_path }}/sites/default/files"
      mode: 0777
      state: directory
      recurse: yes
```

먼저 우리는 `vars.yml`파일 안에 정의된 `drupal_core_version`값으로 `version`을 지정하여 Drupal의 git repository를 clone할 것이다.
`git` module의 `version` parameter는 branch(`master`, `8.0.x` 등)와 tag(`1.0.1`, `7.24` 등) 또는 개별 commit hash(`50a1877` 등)를 지정하여 clone할 수 있다.

그 다음 Drush의 `si` 명령어(`site-install`의 줄임말)는 사용하여 Drupal의 installation(database를 configure하고, 몇가지 maintenance를 실행하고, site를 위한 몇몇 default configuration setting을 설정한다)을 실행할 것이다.
`drupal_core_version`과 `domain`같은 몇가지 variable들을 전달한다.
또한 `drupal_site_name`을 추가하여 varaible을 `vars.yml` 파일에 추가한다.

```yaml
# Your Drupal site name.
drupal_site_name: "D8 Test"
```

또한, Drupal의 installation process는 결과적으로 `settings.php` 파일을 생성한다.
따라서 우리는 해당 파일의 location을 `creates` parameter를 통해 Ansible이 site가 이미 설치되었는지를 판단하도록 할 수 있다(따라서 실수로 재설치하지 않는다).
site가 install되고 나면, Apache도 재시작할 것이다.
(Apache의 configuration을 업데이트할 때 사용했던 것처럼 `notify`를 다시 사용할 것이다.)

마지막 두 task는 Drupal의 `settings.php`와 폴더들의 permission을 각각 `744`와 `777`로 설정하는 것이다.

### Drupal LAMP server summary

이제 `http://drupaltest.dev/`로 서버에 접속하게 되면(`drupaltest.dev`가 VM의 IP주소를 가르킨다고 가정한다) Drupal의 default home page를 볼 수 있고 `admin/admin`으로 접속이 가능하다.
(production server에서는 명백히 안전한 password를 설정해야 한다)

Apache, MySQL, PHP를 실행하는 비슷한 server configuration으로 Drupal뿐 아니라 Symfony, Wordpress, Joomla, Laravel 등과 같은 다른 web frameworks와 CMS들을 실행할 수 있다.

{{% notice notes %}}

전체 Drupal LAMP server playbook의 예시는 책의 code repository인 <https://github.com/geerlingguy/ansible-for-devops>의 `drupal` directory에서 확인할 수 있다.

{{% /notice %}}

## Real-world playbook: Ubuntu Apache Tomcat server with Solr

Apache Solr는 full-text search, word highlighting, faceted search, fast indexing 등에 optimize된 빠르고 scalable한 search server이다.
매우 유명한 search server로 Ansible을 통해 설치하고 설정하기가 꽤 쉽다.
다음의 example에서 우리는 Apache Solr를 Ubuntu 12.04와 Apache Tomcat을 통해 설정할 것이다.

```plain
+-----------------------------------+
|                                   |
|       Apache Solr Server/VM       |
|                                   |
+-----------------------------------+
|                                   |
| +-------------------------------+ |
| |                               | |
| |        Apache Solr 4.x        | |
| |                               | |
| +-------------------------------+ |
|                                   |
| +-------------------------------+ |
| |                               | |
| |        Apache Tomcat 7        | |
| |                               | |
| +-------------------------------+ |
|                                   |
| +-------------------------------+ |
| |                               | |
| |      Ubuntu 12.04 (Linux)     | |
| |                               | |
| +-------------------------------+ |
|                                   |
+-----------------------------------+
```

**Apache Solr Server.**

### Include a variables file, and discover `pre_tasks` and `handlers`

이전의 LAMP server 예시처럼 우리는 분리된 `vars.yml` 파일에 있는 variable들을 Ansible에게 알려주는 것으로부터 playbook을 시작한다.

```yaml
- hosts: all
  
  vars_files:
  - vars.yml
```

`vars.yaml`에 대해 생각해보는 동안 빠르게 `vars.yaml` 파일을 생성하자.
Solr playbook과 동일한 폴더에 파일을 생성하고 다음의 내용을 추가하자.

```yaml
download_dir: /tmp
solr_dir: /opt/solr
```

이 두 변수는 Apache Solr를 다운로드하고 설치하는 동안 사용할 path를 정의한 것이다.

`vars_files`를 마치고 playbook으로 돌아와서 우리는 `pre_tasks`를 사용하여 apt cache가 업데이트되도록 할 것이다.

```yaml
  pre_tasks:
  - name: Update apt cache if needed.
    apt: update_cache=yes cache_valid_time=3600
```

Drupal playbook처럼 우리는 다시 `handlers`를 사용하여 `tasks` section에서 notify를 받는 특정한 tasks를 정의할 것이다.
이번에는 handler를 사용하여 Apache Solr에 영향을 주는 `tomcat7`과 Java servlet container를 재시작할 것이다.

```yaml
  handlers:
  - name: restart tomcat
    service: name=tomcat7 state=restarted
```

우리는 playbook 안에서 handler를 `notify: restart tomcat` 옵션을 통해 호출할 것이다.

### Install Apache Tomcat 7

Ubunntu 특정 서버에서 Tomcat7을 설치하는 것은 쉽다.
apt repository에 package가 있기 때문에 우리는 이것이 설치 되었는지, `tomcat7` service가 enabled 되었고 start 되었는지만 확인하면 된다.

```yaml
  tasks:
  - name: Install Tomcat 7.
    apt: "name={{ item }} state=installed"
    with_items:
      - tomcat7
      - tomcat7-admin
      - 
  - name: Ensure Tomcat 7 is started and enabled on boot.
    service: name=tomcat7 state=started enabled=yes
```

엄청 쉽다.
우리는 `apt` module을 이용하여 `tomcat7`과 `tomcat7-admin` 두 package를 설치하였다(그래서 우리는 Tomcat의 administrative backend에 로그인할 수 있다).
그리고 `tomcat7`을 시작하고 system boot할 때 start 되도록 설정한다.

### Install Apache Solr

Ubuntu 12.04는 Apache Solr에 대한 package를 포함한다.
하지만 매우 오래된 버전을 설치하기 때문에 우리는 source로부터 Solr의 최신 버전을 설치할 것이다.
첫번째 단계는 source를 다운로드하는 것이다.

```yaml
  - name: Download Solr.
    get_url:
      url: http://apache.osuosl.org/lucene/solr/4.9.1/solr-4.9.1.tgz
      dest: "{{ download_dir }}/solr-4.9.1.tgz"
      sha256sum: 4a546369a31d34b15bc4b99188984716bf4c0c158c0e337f3c1f98088aec70ee
```

우리는 가장 최근의 stable 버전인 Apache Solr 4.9.1을 설치한다.
remote server에서 파일을 다운로드 했을 때 `get_url` module은 raw `wget`이나 `curl` 명령어보다 더 유연함과 편리함을 제공한다.

`get_url`에 `url`(파일 소스를 다운로드할 주소)과 `dest`(다운로드된 파일이 위치할 곳)를 전달해 주어야 한다.
`dest` parameter로 디렉토리를 넘기면 Ansible은 파일을 안에다가 위치시키지만 나중에 playbook이 실행될 때마다 다시 다운로드할 것이다(만약 변경사항이 있다면 기존의 것은 overwrite된다).
이런 overhead를 피하기 위해 우리는 다운로드할 파일의 full path를 입력한다.

우리는 안정성을 위해 optional parameter인 또한 `sha256sum`을 사용한다.
파일이나 archive를 다운로드 하면 application의 functionality와 security의 취약점이 되기 때문에 file이 우리가 생각하는 것과 동일한지 확인하는 것은 좋은 생각이다.
`sha256sum`은 다운로드된 파일에서 data의 hash와 지정한 256-bit hash(`shasum -a 256 /path/to/file`을 통해 파일의 `sha256sum`을 얻을 수 있다)를 비교한다.
checksum이 제공한 hash와 일치하지 않으면 Ansible은 fail될 것이고 새로워진(그리고 유효하지 않는) 다운로드 파일을 버릴 것이다.

```yaml
  - name: Expand Solr.
    command: >
      tar -C /tmp -xvzf {{ download_dir }}/solr-4.9.1.tgz
      creates={{ download_dir }}/solr-4.9.1/dist/solr-4.9.1.war

  - name: Copy Solr into place.
    command: >
      cp -r {{ download_dir }}/solr-4.9.1 {{ solr_dir }}
      creates={{ solr_dir }}/dist/solr-4.9.1.war
```

우리는 Apache Solr archive를 압축해제하고 위치로 복사해야 한다.
이 두 단계를 위해 내장된 `tar`과 `cp` utility를 (적절한 옵션을 가지고) 사용한다.
`creates`를 설정하는 것은 Ansible이 나중에 다시 실행되었을 때 Solr war file이 이미 존재하기 때문에 이 단계를 건너 뛰게 한다.

```yaml
  # Use shell so commands are passed in correctly.
  - name: Copy Solr components into place.
    shell: >
      cp -r {{ item.src }} {{ item.dest }}
      creates={{ item.creates }}
    with_items:
      # Solr example configuration and war file.
      - {
        src: "{{ solr_dir }}/example/webapps/solr.war",
        dest: "{{ solr_dir }}/solr.war",
        creates: "{{ solr_dir }}/solr.war"
      }
      - {
        src: "{{ solr_dir }}/example/solr/*",
        dest: "{{ solr_dir }}/",
        creates: "{{ solr_dir }}/solr.xml"
      }
      # Solr log4j logging configuration
      - {
        src: "{{ solr_dir }}/example/lib/ext/*",
        dest: "/var/lib/tomcat7/shared/",
        creates: "/var/lib/tomcat7/shared/log4j-1.2.16.jar"
      }
      - {
        src: "{{ solr_dir }}/example/resources/log4j.properties",
        dest: "/var/lib/tomcat7/shared/classes",
        creates: "/var/lib/tomcat7/shared/classes/log4j.properties"
      }
    notify: restart tomcat
```

다음 task는 Apache Solr를 실행하는데 필요한 특정 디렉토리와 파일을 복사하는 단계이다.

여기서는 특별한게 없지만 이 예시는 `with_items` lists안에서 comment를 사용하여 list안의 item들을 명시해주는 것을 보여준다.
우리는 각 command들을 각각 따로 task로 만들 수 있지만 이렇게 한 이유는 총 Ansible task의 수를 줄여주고 `with_items` list를 필요시 external variable로 옮기기 위한 것이다.

```yaml
  - name: Ensure solr example directory is absent.
    file: 
      path: "{{ solr_dir }}/example"
      state: absent

  - name: Set up solr data directory
    file:
      path: "{{ solr_dir }}/data"
      state: directory
      owner: tomcat7
      group: tomcat7
```

최신 버전의 Apache Solr는 `{{ solr_dir }}` 폴더 내부를 모두 resursive하게 검색하여 potential search configuration을 로딩한다.
우리는 서버의 default search core를 사용하기 위해 example 중 하나를 복사하였기 때문에 Solr는 그 examplㄷ과 duplicate라고 알게되고 crash가 날 것이다.
따라서 우리는 `file` module에 `path`를 사용하여 example directory가 없도록 할 것이다(`state=absent`).

example directory를 지우고 나서(다음에 실행할 때에도 없어져 있어야 한다) 우리는 Solr가 index data를 저장할 data directory가 존재하고 `tomcat7` user와 group으로 owner를 설정되도록 해야한다.

```yaml
  - name: Configure solrconfig.xml for new data directory.
    lineinfile:
      dest: "{{ solr_dir }}/collection1/conf/solrconfig.xml"
      regexp: "^.*<dataDir.+%"
      line: "<dataDir>${solr.data.dir:{{ solr_dir }}/data}</dataDir>"
      state: present
```

앞에서 보았듯이 `lineinfile`은 idempotent하게 configuration file setting이 존재하는지 확인하는 데 유용한 module이다.
이 경우에 우리는 `<dataDir>` 줄이 우리 default search core의 configuration에 특정한 값으로 설정되어있는지 확인해야한다.

```yaml
  - name: Set permissions for solr home.
    file:
      path: "{{ solr_dir }}"
      recurse: yes
      owner: tomcat7
      group: tomcat7
```

`{{ solr_dir }}`의 전체 content에서 ownership option을 알맞게 설정하기 위해 우리는 `file` module을 `recurse` parameter를 `yes`로 설정하여 사용할 것이다.
이는 shell command에서의 `chown -R tomcat7:tomcat7 {{ solr_dir }}`과 동일하다.

```yaml
  - name: Add Catalina configuration for solr.
    template:
      src: templates/solr.xml.j2
      dest: /etc/tomcat7/Catalina/localhost/solr.xml
      owner: root
      group: tomcat7
      mode: 0644
    notify: restart tomcat
```

마지막 task는 template file (`solr.xml.j2`)를 remote host로 복사하고 Jinja2 문법으로 variable들을 대체한 뒤 file의 ownership과 permission을 Tomcat에 필요한 것으로 설정한다.

task가 실행되기 전에 local template file은 생성이 되어있어야 한다.
`templates` 폴더를 Apache Solr playbook의 디렉토리와 같은 곳에서 생성하고 다음의 내용으로 `solr.xml.j2`를 그 안에 생성한다.

```yaml
<?xml version="1.0" encoding="utf-8"?>
<Context docBase="{{ solr_dir }}/solr.war" debug="0" crossContext="true">
  <Environment name="solr/home" type="java.lang.String" value="{{ solr_dir }}" override="true"/>
</Context>
```

playbook을 `$ ansible-playbook [playbook-name.yml]`로 실행하고 몇분 후에(서버의 인터넷 환경에 따라 다르다) Solr admin interface로 `http://example.com:8080/solr`를 통해 접속할 수 있다(`example.com`이 우리 서버의 hostname이나 IP 주소로 바뀌어야 한다).

### Apache Solr server summary

Apache Solr를 deploy할 때 사용했던 configuration은 multicore setup을 할 수 있고 따라서 우리는 admin interface를 통해 'search cores'를 추가할 수 있다(디렉토리와 core schema configuration이 filesystem에 위치시킨다).
그리고 multiple website와 application을 위한 multiple indexes를 가질 수 있다.

위에서 보앗던 것과 유사한 playbook은 Drupal website에 대한 Apache Solr search core를 hosts하는 service인 infrastructure for Hosted Apache Solr의 일부로 사용되었다.

{{% notice notes %}}

전체 Apache Solr server playbook에 대한 예제는 이 책의 code repository인 <https://github.com/geerlingguy/ansible-for-devops>의 `solr` directory에서 확인 가능하다.

{{% /notice %}}

## Summary

이제 우리는 Ansible의 `modus operandi`에 친숙해지게 되었다.
Playbook은 Ansible의 configuration management와 provisioning 기능의 심장이고 동일한 module과 비슷한 syntax로 ad-hoc command를 사용하여 일반 서버 management에 deployment를 할 수 있다.

이제 playbook에 친숙해졌으니 task의 organization, condition, variable과 같은 playbook을 만드는 좀 더 깊숙한 개념들에 대해 알아볼 것이다.
나중에 우리는 role을 통한 playbook의 사용법을 배워 이를 무한정으로 유연하고 infrastructure를 configure하고 setting하는 데 드는 시간을 줄일 것이다.
