---
title: "Handover"
menuTitle: "Handover"
date:  2020-03-01T00:22:17+09:00
weight: 2
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

chapter 4에서 Ubuntu LAMP server 예제는 Apache를 재시작하는 간단한 handler를 사용하였고 Apache의 configuration에 영향을 주는 특정한 task들이 `notify: restart apache`라는 옵션으로 handler에게 noti를 줬었다.

```yaml
handlers:
  - name: restart apache
    service: name=apache2 state=restarted

tasks:
  - name: Enable Apache rewrite module
    apache2_module: name=rewrite state=present
    notify: restart apache
```

어떤 상황에서는 여러개의 handler에 notify를 해야할 상황이 있을 수도 있다.
또는 어떤 handler는 다른 추가적인 handler에게 notify를 해야할 수도 있다.
이 두가지 모두 Ansible에서는 쉽게 할 수 있다. 하나의 task에서 여러 handler에게 notify를 하려면 `notify` 옵션을 list로 작성하면 된다.

```yaml
- name: Rebuild application configuration
  command: /opt/app/rebuild.sh
  notify:
    - restart apache
    - restart memcached
```

handler가 다른 handler에게 noti를 주려면 `notify` 옵션을 handler에 추가하면 된다.
handler는 기본적으로 `notify` 옵션으로 호출되는 glorified task이다.
하지만 스스로 task처럼 행동하기 때문에 다른 handler와 연계할 수 있다.

```yaml
handlers:
  - name: restart apache
    service: name=apache2 state=restarted
    notify: restart memcached

  - name: restart memcached
    service: name=memcached state=restarted
```

handler를 사용할 때 몇가지 고려해야할 사항들이 더 있다.

* handler는 task가 handler에게 notify를 할 때만 실행된다.
  만약 handler를 notify하는 task가 `when` condition이나 다른 이유로 생략되었다면 handler는 실행되지 않는다.
* handler는 play가 끝날때 딱 한번만 실행된다.
  이 동작을 override하여 playbook 중간에 handler가 실행되기를 원한다면 `meta` module을 사용하면 그렇게 할 수 있다.
  (e.g. `- meta: flush_handlers`)
* handler에게 noti를 주기 전에 play가 특정 host(또는 모든 host)에서 fail이 나면 handler는 절대 동작하지 않는다.
  playbook이 실패했을 때에도 무조건 handler가 동작하기를 원한다면 `meta` module로 해당 task를 playbook에서 분리하거나 playbook을 실행할 때 command line flag인 `--force-handlers`를 사용하면 된다.
* handler는 playbook이 동작하는 동안 어떤 호스트라도 접속이 안되는 경우 동작하지 않는다.
