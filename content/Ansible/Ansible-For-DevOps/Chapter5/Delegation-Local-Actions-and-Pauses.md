---
title: "Delegation Local Actions and Pauses"
date:  2020-03-12T13:32:45+09:00
weight: 6
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

notification을 보내는 것, load balancer와 통신하는것 또는 DNS, 네트워킹에 변화를 주는것, 서버를 모니터링하는 것과 같은 몇몇 task는 Ansible이 host machine(playbook을 실행하는)에서 동작하거나 playbook에 의해 관리되지 않는 host에서 실행할 필요가 있다.
Ansible은 `delegate_to`를 사용한 특정 host에 task를 delegate할 수 있다.

```yaml
- name: Add server to Munin monitoring configuration.
  command: monitor-server webservers {{ inventory_hostname }}
  delegate_to: "{{ monitoring_master }}"
```

delegation은 서버의 load balancer 또는 replication pool에 등록하는 것을 관리하기 위해 사용된다.
우리는 특정한 command를 local에서 실행하거나 Ansible에 내장된 load balancer module을 사용하고 `delegate_to`를 이용하여 직접 load balancer host에서 command를 실행할 수 있다.

```yaml
- name: Remove server from load balancer.
  command: remove-from-lb {{ inventory_hostname }}
  delegate_to: 127.0.0.1
```

task를 localhost로 delegate할 때 Ansible은 `delegate_to` 대신에 `local_action`이라는 간단한 명령을 사용할 수도 있다.

```yaml
- name: Remove server from load balancer.
  local_action: command remove-from-lb {{ inventory_hostname }}
```

## Pausing playbook execution with `wait_for`

playbook의 중간에서 `local_action`을 사용하여 서버가 완전히 부팅되기까지를 기다리거나 어플리케이션이 특정 포트를 listen 할때까지 기다리도록 할 수 있다.

```yaml
- name: Wait for webserver to start.
  local_action:
    module: wait_for
    host: "{{ inventory_hostname }}"
    port: "{{ webserver_port }}"
    delay: 10
    timeout: 300
    state: started
```

위의 task는 `webserver_port`가 `inventory_hostname`에서 open될 때까지 기다리며 5분의 timeout을 가지고 Ansible playbook을 실행하는 host에서 체크를 한다(첫번째 체크를 하기 전과 체크 사이사이 10초의 지연시간이 있다).

`wait_for`은 많은 것들을 기다리기 위해 playbook execution을 멈출 때 사용된다.

* `host`와 `port`를 사용하여 `timeout`까지 기다리며 port가 사용 가능할때까지(또는 불가능할때까지) 기다린다.
* `path`(필요한 경우 `search_regex`도 사용하여)를 통해 `timeout`까지 파일이 존재하기를(또는 존재하지 않기를) 기다린다.
* `host`, `port`, `drained`를 `state`의 parameter로 사용하여 주어진 port가 모든 active connection을 drain했는지 확인한다.
* `delay`를 이용하여 단순히 주어진 시간(초단위로)만큼 playbook의 실행을 멈춘다.

## Running an entire playbook locally

playbook을 task가 실행되어야 하는 server나 worksation에서 실행하거나(예를 들면 self-provisioning) `ansible-playbook` command가 실행되는 것과 같은 호스트에서 playbook이 실행되어야 할 때 `--connection=local`을 사용하여 SSH connection overhead를 없애 playbook의 실행을 빠르게 할 수 있다.

간단한 예시로 `ansible-playbook test.yml --connection=local`을 사용하는 짧은 playbook이 있다.

```yaml
---
- hosts: 127.0.0.1
  gather_facts: no

  tasks:
    - name: Check the current system date.
      command: date
      register: date

    - name: Print the current system date.
      debug: var=date.stdout
```

이 playbook은 localhost를 실행하고 현재의 날짜를 debug message에 출력한다.
이는 local connection으로 동작하기 때문에 _굉장히_ 빠르게(저자의 Mac에서는 0.2초가 걸렸다) 동작할 것이다.

playbook을 `--connection=local`로 실행하는 것은 전체 playbook을 `--check` 모드로 configuration을 확인할 때(변화가 있을 때 email을 주는 cron job과 같은것) 또는 testing infrastructure에서 playbook을 testing할 때(Travis, Jenkins나 다른 CI tool을 통해) 유용하게 사용할 수 있다.
