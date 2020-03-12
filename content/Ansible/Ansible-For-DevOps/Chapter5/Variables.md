---
title: "Variables"
date:  2020-03-08T18:19:40+09:00
weight: 4
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

Ansible에서의 variable은 대부분의 다른 시스템에서의 variable과 비슷하다.
variable은 항상 글자로 시작하고`[A-Za-z]` 그 다음부터는 `_`나 숫자들 `[0-9]`를 포함할 수 있다.

사용가능한 variable name은 `foo`, `foo_bar`, `foo_bar_5`, `fooBar`을 포함하지만 표준은 모두 소준자를 사용하고 variable name에서 숫자를 제거하는 것이다(`camelCase`나 `UpperCamelCase`를 피한다).

사용불가능한 variable name은 `_foo`, `foo-bar`, `5-foo-bar`, `foo bar`가 있다.

inventory file에서 variable의 값은 equal sign으로 할당된다.

```toml
foo=bar
```

playbook이나 파일에 포함된 variable에서는 variable의 value가 colon을 통해 할당된다.

```yaml
foo: bar
```

## Playbook variables

task에서 사용할 variable을 정의하는 방법에는 여러가지가 있다.

variable은 `ansible-playbook`을 호출할 때 `--extra-vars` 옵션을 통해 command line을 통해서 전달될 수 있다.

```bash
ansible-playbook exampl.yml --extra-vars "foo=bar"
```

JSON, YAML에 quote를 씌워 extra variable을 전달하거나 JSON, YAML 파일을 직접 전달할 수도 있다.
`@even_more_vars.json`이나 `--extra-vars "@even_more_vars.yml`처럼 사용하면 된다.
하지만 여기서 아래에 적힌 다른 method를 사용하는 것도 좋을 수 있다.

variable은 `vars` section에서 playbook의 나머지 부분에 inline을 표함할 수 있다.

```yaml
---
- hosts: example
  vars:
    foo: bar
  tasks:
    # Prints "Variable 'foo' is set to bar".
    - debug: msg="Variable 'foo' is set to {{ foo }}"
```

variable은 또한 별도의 파일에 작성하고 `vars_files` section에서 포함하게 할 수도 있다.

```yaml
---
# Main playbook file.
- hosts: example
  vars_files:
    - vars.yml
  tasks:
    - debug: msg="Variable 'foo' is set to {{ foo }}"
```

```yaml
---
# Variables file 'vars.yml' in the same folder as the playbook.
foo: bar
```

모든 variable들이 YAML의 root level로 설정된 것을 인지해야 한다.
standalone file로 포함되는 상황에서는 `vars`같은 heading이 필요하지 않다.

variable 파일은 상황에 따라 import되게 할수도 있다.
예를 들어 CentOS server에 대한 variable 세트가 있을수 있고(Apache service가 `httpd`이다) Debian server에서는 다른 세트를 가질 수 있다(Apache service가 `apache2`이다).
이러한 경우 `vars_files`를 include할 때 조건을 사용할 수 있다.

```yaml
---
- hosts: example
  vars_files:
    - [ "apache_{{ ansible_os_family }}.yml", "apache_default.yml" ]
  tasks:
    - service: name={{ apache }} state=running
```

그러고 난 후 두 파일을 example playbook과 같은 디렉토리에 `apache_CentOS.yml`과 `apache_default.yml`로 저장한다.
CentOS 파일에서는 `apache: httpd`로 설정하고 default 파일에서는 `apache: apache2`로 설정한다.

remote server가 `facter`나 `ohai`가 설치되어 있는 한 Ansible은 server의 OS를 읽을 수 있게 되고 이를 variable로 변경(`ansible_os_family`)하여 resulting name을 가지고 vars file을 포함시킬 수 있다.
Ansible이 파일의 이름을 그 이름으로 찾지 못한다면 두번째 옵션(`apache_default.yml`)을 사용할 것이다.
따라서 Debian이나 Ubuntu server에서 Ansible은 `apache_Debian.yml`이나 `apache_Ubuntu.yml` 파일이 없더라도 `apache2`를 서비스 이름으로 사용할 수 있을 것이다.

## Inventory variables

variable은 Ansible inventory file의 host definition이 있는 줄이나 group에 대해 정의한 것을 통해서도 추가될 수 있다.

