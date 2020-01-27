---
title: "Netplan"
date: 2020-01-11T01:12:57+09:00
draft: true
weight: 10
tags: ["ubuntu-18.04", "netplan", "static-ip"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

## Netplan

### static IP 할당

다음과 같이 static-IP-netplan.yaml을 작성합니다.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: no
      dhcp6: no
      addresses: [ 192.168.8.21/24 ]
      gateway4: 192.168.8.30
      nameservers:
        addresses: [ 8.8.8.8 ]
```