---
title: "if/then/when - Conditionals"
date:  2020-03-12T10:15:33+09:00
weight: 5
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

많은 task가 특정한 상황에서만 동작해야 하는 조건을 가지고 있다.
몇몇 task는 idempotence가 내장된 module(yum이나 apt 패키지가 설치되어 있는 경우)을 사용하고 우리는 보통 이 task에 대해 추가적인 행동을 정의할 필요가 없다.

하지만 많은 task에서 - 특히 Ansible의 `command`나 `shell` module을 사용하는 경우 - 이 module이 실행되고 나서 변화가 있는지 없는지에 따라 또는 실행했을때 실패되었던 경우, 언제 실행될지를 결정하는 추가적인 input을 필요로 하게 된다.

우리는 이런 모든 주된 conditional behavior를 Ansible task에 적용할 수 있도록 할 것이고 또한 Ansible에게 언제 play가 끝나는지 또는 실패하는지를 알려줄수도 있다.

## Jinja2 Expressions, Python built-ins, and Logic

Ansible에서의 conditional에 대해서 이야기하기 전에 Jinja2(Ansible이 template과 conditional 모두에서 사용하는 문법), Python function(보통 `built-ins`라고 불린다)의 일부분에 대해서 짚고 넘어가는 것이 좋을 것이다.
Ansible은 `when`, `changed_when`, `failed_when`과 함께 expressions와 built-ins를 사용하여 Ansible에게 가능한한 정확하게 설명할 수 있다.

Jinja2는 string(`string`), integer(`42`), float(`42.33`), list(`[1, 2, 3]`), tuple(list와 비슷하지만 수정할 수 없는 것), dictionary(`{key: value, key2: value2}`), boolean(`true`, `false`)과 같은 literal의 정의를 허용한다.

Jinja2는 또한 기본적인 사칙연산과 비교(`==`는 일치, `!=`는 불일치, `>=`는 이상)를 허용한다.
logical operator는 `and`, `or`, `not`이 있고 괄호를 통해 그룹을 지을 수 있다.

어느 프로그래밍 언어라도 친숙한 것이 있다면 Jinja2 expression의 기본적인 사용법은 금방 배울 수 있을 것이다.

예를 들면 다음과 같다.

```jinja2
# The following expressions evaluate to 'true':
1 in [1, 2, 3]
'see' in 'Can you see me?'
foo != bar
(1 < 2) and ('a' not in 'best')

# The following expressions evaluate to 'false':
4 in [1, 2, 3]
foo == bar
(foo != foo) or (a in [1, 2, 3])
```

또한 Jinja2는 주어진 오브젝트에 대해서 테스트할 수 있는 `tests` 세트를 제공한다.
예를 들어 `foo` variable을 특정한 서버의 그룹에서만 정의했다면 `foo is defined`를 conditional로 사용하여 variable이 정의가 되었을 경우 `true`를, 아니면 `false`를 리턴하게 할 수 있다.

또한 `undefined`(`defined`의 반대), `equalto`(`==`와 비슷하게 동작하는 것), `even`(짝수일 경우 `true`를 리턴), `iterable`(오브젝트를 iterate할 수 있을 경우 `true`)과 같은 다른 체크들도 할 수 있다.
이 영역에 대해서는 이 책의 뒷부분에서 다룰 것이지만 지금은 Ansible conditional을 Jinja2 expression을 통해 많은 것을 할 수 있다는 것만 알면 된다.

Jinja2를 활용해서 해결할 수 없는 문제의 경우 Python의 built-in library function들(`string.split`, `[number].is_signed()`같은 것들)을 사용하여 variable을 조작하고 task가 실행할지 말지, 결과를 change로 할지 failed로 할지 등에 대해 결정할 수 있다.

예를 들면 때때로 version string을 파싱하여 특정 프로젝트의 major version을 찾아내야하는 경우가 있다.
`software_version`이 4.6.1로 설정되어있다고 가정하면 major version을 `.`으로 split 한 다음 array에서 첫번째 element를 사용하면 된다.
major version이 `4`인 경우를 확인하기 위해 `when`을 사용하고 특정한 task를 실행하도록(또는 실행하지 않도록) 설정한다.