```toml
# Host-specific variables (defined inline).
[washington]
app1.example.com proxy_state=present
app2.example.com proxy_state=absent

# Variables defined for the entire group
[washington:vars]
cdn_host=washington.static.example.com
api_version=3.0.1
```

더 많은 variable을 정의하고자 한다면, 특히 한 두개 이상의 호스트에 variable을 적용하려고 한다면 inventory file을 사용하는 것은 성가신 일일 수 있다.
사실 Ansible의 documentation에서는 inventory에 variable을 저장하지 않는 것을 권장한다.
대신에 `group_vars`와 `host_vars` YAML variable file을 특정한 위치에 놓으면 Ansible이 이를 개별 호스트와 inventory에 정의된 group에 적용하게 된다.

예를 들어 `app1.example.com` 호스트에 variable 설정을 적용하려 한다면 `app1.example.com`이라는 이름으로 빈 파일을 생성하고 이를 `/etc/ansible/host_vars/app1.example.com`에 위치한뒤 `vars_files` YAML에 넣고싶은 variable을 추가하면 된다.

```yaml
foo: bar
baz: qux
```

variable들을 전체 `washington` group에 대해 적용하고 싶으면 `/etc/ansible/group_vars/washington`에 비슷한 파일을 생성하면 된다(`washington`은 사용하고싶은 group으로 변경하면 된다).

이 파일들을 같은 이름으로 playbook 디렉토리의 `host_vars`나 `group_vars` 디렉토리 안에 놓아도 된다.
Ansible은 `/etc/ansible/[host|group]_vars` 디렉토리에 있는 inventory에 정의된 variable을 먼저 사용한 뒤 playbook directory에 정의되어 있는 variable을 사용하게 될 것이다.

`host_vars`와 `group_vars`를 사용하는 것의 다른 대안책은 위에서 언급했듯이 conditional variable file을 사용하는 것이다.

## Registered Variables

command를 실행하고 나서 이 return code나 stderr, stdout을 가지고 다음 task를 진행할지 결정해야하는 상황이 많이 있을 것이다.
이러한 상황에서 Ansible은 `register`를 사용하여 runtime에 특정 command의 output을 variable로 저장하는 기능을 가지고 있다.

이전 챕터에서 `register`를 통해 `forever list` command의 ouput을 가지고 Node.js app을 시작해야하 하는지 결정할 때 사용했다.

```yaml
- name: "Node: Check list of Node.js apps running."
  command: forever list
  register: forever_list
  changed_when: false

- name: "Node: Start example Node.js app."
  command: forever start {{ node_apps_location }}/app/app.js
  when: "forever_list.stdout.find('{{ node_apps_location }}/app/app.js') == -1"
```

이 예시에서 우리는 Python에 내장된 string function(`find`)을 사용하여 app의 위치를 검색하고 존재하지 않을경우 Node.js app을 시작한다.

`register`에 대해서는 이번 챕터의 뒷부분에서 알아보도록 하자.

## Accessing Variables

간단한 variable(Ansible에 의해서 수집되는 inventory 파일 또는 playbook이나 variable file에 정의된 것들)은 `{{ variable }}`과 같은 문법을 사용하여 task 안에서 사용할 수 있다.
예를 들면 다음과 같다.

```yaml
- command: /opt/my-app/rebuild {{ my_environment }}
```

command가 동작하면 Ansible은 `my_environment`의 내용을 `{{ my_environment }}`로 대치할 것이다.
그러면 결과적으로 command는 `/opt/my-app/rebuild dev`처럼 될 것이다.

사용할만한 많은 variable들은 array(또는 리스트)로 구조화될 수 있고 `foo` array에 접근하는 것은 information에 대해 충분한 정보를 제공하지 않는다(Ansible이 `with_items`처럼 전체 array를 사용해야하는 상황을 제외하곤).

아래와 같이 variable의 리스트를 정의했다고 해보자.

```yaml
foo_list:
  - one
  - two
  - three
```

해당 array에 있는 첫번째 아이템에 다음과 같이 접근할 수 있다.

```yaml
foo[0]
foo|first
```

첫번째 줄은 Python에서 array에 접근하는 문법(array의 첫번째 element, 0번째 index를 불러오기)과 동일하지만 두번째 줄은 Jinja2가 제공하는 filter를 사용한 것이다.
둘 다 유효한 문법이며 유용하며 둘 중 하나를 고르는 것은 전적으로 사용자에게 달려있다.

