---
title: "Deploy Strategy"
menuTitle: "Deploy Strategy"
date:  2020-02-03T14:09:25+09:00
weight: 10
draft: true
tags: ["deploy", "cicd", "canary", "blue-green", "roll-out"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

## Deploy Strategy

### Canary

* 한 부분을 패치할 때.
* 이전 버전과의 호환성이 중요. (두개가 동시에 동작해야 함.)
* 비율을 다르게 하면서 배포

### Blue-Green

* Blue 버전과 Green 버전 두개를 동시에 띄운 환경에서 트래픽을 한번에 변경
* 이전 버전으로 롤백할 때도 트래픽을 한번에 옮기면 간단하게 해결 가능.
* 전체 어플리케이션에 대해서 트래픽을 변경할 수 있어 전체 패키지를 배포할 때 사용할 수 있음.
