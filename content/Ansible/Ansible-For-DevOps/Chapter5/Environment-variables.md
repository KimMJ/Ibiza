---
title: "Environment Variables"
date:  2020-03-01T18:43:27+09:00
weight: 3
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

Ansible은 다양한 방법으로 environment variable을 사용할 수 있도록 해준다.
첫번째로 remote user account에 대해 어떤 environment variable을 설정하고자 한다면 remote user의 `.bash_profile`에 다음과 같이 추가하면 된다.

```yaml
- name: Add an environment variable to the remote user's shell
  lineinfile: dest=~/.bash_profile regexp=^ENV_VAR= line=ENV_VAR=value
```

그러면 다음에 실행되는 모든 task는 이 environment variable에 접근할 수 있다.
(물론 `shell` module만 environment variable을 사용하는 shell command를 이해할 것이다!)
environment variable을 나중 task에서 사용하려면 task의 `register` 옵션을 사용하여 environment variable을 variable에 저장하여 Ansible이 나중에 사용할 수 있도록 하는 것을 추천한다.
예를 들면 다음과 같다.

```yaml
- name: Add an environment variable to the remote user's shell.
  lineinfile: dest=~/.bash_profile regexp=^ENV_VAR= line=ENV_VAR=value

- name: Get the value of the environment variable we just added.
  shell: 'source ~/.bash_profile && echo $ENV_VAR'
  register: foo

- name: Print the value of the environment variable.
  debug: msg="The variable is {{ foo.stdout }}"
```

Ansible이 remote user의 최신 environment variable을 사용하고 있는지를 확실하게 하기 위해 우리는 4번째 줄에 있는 `source ~/.bash_profile`을 사용한다.
어떤 상황에서는 task가 $ENV_VAR가 아직 정의되지 않은, 계속해서 동작중인 세션이나 quasi-cached SSH session을 사용하기 때문이다.

(처음으로 `debug` module이 등장했다. 이는 나중에 다른 debugging techniques들과 함께 깊게 파볼 것이다.)

{{% notice notes %}}

왜 `~/.bash_profile`인가?
user의 home folder에는 `.bashrc`, `.profile`, `.bash_profile`같은 environment variable을 저장할 수 있는 많은 파일이 있다.
우리의 경우 environment variable이 pseudo-TTY shell session을 사용하는 Ansible에서 사용할 수 있기를 원하기 때문에 `.bash_profile`로 environment를 설정할 수 있다.
shell session configuration과 이 dotfiles에 대해서는 여기를 통해 더 알아볼 수 있다.
(Configuring your login sessions with dotfiles)[http://mywiki.wooledge.org/DotFiles]

{{% /notice %}}

Linux는 `/etc/environment`에 추가된 global environment variable도 읽기 때문에 그곳에 추가해도 된다.

```yaml
- name: Add a global environment variable.
  lineinfile: dest=/etc/environment regexp=^ENV_VAR= line=ENV_VAR=value
  sudo: yes
```

어떤 경우에던지 server에 있는 environment variable을 `lineinfile`로 관리하는 것은 꽤나 간단하다.
만약 어플리케이션이 많은 environment variable을 필요로 한다면(대다수의 Java application의 경우처럼) `lineinfile`로 많은 아이템의 리스트를 작성하는 것보다 `copy`나 `template`으로 local file을 사용하는 것을 고려해볼 수 있다.

## Per-play environment variables

또한 특정 play에 대해 `environment` 옵션을 사용하여 하나의 play에 대해서만 environment를 설정할 수 있다.
예를 들어, 특정한 파일을 다운로드하기 위해 http proxy 설정이 필요하다고 해보자.
이는 다음과 같이 할 수 있다.

```yaml
- name: Download a file, using example-proxy as a proxy.
  get_url: url=http://www.example.com/file.tar.gz dest=~/Downloads/
  environment:
    http_proxy: http://example-proxy:80/
```

트록시나 다른 environment variable을 필요로 하는 task가 많은 경우에 특히 성가실 수 있는 일이다.
이러한 경우 environment를 playbook의 `vars` 섹션에(또는 variable file을 include하여) variable을 통해 전달할 수 있다.

```yaml
vars:
  var_proxy:
    http_proxy: http://example-proxy:80/
    https_proxy: https://example-proxy:443/
    [etc...]

task:
- name: Download a file, using example-proxy as a proxy.
  get_url: url=http://www.example.com/file.tar.gz dest=~/Downloads/
  environment: var_proxy
```

proxy가 시스템 전반적으로 설정되어야 한다면(대다수의 기업 방화벽을 사용하는 경우) `/etc/environment` 파일에 설정하는 것을 선호하는 편이다.

```yaml
# In the 'vars' section of the playbook (set to 'absent' to disable proxy):
proxy_state: present

# In the 'tasks' section of the playbook:
- name: Configure the proxy.
  lineinfile:
    dest: /etc/environment
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    state: "{{ proxy_state }}"
  with_items:
    - { regexp: "^http_proxy=", line: "http_proxy=http://example-proxy:80/" }
    - { regexp: "^https_proxy=", line: "https_proxy=https://example-proxy:443/" }
    - { regexp:  "^ftp_proxy=", line: "ftp_proxy=http://examle-proxy:80/" }
```

이렇게 하는 방법은 proxy가 서버에서 enable 되어있더라도 설정할 수 있도록 하며 한번 play한 뒤 http, https, ftp proxy들을 설정한다.
이런 비슷한 방법으로 시스템 전역에 설정되어야 하는 environment variable들을 설정할 수 있다.

{{% notice notes %}}

remote environment variable들을 `ansible` command를 통해 테스트 할 수 있다.
(`ansible test -b shell -a 'echo $TEST'`)
이렇게 할 때 quotes를 통해 escape를 해야함에 주의를 해야한다.
double quotes나 single quotes를 사용할 수도 있다.
그렇지 않으면 remote server의 environment variable이 아닌 local server의 것을 출력할 수도 있다.

{{$ /notes $}}