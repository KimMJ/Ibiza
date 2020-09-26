---
title: "Includes"
date:  2020-03-13T12:10:01+09:00
weight: 2
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

우리는 챕터 4에서 `vars_files`를 사용하여 variable을 playbook에 적는 것이 아닌 분리된 `vars.yml`에 저장할 때 다른 파일들을 include하는 기본적인 방법을 이미 봤었다.

```yaml
- hosts: all
  
  vars_files:
  - vars.yml
```

task도 이와 비슷한 방법으로 include할 수 있다.
playbook에서의 `tasks: ` 섹션에서 `include` 지시자를 다음과 같이 작성한다.

```yaml
tasks:
  - include: included-playbook.yml
```

variable include file과 같이 task도 included file에서 flat list 형태로 있게 된다.
예를 들어 `included-playbook.yml`은 다음과 같을 수 있다.

```yaml
---
- name: Add profile info for user.
  copy:
    src: example_profile
    dest: "/home/{{ username }}/.profile"
    owner: "{{ username }}"
    group: "{{ username }}"
    mode: 0744

- name: Add private keys for user.
  copy:
    src: "{{ item.src }}"
    dest: "/home/.ssh/{{ item.dest }}"
    owner: "{{ username }}"
    group: "{{ username }}"
    mode: 0600
  with_items: ssh_private_keys

- name: Restart example service.
  service: name=example state=restarted
```

이 경우에 user account를 configure하고 몇몇 서비스를 재시작하기 때문에 파일을 `user-config.yml`이라고 이름지을 수 있다.
이제 여기 그리고 서버를 provision하거나 configure하는 다른 모든 playbook에서 특정 user account를 configure하고 싶다면 다음을 playbook의 `tasks` section에 추가하면 된다.

```yaml
- include: example-app-config.yml
```

우리는 이 파일에 정의된 `{{ username }}`과 `{{ ssh_private_keys}}` variable을 하드코딩된 value 대신에 사용하여 include file을 재사용 가능하도록 만들 것이다.
variable을 playbook 내에서 정의할수도 있고 include variable file을 통해서도 정의할 수 있지만 Ansible은 일반적은 YAML 문법으로 직접 include할 수 있도록 할 수도 있다.

```yaml
- { include: user-config.yml, username: johndoe, ssh_private_keys: [] }
- { include: user-config.yml, username: janedoe, ssh_private_keys: [] }
```

더 읽기 쉽게 하기 위해 구조화된 variable을 사용할수도 있다.

```yaml
- include: user-config.yml
  vars:
    username: johndoe
    ssh_private_keys:
      - { src: /path/to/johndoe/key1, dest: id_rsa }
      - { src: /path/to/johndoe/key2, dest: id_rsa2 }
- include: user-config.yml
  vars:
    username: janedoe
    ssh_private_keys:
      - { src: /path/to/janedoe/key1, dest: id_rsa }
      - { src: /path/to/janedoe/key2, dest: id_rsa2 }
```

Include file은 다른 file들도 include할 수 있어 다음과 같은것을 할 수 있다.

```yaml
tasks:
  - include: user-config.yml
```

`user-config.yml`안에서는 다음과 같이 작성한다.

```yaml
- include: ssh-setup.yml
```

## Handler includes

handler도 task처럼 playbook의 `handlers` 섹션 안에서 include 될 수 있다.
예를 들면 다음과 같다.

```yaml
handlers:
  - include: included-handlers.yml
```

handler는 서비스를 재시작하거나 configuration을 로딩하는 것과 같은데 사용되기 때문에 이는 main playbook의 노이즈를 줄여주는데 도움을 줄 것이고 playbook의 원래 목적에 맞게 파일을 분리해줄 것이다.

## Playbook includes

playbook은 최 상단에 `include` 문법을 사용하여 다른 playbook을 include 할 수 있다.
예를 들어 두개의 playbook을 가지고 있고 하나는 webserver에 대한 것(`web.yml`), 하나는 database server에 대한 것(`db.yml`)이라고 한다면 다음 playbook으로 동시에 실행할 수 있다.

```yaml
- hosts: all
  remote_user: root

  tasks:
    ...

- include: web.yml
- include: db.yml
```