```yaml
- name: Do something only for version 4 of the software.
  [task here]
  when: software_version.split('.')[0] == '4'
```

Jinja2 filter와 variable만 사용하는 것이 일반적으로는 가장 좋지만 좀 더 variable을 조작하기 위해서는 Python을 이용하는 것도 나쁘지 않다.

### `register`

Ansible에서 어느 play든 variable을 `register`할 수 있고 한번 register 하고 나면 그 variable은 뒤의 모든 task에서 사용할 수 있게 된다.
register된 variable은 일반적인 variable이나 host fact처럼 사용할 수 있다.

많은 경우에 우리는 shell command의 ouput(stdout 또는 stderr)를 필요로 하고 이를 다음과 같은 syntax를 통해 variable에 넣을 수 있다.

```yaml
- shell: my_command_here
  register: my_command_result
```

후에 우리는 stdout(string으로)을 `my_command_result.stdout`을 통해 접근할 수 있고 stderr를 `my_command_result.stderr`를 통해 접근할 수 있다.

registered fact는 많은 종류의 task에서 유용하게 사용되며 conditional(play가 실행되는 when과 how를 정의한 것)과 play의 어느 부분에서도 사용할 수 있다.
예를 들어 command가 `10.0.4`와 같은 version number string을 출력하고 이를 `version`으로 output을 register한다면 나중에 `{{ version.stdout }}`처럼 variable을 출력하여 체크해볼 수 있다.

{{% notice notes %}}

특정 registered variable에 대한 다른 속성들을 보고싶다면 playbook을 `-v` 옵션을 통해 실항하면 play ouput을 확인할 수 있다.
보통 `changed`(play의 결과가 변경되었을 경우), `delta`(play를 실행하는데 걸린 시간), `stderr`, `stdout`과 같은 value에 접근할 수 있다.
몇몇 Ansible module(`stat`과 같은)들은 registered variable보다 더 많은 정보를 가지고 있기 때문에 `-v`를 통해 그 안에 무엇이 있는지 확인하는 것이 좋다.

{{% /notice %}}

### `when`

play에 추가할 수 있는 유용한 extra key중 하나는 `when` statement이다.
간단한 `when`의 사례를 보도록 하자.

```yaml
- yum: name=mysql-server state=present
  when: is_db_server
```

위의 statement는 `is_db_server` variable을 앞에서 boolean(`true`, `false`)으로 정의했다고 가정하고 value가 `true`이면 실행하고 `false`이면 건너뛰도록 한다.

`is_db_server` variable을 database server에서만 정의했을 경우(variable이 아예 정의되지 않을 수도 있는 경우를 의미한다) 다음과 같이 task에 조건을 걸 수 있다.

```yaml
- yum: name=mysql-server state=present
  when: (is_db_server is defined) and is_db_server
```

`when`은 variable이 이전 task에서 등록이 됐는지 확인하는 절차를 함께 넣으면 더욱 강력하다.
예를 들어 실행중인 어플리케이션의 상태를 체크하기 원하고 그 어플리케이션이 `ready` output을 보고했을 때만 play를 실행하고 싶은 경우가 있다.

```yaml
- command: my-app --status
  register: myapp_result

- command: do-something-to-my-app
  when: "'ready' in myapp_result.stdout"
```

이 예시는 약간 부자연스럽긴 하지만 `when`이 task에서 보통 어떻게 쓰이는지에 대해서는 잘 묘사해주고 있다.
`when`을 실제 playbook에서 어떻게 사용하는지 예시를 확인해보자.

