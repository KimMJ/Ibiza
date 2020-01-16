---
title: "Install Network Policy Provider"
menuTitle: "Install Network Policy Provider"
date:  2020-01-17T00:11:57+09:00
weight: 3
draft: true
tags: ["calico", "network-policy", "install", "kubernetes"]
---

Kubernetes에서 Cluster Networking은 굉장히 중요합니다.
공식 문서에서는 다음과 같은 4가지 network관련 알아야 할 사항이 있다고 합니다.

1. 강하게 결합된 container간의 통신 : 파드와 `localhost` 통신으로 해결이 됩니다.
   즉, 파드 내에서는 container간에 통신할 때 `localhost`로 통신할 수 있습니다.
2. Pod-Pod간의 통신 : Cluster Networking의 주요 쟁점입니다.
3. Pod-Service간 통신 : services로 해결합니다.
4. 외부-Service간 통신 : services로 해결합니다.

즉, 이제 하려는 작업은 Pod와 Pod간의 통신을 도와주는 Cluster Networking을 설치하는 것입니다.

여기에서는 `Calico`를 사용하여 Pod간의 통신을 하도록 설정하겠습니다.

## `kubeadm`, `kubelet`, `kubectl` 설치

`kubectl`은 이미 지난시간에 설치를 했습니다.
따라서 `kubeadm` 및 `kubelet`을 설치해보도록 하겠습니다.
절차 안에는 `kubectl`을 설치하는 스크립트 또한 포함되어있습니다.
간단하게 설명드리자면 `kubeadm`은 Kubernetes를 관리하는 툴이라고 생각하면 되고 `kubelet`은 명령을 이행하는 툴이라고 생각하면 됩니다.

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

마지막에 `apt-mark`를 통해 `kubelet`, `kubeadm`, `kubectl`의 버전을 고정시켰습니다.



#### Reference

https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/calico-network-policy/
https://kubernetes.io/docs/concepts/cluster-administration/networking/
https://docs.projectcalico.org/v3.11/getting-started/kubernetes/
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/