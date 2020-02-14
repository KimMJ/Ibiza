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
     이 때 `{ var1: value, var2: value }`