더 크고 구조화된 array에 대해서(예를 들어 Ansible이 server에서 얻어온 서버의 IP 주소를 받아오는 것) 우리는 `[]`이나 `.`을 이용하여 어떤 array의 key에도 접근할 수가 있다.
예를 들어 `eth0` network interface에 대한 정보를 얻고싶으면 먼저 playbook의 `debug`를 이용하여 전체 array를 살펴보면 된다.

```yaml
#In your playbook.
task:
  - debug: var=ansible_eth0
```

```bash
TASK: [debug var=ansible_eth0] *****************************************
ok: [webserver] => {
  "ansible_eth0": {
    "active": true,
    "device": "eth0",
    "ipv4": {
    "address": "10.0.2.15",
    "netmask": "255.255.255.0",
    "network": "10.0.2.0"
  },
  "ipv6": [
    {
    "address": "fe80::a00:27ff:feb1:589a",
    "prefix": "64",
    "scope": "link"
    }
  ],
  "macaddress": "08:00:27:b1:58:9a",
  "module": "e1000",
  "mtu": 1500,
  "promisc": false,
  "type": "ether"
  }
}
```

이제 전반적인 variable에 대한 구조를 알게되었으니 다음의 테크닉을 통해 서버의 IPv4 주소만 얻어올 수 있다.

```jinja2
{{ ansible_eth0.ipv4.address }}
{{ ansible_eth0['ipv4']['address']}}
```

## Host and Group variables

Ansible은 host별, group별 variable들을 쉽게 정의하거나 override할 수 있다.
앞에서 배운 것처럼 inventory file은 group과 host를 다음과 같이 정의할 수 있다.

```toml
[group]
host1
host2
```

host별 또는 group별로 variable을 정의하는 가장 쉬운 방법은 inventory file 안에서 직접 할 수 있다.

```toml
[group]
host1 admin_user=jane
host2 admin_user=jack
host3

[group:vars]
admin_user=john
```

이 경우 Ansible은 default variable 'john'을 `{{ admin_user }}`에 대해 사용하지만 `host`과 `host2`의 경우 hostname 옆에 정의된 admin user를 사용하게 될 것이다.

이는 variable을 정의하거나 각 host별 또는 각 group별로 정의할 때 간편하고 잘 작동하지만 더 복잡한 playbook의 경우 host-specific한 variable을 몇가지(3+) 더 추가해야할 수도 있다.
이런 상황에서 유지보수와 가독성을 위해 다른 파일에 variable을 정의하는 것이 더 쉬울 것이다.

### `group_vars` and `host_vars`

Ansible은 inventory file(또는 `/etc/ansible/hosts`에 있는 default inventory file을 사용한다면 `/etc/ansible` 내부)과 같은 위치에서 `group_vars`와 `host_vars` 디렉토리를 검색할 것이다.

이 디렉토리 안에 inventory file에서 정의된 group name 또는 hostname을 따라 이름지어 YAML 파일을 저장하면 된다.
위의 예시에서 계속해서 이 specific variable들을 옮겨보도록 하자.

```yaml
---
# File: /etc/ansible/group_vars/group
admin_user: john
```

```yaml
# File: /etc/ansible/host_vars/host1
anmin_user: jane
```

default inventory file(또는 playbook의 root directory 바깥에 있는 inventory file)을 사용한다고 하더라도 Ansible은 playbook 안에 있는 `group_vars`와 `host_vars` 디렉토리 내부의 host, group variable file들도 사용한다.
이는 전체 playbook과 infrastructure configuration을 모든 host/group-specific configuration을 포함하는 source-control repository에 패키징할 때 편리하게 사용할 수 있다.

또한 `group_vars/all` 파일을 정의하여 `all` group에 대해 적용할 수 있고 또한 `host_vars/all` 파일을 통해 `all` host에 대해 적용할 수도 있다.
하지만 보통은 playbook과 role 안에 sane default를 정의하는 것이 더 좋다(나중에 더 이야기해보도록 한다).

### Magic variables with host and group variables and information

