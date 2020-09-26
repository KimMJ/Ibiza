---
title: "Playbook Organization Roles and Includes"
date:  2020-03-13T12:04:52+09:00
weight: 1
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

이제까지 우리는 꽤 쉬운 예시들을 사용해왔다.
대부분의 예시는 특정 서버에 대해서 생성되었고 하나의 긴 playbook이었다.

ANsible은 더 효과적인 방법으로 task들을 구성할 수 있어 playbook을 더 유지보수할 수 있도록, 재사용할 수 있도록, 강력하게 만들어줄 수 있다.
우리는 task를 나누어 include와 role을 이용하여 더 효과적이게 만들고 common package와 application을 configure하는 데 도움을 주는, community-maintained role의 repository인 Ansible Galaxy를 조사하는 두가지를 해볼 것이다.
