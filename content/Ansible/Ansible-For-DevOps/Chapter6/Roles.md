---
title: "Roles"
date:  2020-03-15T20:54:04+09:00
weight: 3
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

다른 playbook 안에있는 playbook을 include하는 것은 우리의 playbook 구조를 더 알맞게 해주지만 playbook 안에서 전체 infrastructure의 configuration을 감싸기 시작하면 Russian nesting dolls와 같은 형태가 되어버릴 것이다.

좀 더 나은 방법으로 관련된 configuration들을 함께 패키징하는 방법은 없을까?
추가적으로 이 패키지를 사용하면서 좀 더 유연하게 만들어 우리 infrastructure 전체에 동일한 패키지를 사용하지만 개별 서버와 서버 그룹마다 약간씩 다른 설정을 줄 수 있을까?

Ansible Role이 이것을 할 수 있도록 해준다.

어떻게 Ansible role이 roles를 사용하여 챕터 4에서 사용했던 playbook 예시를 좀 더 유연한 구조로 만드는지 알아보도록 하자.

## Role scaffolding

role 안에서 명시적으로 특정 파일과 playbook을 include해 주어야 하지 않고 Ansible은 `main.yml` 파일을 특정 위치에 가지고 있는 디렉토리들을 자동으로 role을 만들 때 사용할 수 있도록 한다.

Ansible role을 사용할 때는 두가지 directory가 필요하다.

```plain-text
role_name/
  meta/
  tasks/
```

위에서와 같이 디렉토리 구조를 가져가고 각 디렉토리 안에 `main.yml`파일을 가지고 있다면 Ansible은 다음과 같은 문법으로 우리의 playbook 안에서 role을 호출했을 때 `task/main.yml`에 정의된 모든 task들을 실행할 것이다.

```yaml
---
- hosts: all
  roles:
    - role_name
```

우리의 role은 두개의 다른 위치에 있어도 된다.
하나는 global Ansible role path(`/etc/ansible/ansible.cfg`에서 설정 가능하다)이고 다른 하나는 main playbook 파일이 있는 폴더와 같은곳에 위치한 `roles` 폴더이다.

{{% notice notes %}}

role에 대한 scaffolding을 구축하는 다른 간편한 방법은 command를 이용하는 것이다(`ansible-galaxy init role_name`).
이 명령어를 실행시키면 example role이 현재 working directory 안에 생기는데 이를 필요에 따라 수정하면 된다.
`init` command를 사용하면 role이 언젠가 Ansible Galaxy에 role을 제출할 때 구조적으로 정확하다는 것을 확실히 해주기도 한다.

{{% /notice %}}

## Building your first role

챕터 4의 Node.js server 예시를 정리해보자면 configuration 중에서 가장 주된 파트는 Node.js를 설치하고 필요한 npm module들을 설치하는 것이다.

챕터 4에서의 첫번째 예시처럼 main `playbook.yml` 파일과 같은 디렉토리에 `roles` 폴더를 생성한다.
`roles` 폴더 안에서 `nodejs` 폴더를 생성한다(이는 role의 이름이 된다).
`nodejs` role 디렉토리 안에 `meta`와 `tasks` 폴더를 생성한다.

`meta` 폴더 안에 간단한 `main.yml`를 생성하고 다음의 내용을 작성한다.

```yaml
---
dependencies: []
```

role에 대한 meta information은 이 파일에서 정의된다.
기본 예시와 간단한 role에서 우리는 단순히 필요한 role dependency들(현재 role이 실행되기 전에 먼저 동작되어야 하는 다른 role들)을 모두 나열할 것이다.
아 파일에 Ansible과 Ansible Galaxy에 대한 role을 정의할 수 있지만 이 meta information에 대해서는 나중에 더 깊게 알아보도록 할 것이다.
이제 파일을 저장하고 `tasks` 폴더로 넘어가보자.

`main.yml` 파일을 이 폴더안에 생성하고 다음의 내용을 작성한다(기본적으로 챕터 4 예시에서 configuration을 복사 붙여넣기 했다).

