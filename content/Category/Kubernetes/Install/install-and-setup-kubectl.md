---
title: "Install and Setup Kubectl"
menuTitle: "Install and Setup Kubectl"
date:  2020-01-14T02:26:45+09:00
weight: 2
draft: false
tags: [ "kubernetes", "kubectl", "install" ]
---

시작에 앞서, 공식 docs에서는 `kubectl` 버전이 minor 버전 하나정도만 차이나도록 하라고 하고 있습니다. 
예를 들어, v1.16.x인 client(worker, master 포함)가 있다면, v1.15.x나 v1.17.x까지만 허용합니다.

### Linux에 `kubectl` 설치

`curl`을 이용하는 방법, `snap`이나 `homebrew`를 이용하는 방법, `native package management`를 이용하는 방법이 있습니다.
그 중에서 `curl`을 이용하는 방법을 다루도록 하겠습니다.

1. `curl`을 통해서 `kubectl`을 설치합니다.

    ```bash
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    ```

    `curl` 안에 `curl`을 넣어서 최신 버전의 stable을 가지고오도록 하고있네요.
    이를 응용하면 특정한 버전의 `kubectl`도 가지고 올 수 있을 것입니다.

    ```bash
    curl -LO https://storage.googleapis.com/kubernetes-release/release/1.16.1/bin/linux/amd64/kubectl
    ```

    위의 명령어는 1.16.1 버전을 설치하는 것입니다.
    이처럼 버전이 들어가는 자리에 원하는 버전을 넣으면, 언제든 원하는 버전의 `kubectl`을 깔 수 있을 것입니다.

2. `kubectl` 바이너리 파일을 실행 가능하도록 변경합니다.
    
    ```bash
    chmod +x ./kubectl
    ```

3. 바이너리 파일을 어디서든 실행할 수 있도록 `$PATH` 환경변수가 가르키는 위치에 둡니다.
    예를 들어 `$PATH`가 `/usr/local/bin`을 포함한다면 그 위치에 `kubectl`을 위치시킵니다.

    ``` bash
    sudo mv ./kubectl /usr/local/bin/kubectl
    ```

4. `kubectl`의 버전을 확인하여 제대로 설치가 되었는지 확인합니다.

    ```bash
    kubectl version --client
    ```

5. `kubectl`의 자동완성 기능을 활성화 시킵니다.

    ```bash
    apt install bash-completion
    ```

    `bash-completion` 프로그램을 다운로드 받습니다.
    그 후 `/etc/bash_completion.d/` 디렉토리에 bash-completion 설정을 다음의 명령어를 통해 넣습니다.

    ```bash
    kubectl completion bash >/etc/bash_completion.d/kubectl
    ```

    이제 `shell`을 다시 실행시키면 자동완성 기능이 활성화 될 것입니다.


Reference:  
https://kubernetes.io/docs/tasks/tools/install-kubectl/