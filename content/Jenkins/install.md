---
title: "Jenkins Install"
menuTitle: "Install"
date:  2020-02-11T17:20:41+09:00
weight: 1
draft: false
tags: ["jenkins", "install"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

## Download docker-compose.yaml

[링크](https://hub.docker.com/r/bitnami/jenkins/)를 참조하여 docker-compose.yml을 다운로드 받습니다.

```bash
curl -sSL https://raw.githubusercontent.com/bitnami/bitnami-docker-jenkins/master/docker-compose.yml > docker-compose.yml
```

현재 yaml은 다음과 같은 구성입니다.

```yaml
version: '2'
services:
  jenkins:
    image: 'bitnami/jenkins:2'
    ports:
      - '80:8080'
      - '443:8443'
      - '50000:50000'
    volumes:
      - 'jenkins_data:/bitnami'
volumes:
  jenkins_data:
    driver: local
```

여기서 몇가지 설정을 추가해주도록 합니다.

```yaml
version: '2'
services:
  jenkins:
    image: 'bitnami/jenkins:2'
    ports:
      - '38080:8080'
      - '38443:8443'
      - '50000:50000'
    volumes:
      - 'jenkins_data:/bitnami'
volumes:
  jenkins_data:
    driver: local
    driver_opts:
      type: none
      device: $PWD/jenkins_data
      o: bind
```

`jenkins_data`는 jenkins가 사용할 데이터들입니다.
이를 local에 폴더로 만들어줍니다.

```bash
mkdir jenkins_data
```

그 다음 실행합니다.

```bash
docker-compose up -d
```

`http://$IP:38080` 으로 접속할 수 있습니다.
기본 ID/PASSWD는 (user/bitnami)입니다.

## Reference

* <https://hub.docker.com/r/bitnami/jenkins/>