```yaml
---
- name: Install Node.js (npm plus all its dependencies).
  yum: name=npm state=present enablerepo=epel

- name: Install forever module (to run our Node.js app).
  npm: name=forever global=yes state=latest
```

Node.js 디렉토리 구조는 다음과 같아야 한다.

```plain
nodejs-app/
  app/
    app.js
    package.json
  playbook.yml
  roles/
    nodejs/
      meta/
        main.yml
      tasks/
        main.yml
```

이제 node.js server configuration에 대한 playbook에서 사용할 Ansible role 작성을 마쳤다.
node.js app 설치하는 줄을 `playbok.yml`에서 삭제하고 playbook을 재구성하여 다른 task들이 먼저 실행되고(`tasks:` 대신 `pre_tasks:` 섹션으로) role이 실행된 후 나머지 task(`tasks:` 섹션)가 실행되도록 해보자.
다음과 같을 것이다.

```yaml
pre_tasks:
  # EPEL/GPG setup, firewall configuration...

roles:
  - nodejs

tasks:
  # Node.js app deployment tasks...
```

{{% notice notes %}}

이 playbook에서의 전체 예시는 [ansible-for-devops code repository](https://github.com/geerlingguy/ansible-for-devops/blob/master/nodejs-role/)에서 확인할 수 있다.

{{% /notice %}}

main playbook을 재구성했다면 `ansible-playbook`일 실행했을 때 `nodejs` role의 task들이 `nodejs | [Task name here]`의 prefix를 가지는 것을 빼고 모든것은 동일하게 동작할 것이다.

playbook을 실행하는 동안 보여지는 추가적인 데이터는 자동적으로 task가 속한 role의 prefix를 기입하기 때문에 task의 `name` value의 일부분으로 description을 추가할 필요가 없다.

우리의 role은 지금까진 유용하지 않지만 여전히 한가지 일을 하고 있고 다른 node.js module이 설치되어야 하는 다른 서버에 적용할 수 있을만큼 충분히 유연하지도 못하다.

## More flexibility with role vars and defaults

role을 더 유연하게 만들기 위해 하드코딩된 value 대신 npm module의 리스트를 사용할 수 있고 그렇게 되면 role을 사용하는 playbook은 role의 default list를 override하는 자신만의 module list variable을 제공하면 된다.

role의 task를 실행할 때 Ansible은 role의 `vars/main.yml` 파일과 `defaults/main.yml`에 정의된 variable(둘간의 차이점은 나중에 알아보자)을 가지고 오지만 playbook에서 default나 다른 role이 제공하는 variable을 필요시 override할 수 있다.

`tasks/main.yml` 파일을 list variable을 사용하고 이 리스트를 순회하며 playbook이 필요한 만큼 패키지를 설치하도록 수정해보자.


```yaml
---
- name: Install Node.js (npm plus all its dependencies).
  yum: name=npm state=present enablerepo=epel

- name: Install npm modules required by our app.
  npm: name={{ item }} global=yes state=latest
  with_items: node_npm_modules
```

`defaults/main.yml`에 default `node_npm_modules` variable을 작성해보자

```yaml
---
node_npm_modules:
  - forever
```

이제 playbook을 이와같이 실행하면 여전히 `forever` module을 설치하는 동일한 동작을 할 것이다.
하지만 role이 더 유연해지려면 새로운 playbook을 우리것과 같이 생성한 다음 default를 다음과 같이 override해야 한다(`vasr` 섹션이나 `vars_files`를 통해 include되는 파일을 통해).

```yaml
node_npm_modules:
  - forever
  - async
  - request
```

playbook을 이 custom variable을 통해 실행하면(`nodejs` role에서는 아무것도 변경하지 않았다) 위의 세가지 npm module이 설치도리 것이다.

이제 얼마나 강력한지 슬슬 알게될 것이다.

playbook 구조를 다음과 같이 했다고 해보자.

```yaml
---
- hosts: appservers
  roles:
    - yum-repo-setup
    - firewall
    - nodejs
    - app-deploy
```

각 role들은 각자 분리된 세계에 있지만 우리의 infrastructure에서의 server와 group들을 공유할 수 있다.

* `yum-repo-setup` role은 GPG key를 import하는 특정 repository에서 사용할 수 있다.
* `firewall` role은 각 서버마다 또는 각 inventory group마다의 서비스가 허용 또는 거부하는 포트를 지정할 수 있다.
* `app-deploy` role은 우리의 app을 디렉토리에 deploy하고 특정한 app option을 서버마다 또는 그룹마다 설정할 수 있다.

작은 기능을 분리된 role로 나누었을 때 관리하기가 쉬워진다.
100줄이 넘는 playbook task를 관리하는것 대신 `name:`에 모두 `Common |` 또는 `App Deploy |`로 prefix를 달아서 각 YAML에 10~20줄이 있는 몇가지 role을 관리하게 된다.

가장 좋은 점은 main playbook을 구성할 때 매우 간단해져서 특정 서버에 configure되고 deploy되는 모든 것들을 include된 playbook 파일들과 수백개의 task를 스크롤릴 하는 대신 한번에 알아볼 수 있게 된다.

{{% notice notes %}}

**Variable precedence**:
Ansible이 `defaults`에 include된 파일에 있는 variable을 `vars`에 있는것보다 낮은 우선순위로 다룬다는 것을 명심해라.
hosts/playbook에서 쉽게 override될 수 있는 특정한 variable이 필요하다면 `defaults`에 추가해주어야 한다.
role 내에서 항상 정의가 되어야 하는 value를 가진 common variable을 사용한다면 `vars` 안에 넣어라.
더 자세한 variable precedence에 대해서는 이전 챕터에서의 "Variable Precedence" 섹션을 확인해보아라.

{{% /notice %}}

## Other role parts: handlers, files, and templates

### Handlers

이전 예제중 하나에서 우리는 handler(`notify` 옵션을 통해 playbook task가 결과적을 변경사항이 있는 경우 호출할 수 있는 task)에 대해 소개했었고 Apache를 재시작하는 handler의 예시는 다음과 같았다.

```yaml
handlers:
  - name: restart apache
    service: name=apache2 state=restarted
```

Ansible role에서 handler는 task, variable, 다른 configuration과 같이 일급 객체이다.
handler를 role의 `handlers` 디렉토리에서 `main.yml` 파일에 직접 넣을 수 있다.
Apache configuration에 대한 role을 가지고 있다면 `handlers/main.yml` 파일은 다음과 같을 것이다.

```yaml
---
- name: restart apache
  command: service apache2 restart
```

role의 handlers 폴더에 정의된 handler를 playbook안에서 직접 include된 것처럼 호출할 수 있다(e.g. `notify: restart apache`).

## Files and Templates

다음의 예시에서 우리의 role에서 `files`와 `templates` 디렉토리의 파일들이 다음과 같은 구조를 가지고 있다고 가정해보자.

```plain
roles/
  example/
    files/
      example.conf
    meta/
      main.yml
    templates/
      example.xml.j2
    tasks/
      main.yml
```

파일을 직접 서버에 복사하고 role의 `files` 디렉토리 안에서 filename이나 full path를 다음과 같이 추가한다면:

```yaml
- name: Copy configuration file to server directly.
  copy: >
    src=example.conf
    dest=/etc/myapp/example.conf
    mode=644
```

이와 비슷하게 template을 지정할 때 filename이나 full path를 role의 templates 폴더로 추가한다.

```yaml
- name: Copy configuration file to server using a template.
  template: >
    src=example.xml.j2
    dest=/etc/myapp/example.xml
    mode=644
```

`copy` 모듈은 module의 `files` folder에 있는 파일을 복사하고 `template` module은 주어진 template file을 Jinja2 templating engine을 통해 실행한 뒤 서버에 파일을 복사하기 전에 playbook에서 사용할 수 있는 variable들을 merging한다.

### Organizing more complex and cross-platform roles

