---
title: "Prompts"
date:  2020-03-12T19:18:08+09:00
weight: 7
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

드문 경우이지만 사용자가 playbook에서 사용할 variable의 값을 입력하게 해야할 경우가 있을 수 있다.
playbook이 사용자의 개인 로그인 정보를 필요로 하거나 playbook을 실행하는 사람에 의해 버전이나 다른 값들을 입력받아야 할 때, 어디에서 실행되어야 하는지 알아야 할 때면서 이런 정보들이 configured(environment variable나 inventory variable을 사용하는 것)되는 방법이 없는 경우에는 `vars_prompt`를 이용한다.

간단한 예시로 사용자에게 username과 password를 입력하게 하여 network share에 로그인할 수 있도록 할 수 있다.

```yaml
---
- hosts: all

  vars_prompt:
    - name: share_user
      prompt: "What is your network username?"

    - name: share_pass
      prompt: "What is your network password?"
      private: yes
```

Ansible이 play를 실행하기 전에 Ansible은 사용자에게 username과 password를 입력하게 할 것이고 나중에 입력하는 값들은 보안상의 문제때문에 command line에 숨겨져 보일 것이다.

prompt에는 다음과 같은 특수 옵션들이 있다.

* `private`: `yes`로 설정될 경우 사용자의 입력이 command line에서 숨겨진다.
* `default`: prompt에 대해 default value를 설정하여 end user의 시간을 절약할 수 있다.
* `encrypt`/`confirm`/`slat_size`: 이 값들은 password를 설정할 때 사용하여 entry를 확인(`confirm`이 `yes`로 설정되었을 경우 사용자는 password를 두번 입력해야 한다)하고 이를 salt(지정된 size와 crypt scheme을 이용하여)를 이용하여 암호화한다.
  Ansible의 [Prmopts](http://docs.ansible.com/playbooks_prompts.html#prompts) documentation을 통해 prompted variable encryption에 대한 자세한 정보를 얻을 수 있다.

prompts는 user-specific한 정보를 수집하는 간단한 방법이지만 대부분의 경우에 절대적으로 필요하지 않는 이상 피하는 것이 좋다.
playbook을 실행하는 데 완전한 automation을 유지하고자 한다면 role이나 playbook variable, inventorty variable 또는 심지어 local environment variable을 사용하는 것이 더 선호되는 방법이다.