```yaml
# From our Node.js playbook - register a command's output, then see
# if the path to our app is in the output. Start the app if it's
# not present
- command: forever list
  register: forever_list
- command: forever start /path/to/app/app.js
  when: "forever_list.stdout.find('/path/to/app/app.js') == -1"

# Run 'ping-hosts.sh' script if 'ping_hosts' variable is true.
- command: /usr/local/bin/ping-hosts.sh
  when: ping_hosts

# Run 'git-cleanup.sh' script if a branch we're interested in is
# missing from git's list of branches in our project.
- command: chdir=/path/to/project git branch
  register: git_branches
- command: /path/to/project/scripts/git-cleanup.sh
  when: "(is_app_server == true) and ('interesting-branch' not in git_branches.stdout)"

# Downgrade PHP version if the current version contains '7.0'.
- shell: php --version
  register: php_version
- shell: yum -y downgrade php*
  when: "'7.0' in php_version.stdout"

# Copy a file to the remote server if the hosts file doesn't exist.
- stat: path=/etc/hosts
  register: hosts_file
- copy: src=path/to/local/file dest=/path/to/remote/file
  when: hosts_file.stat.exists == false
```

### `changed_when` and `failed_when`

`when`처럼 `changed_when`과 `failed_when`을 사용하여 특정 task가 changes 또는 failures일 경우 Ansible의 reporting에 영향을 줄 수 있다.

Ansible이 주어진 command의 결과가 change인지 확인하는 것은 어렵기 때문에 `comand`나 `shell` module을 `changed_when` 사용하지 않고 사용하고자 한다면 Ansible은 항상 change를 report할 것이다.
대부분의 Ansible module은 result가 올바르게 changes로 되던 안되던 report를 하지만 이 동작을 `changed_when`을 통해서 override할 수도 있다.

PHP Composer를 command로 사용하여 project dependency들을 설치할 때 Composer가 어떤것을 설치했는지 또는 언제부터 변경사항이 없는지를 알 때 유용하다.
다음은 이에 대한 예시이다.

```yaml
- name: Install dependencies via Composer.
  command: "/usr/local/bin/composer global require phpunit/phpunit --prefer-dist"
  register: composer
  changed_when: "'Nothing to install or update' not in composer.stdout"
```

`register`를 사용하여 command의 result를 저장한 것을 볼 수 있고 그 다음 특정 string이 registered variable의 stdout에 있는지를 확인한다.
Composer가 아무것도 안하면 `Nothing to install or update`를 출력할 것이고 우리는 그 string을 사용하여 Ansible에게 그 task가 change인지를 알려준다.

많은 command-line ultility가 stdout 대신 stderr를 프린트하기 때문에 `failed_when`은 Ansible에게 언제 task가 _실제로_ failed되었는지, 그리고 이를 잘못된 방향으로 report하지 않도록 알려줄 수 있다.
다음은 Jenkins CLI command의 stderr를 파싱하여 Jenkins에서 실제로 우리가 요청한 command의 수행이 실패했는지를 확인해볼 수 있는 예시이다.

```yaml
- name: Import a Jenkins job via CLI.
  shell: >
    java -jar /opt/jenkins-cli.jar -s http://localhost:8080/
    create-job "My Job" < /usr/local/my-job.xml
  register: import
  failed_when: "import.stderr and 'already exists' not in import.stderr"
```

이 경우 우리는 command가 error를 리턴했을 때와 error가 `already exists`를 포함하지 않을 때에만 Ansible이 failure를 report하도록 하고 싶다.
command가 job이 이미 존재하는 것을 stderr로 report하는지 아니면 그냥 stdout으로 report하는지에 대해서는 논란의 소지가 많지만 command가 Ansible에 어떤것을 하는지는 설명하기가 쉽다.

### `ignore_errors`

때로 항상 실행되어야 하는 명령어가 있고 이 명령어들이 대부분 error를 발생한다.
또는 실행하는 스크립트에서 error가 에러를 곳곳에서 발생시키고 에러가 사실상 문제점을 나타내는 것이 아지만 짜증나게 하는 경우(그래서 결국 playbook이 실행을 멈추게 되는 경우)가 있다.

이런 상황에서 `ignore_errors`를 task에 추가하며 Ansible은 특정 task를 실행하는 데 어떤 문제도 알아차리지 못할 것이다.
그러나 이를 사용하는 것은 항상 조심해야 한다.
task에서 에러가 발생하느 경우 playbook이 실제로 문제점을 나타낸다면 fail을 하도록 하고 아닌 경우에도 동작할 수 있는 방법을 찾는것이 가장 좋다.