특정한 host의 variable을 다른 host에서 얻어오고자 한다면 Ansible은 magic `hostvars` variable을 제공하여 (inventory file과 `host_vars` 디렉토리에 있는 YAML file 들에서) 정의된 host variable들을 불러올 수 있다.

```yaml
# From any host, returns "jane".
{{ hostvars['host1']['admin_user'] }}
```

이것 외에도 때때로 사용할 수 있는 variable들을 Ansible이 제공해준다.

* `groups`: inventory 안에 있는 모든 group name의 list
* `group_names`: _current_ host가 속한 모든 그룹들의 리스트
* `inventory_hostname`: `inventory`에 따른 현재 host의 hostname(이는 system이 제공하는 hostname인 `ansible_hostname`과는 다른 값일 수 있다).
* `inventory_hostname_short`: `inventory_hostname`의 첫번째 부분.
* `play_hosts`: 현재 play가 실행될 모든 host

Ansible의 official documentation에서 [Magic Variables, and How To Access Information About Other Hosts](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#magic-variables-and-how-to-access-information-about-other-hosts)를 참조하여 최신 정보와 사례를 확인해 보아라.

### Facts (Variables derived from system information)

default로 Ansible playbook을 실행할 때마다 Ansible은 play를 하는 각 host의 information(`facts`)을 수집한다.
이전 chapter에서 playbook을 실행할 때마다 다음과 같은 것을 보았을 것이다.

```bash
$ ansible-playboook playbook.yml

PLAY [group] **********************************************************

GATHERING FACTS *******************************************************
ok: [host1]
ok: [host2]
ok: [host3]
```

Fact는 playbook을 실행할 때 매우 유용하다.
우리는 특정 task를 수행할 때 또는 configuration file안의 특정 정보를 수정하기 위해 host IP address나 CPU type, disk space, OS information, network interface information같은 정보를 수집할 수 있다.

사용할 수 있는 모든 fact에 대한 list를 얻으려면 `ansible` command에 `setup` module을 더해 사용하면 된다.

```bash
$ ansible munin -b setup
munin.midwesternmac.com | success >> {
  "ansible_facts": {
    "ansible_all_ipv4_addresses": [
      "167.88.120.81"
    ],
  "ansible_all_ipv6_addresses":
    "2604:180::a302:9076",
[...]
```

fact를 사용할 필요가 없고 playbook을 실행할 때 조금의 시간이라도 단축하고 싶으면(수십, 수백개의 서버에 대해 Ansible playbook을 돌릴 때 유용할 것이다) playbook에서 `gather_facts: no`를 설정하면 된다.

```yaml
- hosts: db
  gather_facts: no
```

저자가 사용하는 많은 playbook과 role은 `ansible_os_family`, `ansible_hostname`, `ansible_memtotal_mb`와 같은 fact를 사용하여 새로운 variable을 등록하거나 `when`과 함께 사용하여 특정한 task를 실행하도록 조건문을 걸어준다.

{{% notice notes %}}

Factor나 Ohai가 remote host에 설치되어 있다면 Ansible은 여기서 수집된 fact 또한 `facter_`와 `ohai_` prefix를 통해 각각 include할 수 있다.
Ansible을 Puppet이나 Chef와 함께 사용할 경우 이러한 system-information-gathering tool에 대해 이미 친숙할 것이고 Ansible에서도 편하게 이것들을 사용할 수 있을 것이다.
그렇지 않다면 Ansible의 Fact는 어떤 것을 하던지 충분할 것이고 Local Facts를 통해 더 유연하게도 할 수 있다.

{{% /notice %}}

{{% notice notes %}}

playbook을 비슷한 서버나 VM(예를 들어 모든 서버가 동일한 OS에서 실행하고 동일한 hosting provider인 경우)에서 실행한다면 fact는 거의 동일할 것이다.
playbook을 다양한 set의 host(예를 들어 다른 OS들, 다른 virtualization stack, hosting provider일 경우)에 대해서 실행할 때 몇몇 fact는 예상하는 것과는 다른 information을 포함할 수 있다.
Server Check.in에서 5개보다 많은 hosting provider, 다양한 hardware를 가진 server를 보유하고 있어 특히 새로운 서버를 추가할 때 `ansible-playbook`의 결과들을 모니터해야 한다.

{{% /notice %}}

### Local Facts (Facts.d)

host-specific fact를 정의하는 다른 방법은 `.fact` file을 remote host의 특정한 디렉토리, `/etc/ansible/facts.d/`에 넣는 것이다.
이 파일들은 JSON이나 INI 파일이 될 수 있고 또는 JSON을 리턴하는 실행파일을 사용할수도 있다.
예를 들어 `/etc/ansible/facts.d/settings.fact`를 remote host에 생성하고 다음의 내용을 작성한다.

```toml
[users]
admin=jane,john
normal=jim
```

그 다음 Ansible의 `setup` module을 사용하여 remote host에서 새로운 fact를 표시한다.

```bash
$ ansible hostname -m setup -a "filter=ansible_local"
munin.midwesternmac.com | success >> {
  "ansible_facts": {
    "ansible_local": {
      "settings": {
        "users": {
          "admin": "jane,john",
          "normal": "jim"
        }
      }
    }
  },
  "changed": false
}
```

playbook을 사용하여 새로운 서버를 provision 하고, playbook 안에서 나중에 사용할 local fact를 생성하는 `.fact` file을 추가한다면 Ansible에게 다음과 같이 local fact를 불러오라고 명시적으로 알려주어야 한다.

```yaml
- name: Reload local facts.
  setup: filter=ansible_local
```

{{% notice warning %}}

`host_vars`나 다른 variable definition 방법에 비해 local fact를 사용하는 것을 권장하긴 하지만 playbook이 각 host의 특정한 detail에 대해 의존하지 않도록 만드는 것이 훨씬 더 좋다.
때로 반드시 local fact(특히 facts.d에 있는 실행파일을 사용하여 local environment을 기반으로 fact를 정의하는 경우)를 사용해야 하지만 언제나 configuration을 중앙 repository에 두는 것이 더 좋은 방법이고 host-specific fact로부터 벗어나야 한다.

{{% /notice %}}

{{% notice warning %}}

`setup` module 옵션(`filter` 처럼)은 Windows host에 대해서는 사용할 수 없다는 것에 주의하라.

{{% /notice %}}

## Variable Precedence

5개의 다른 place에서 동일한 variable을 정의하였을 때어떤 variable이 사용되고 있는지에 대한 자세한 사항을 파고드는 경우는 드물 것이다.
그러나 만일을 대비하여 Ansible documentation에서는 다음과 같은 순서를 사용한다.


1. command line을 통해 전달된 variable(`-e` option)이 항상 승리한다.
2. inventory에 정의된 variable connection (`ansible_ssh_user` 등)
3. 대부분의 모든 것 (command line switch, play에 정의된 variable, 내장된 variable, role variable 등)
4. 나머지(non-connection) inventory variable들
5. local fact와 자동으로 발견된 fact들 (`gather_facts`를 통해)
6. Role의 default variable (role의 `defaults/main.yml` 파일에 있는 것)

playbook, role을 만들고 inventory를 관리를 많이 하게되면 우리가 원하는 variable definition의 알맞은 조합을 찾게 될것이지만 play별, host별, run별로 variable을 setting하고 overriding하는데 드는 고통을 줄이기 위한 몇가지 사항들이 있다.

* Role(다음 챕터에서 이야기 해보도록 하자)은 role의 `default` variable을 통해 sane default를 제공해야 한다.
  이 variable들은 어디에도 variable이 정의되지 않았을 때 사용될 것이다.
* playbook은 variable을 거의 정의하면 안된다(예를 들어 `set_facts`를 통해).
  그 대신에 variable은 `vars_files`를 include 하거나 또는 inventory를 통해 사용되어야 한다.
* 오직 신뢰할 수 있는 host_specific 또는 group-specific variable들만 host나 group inventory에 정의되어야 한다.
* dynamic, static inventory source는 특정 playbook을 유지보수하는 데 잘 확인하지 않는 상황에서 특히 최소한의 variable을 포함해야 한다.
* command line variable(`-e`)는 반드시 가능한한 피해야한다.
  이걸 주로 사용하는 하나의 예는 실행하는 task의 유지보수성이나 idempotence를 걱정할 필요가 없는 local testing이나 one-off playbook을 실행하는 것이다.

Ansible의 [Variable Precedence](http://docs.ansible.com/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable) documentation을 통해 더 자세한 사항과 예시를 확인하라.