이런 방법으로 playbook을 생성하여 infrastructure의 모든 서버를 configure할 수 있고 그러면 master playbook을 생성하여 각각의 개별 playbook을 include
infrastructure를 initialize하고 싶을 때, 전체 서버들에 대해 변경사항이 있을 때, configuration들이 playbook의 정의와 일치하는지 알고 싶을 때 `ansible-playbook` command를 실행하기만 하면 된다.

## Complete includes example

우리가 챕터 4에서 만들었던 137줄의 Drupal LAMP server playbook을 21줄로만 재구성할 수 있다고 한다면 어떨까?
include가 있다면 이는 쉽다.
단순히 간 task를 그 자체 파일로 만든 다음 main playbook을 다음과 같이 구성하기만 하면 된다.

```yaml
---
- hosts: all
  
  vars_files:
    - vars.yml
  
  pre_tasks:
    - name: Update apt cache if needed.
      apt: update_cache=yes cache_valid_time=3600

  handlers:
    - include: handlers/handlers.yml

  tasks:
    - include: tasks/common.yml
    - include: tasks/apache.yml
    - include: tasks/php.yml
    - include: tasks/mysql.yml
    - include: tasks/composer.yml
    - include: tasks/drush.yml
    - include: tasks/drupal.yml
```

해야할 일은 Drupal의 `playbook.yml` 파일과 같은 위치에서 `handlers`, `tasks` 폴더를 생성하고 각 섹션의 playbook을 그 안에서 생성하는 것이다.

예를 들어 `handlers/handlers.yml`의 내용은 다음과 같을 것이다.

```yaml
---
- name: restart apache
  service: name=apache2 state=restarted
```

`tasks/drush.yml`는 다음과 같을 것이다.

```yaml
---
- name: Check out drush master branch.
  git:
    repo: https://github.com/drush-ops/drush.git
    dest: /opt/drush

- name: Install Drush dependencies with Composer."
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

모든 task를 각각의 파일로 나누는 것은 playbook을 관리할 때 필요한 파일이 더 많아지는 것을 의미하지만 더 간결하게 main playbook을 유지할 수 있도록 해준다.
이는 playbook이 가지고 있는 installation과 configuration 단계를 보기에 더 쉽고 task를 유지보수할 수 있도록 묶을 수 있다.
각 23개의 분리된 task를 하나의 playbook에서 실행하는 것 대신 각 2개에서 5개의 task를 가진 8개의 분리된 파일을 유지보수하기만 하면 된다.

하나의 긴 playbook을 관리하는 것보다 관련된 task가 묶인 작은 단위를 관리하는 것이 더 쉽다.
하지만 처음부터 여러개의 개별 include로 playbook을 작성할 필요는 전혀 없다.
대부분은 자세한 setup과 configuration을 작업할 때 하나의 monolithic playbook을 가지고 있는게 가장 좋고 논리적인 그룹으로 각 include file을 나누는 것이 좋다.

또한 tag(이전 챕터에서 설명했다)를 사용하여 playbook이 특정 include file만 포함하여 실행되도록 할 수 있다.
위의 예시에서 보면 `drush` tag를 include된 drush file에 추가하고자 한다면(그렇게 해서 `ansible-playbook playbook.yml --tags=drush`로 실행하고자 한다면) 20번째 줄을 다음과 같이 수정하면 된다.

```yaml
- include: tasks/drush.yml tags=drush
```

{{% notice notes %}}

include file을 사용하는 전체 Drupal LAMP server playbook의 예시는 이 도서의 code repository인 <https://github.com/geerlingguy/ansible-for-devops>의 `includes` 디렉토리에서 볼 수 있다.

{{% /notice %}}

{{% notice warning %}}

variable을 task include file name으로 사용할 수 없다(`include_vars` 지시자에서 했던 것처럼, `include_vars: "{{ ansible_os_family }}.yml`을 task에 사용하는것, 또는 `vars_files`에서 사용하는것).
나중에 설명하게 될 다른 playbook structure나 role들을 사용하여 conditional task inclusion을 수행할 수 있는, conditional task include보다 더 좋은 방법이 있을 것이다.  

{{% /notice %}}
