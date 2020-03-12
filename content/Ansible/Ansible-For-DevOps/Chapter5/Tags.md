---
title: "Tags"
date:  2020-03-12T19:35:01+09:00
weight: 8
draft: false
tags: [""]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

Tags는 playbook의 task들의 subset을 실행할 수 있도록(또는 제외할 수 있도록) 한다.

role, included file, individual task, 심지어 전체 play에 대해서 tag를 달 수 있다.
문법은 매우 간단하며 아래의 예시는 tag를 추가하는 다양한 방법을 보여준다.

```yaml
---
# You can apply tags to an entire play.
- hosts: webservers
  tags: deploy

  roles:
    # Tags applied to a role will be applied to the tasks in the role.
    - { role: tomcat, tags: ['tomcat', 'app'] }

  tasks:
    - name: Notify on completion.
      local_action:
        module: osx_say
        msg: "{{ inventory_hostname }} is finished!"
        voice: Zarvox
      tags:
        - notifications
        - say

    - include: foo.yml
      tags: foo
```

위의 playbook을 `tags.yml` 파일로 저장했다고 가정하면 우리는 아래의 command를 통해 `tomcat` role과 `Notify on completion` task만 실행하도록 할 수 있다.

```bash
$ ansible-playbook tags.yml --tags "tomcat, say
```

`notifications` tag를 가진것을 제외하고 싶으면 `--skip-tags`를 사용하면 된다.

```bash
$ ansible-playbook tags.yml --skip-tags "notifications"
```

이는 웬만한 tagging structure를 가지고 있다면 매우 손쉽다.
playbook의 특정한 부분만 실행하고 싶을 때, 또는 series에서 하나의 play만 실행하고 싶은 경우(또는 play나 included task를 제외하고 싶은 경우) `--tags`나 `--skip-tags`를 사용하면 쉽다.

playbook에서 `tags` 옵션을 사용하여 하나 이상의 tag를 생성할 때에는 한가지 주의해야할 점이 있다.
`tags: tagname`은 하나의 tag를 추가할때만 사용하고 하나보다 더 많은 경우 YAML이 list syntax를 사용해야 한다.

```yaml
# Shorthand list syntax.
tags: ['one', 'two', 'three']

# Explicit list syntax.
tags:
  - one
  - two
  - three

# Non-working example.
tags: one, two, three
```

일반적으로 특히 individual role과 play가 있는 더 큰 playbook에서는 tag를 많이 사용하지만 task의 묶음을 디버깅하는 경우가 아니라면 저자는 일반적으로 tag를 individual task나 includes에 추가하는 것을 피한다(visual clutter를 줄이기 위해 tag를 어디에도 추가하지 않는다).
우리의 니즈에 맞는 tagging style을 찾아야 하고 그러면 playbook에서 원하는 특정 부분을 실행할 수(또는 실행하지 않을 수) 있을 것이다.
