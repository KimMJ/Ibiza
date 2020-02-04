---
title: "Getting Started With_Ansible"
menuTitle: "Getting Started With_Ansible"
date:  2020-02-05T01:41:13+09:00
weight: 2
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

## Ansible and Infrastructure Management

### On snowflakes[^1] and shell scripts

보통은 SSH를 통해서 접속하여 필요한 작업을 하고 접속을 종료한다. 이 때, 어떤 것들은 기록되고 어떤 것들은 기록되지 않는다. 결국 관리자가 똑같은 작업을 여러 서버에 해야하는 책임소지가 있다.

서버가 동작 중일 때 몇가지 변경사항이 생기고 적용할 방법이 쉽다면 문제가 되진 않을 것이다.
그러나 불행하게도 대부분은 그렇지 않다.

이 때 기존과 똑같은 서버를 만드려고 한다면 정말 많은, 쓸데없는 시간을 소비하게 된다.

shell script로 보완을 하려고 하지만, 모든 edge case를 커버하기란 어려운게 현실이다.

### Configuration management

`CFEngine`, `Puppet`, `Chef`같은 서비스들이 이런 Infrastructure를 구성하는 툴로 사용되고 있었다. 하지만 command line configuration이 아닌 다른 방법을 새로 익혀야 한다. `Puppet`이나 `Chef`는 Ruby나 기타 커스텀 언어들에 대한 이해가 필요하다.

반면 Ansible은 command line을 그대로 실행하게 한다. 따라서 기존의 스크립트를 이용할 수 있다. 이를 idempotent[^2] playbook으로 전환할 수 있다. command line에 익숙한 사람들에게는 훨씬 좋은 옵션이 될 것이다.

Ansible은 변경사항들을 모든 서버에(default) push하고 추가적인 소프트웨어를 서버에 설치할 필요가 없다. 따라서 memory footprint, 관리를 위한 추가적인 daemon같은 것은 없다.

#### Idempotence

멱등성은 여러번 동작을 해도 동일한 결과가 나온다는 속성이다.

이는 configuration management tool의 중요한 기능으로 몇번을 실행하더라도 동일한 설정이 유지되어야 한다는 것을 의미한다. 많은 shell script가 한 번 이상 실행되면 의도하지 않은 결과를 발생시키는데, Ansible은 추가적인 설정 없이 동일한 결과가 나오게 한다.

사실 대부분의 Ansible modules와 commands는 idempotent이고, 그렇지 않은 것은 Ansible에서 언제 command가 동작해야 하는지, 변경되거나 실패한 command의 구성이 어떤지를 제공하여 모든 서버에 대해 idempotent configuration을 유지하도록 도와준다.

### Installing Ansible

Ansible은 Python에만 dependency가 있다. Python이 있으면 `pip`로 설치가 가능하다.

Mac 환경이면 더 쉽다.

1. Homebrew 설치 (홈페이지에서 설치)
2. Python 2.7.x 설치 (`brew install python`)
3. Ansible 설치 (`sudo pip install ansible`)

`brew install ansible`로 설치해도 되고 이 경우 update 시 `brew`를 사용하면 된다.

Windows를 사용한다면 조금은 복잡하다. 둘 중 하나를 선택해서 설치하면 된다.

1. Linux Virtual Machine을 사용해서 설치하기
2. `Cygwin` 환경에서 Ansible이 동작하도록 하기

Linux를 사용한다면 이미 Ansible이 설치되어 있을 수 있다.

`python-pip`와 `python-devel`이 있다면 `pip`를 통해 Ansible을 설치할 수 있다. 이 때 "Development Tools"가 이미 설치되어 있어 `gcc`, `make` 등이 설치되어있음을 가정한다.

```bash
sudo pip install ansible
```

Fedora같은 시스템은 `yum` 패키지를 통해 설치하는 것이 가장 쉽다. RHEL/CentOS는 Ansible 설치 전에 EPEL의 RPM을 설치해야한다.

```bash
yum -y install ansible
```

Ubuntu에서의 가장 간단한 설치 방법은 `apt` package를 통해 설치하는 것이다.

```bash
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible
```

Ansible이 설치되고 나면 `ansible --version`으로 제대로 설치되어 있는지 확인한다.

## Creating a basic inventory file

Ansible은 inventory file(보통, 서버들의 리스트)을 사용하여 서버와 통신한다. IP 주소를 domain name과 매칭시키는 hosts 파일처럼 Ansible inventory file은 서버(IP address이나 domain name)을 group에 매칭시킨다. Inventory file은 이보다 더 많은 것을 할 수 있지만 지금은 간단하게 하나의 서버에 대한 파일만 생성할 것이다. `/etc/ansible/hosts`(Ansible inventory file의 default location)에 파일을 다음과 같이 추가한다.

```bash
sudo mkdir /etc/ansible
sudo touch /etc/ansible/hosts
```

이제 파일을 수정한다. 이 때 `sudo` 권한으로 수정해야 한다.

```hosts
[example]
www.example.com
```

`example`은 우리가 관리하게 될 서버의 그룹이고, `www.example.com`은 그 그룹에 속하게 된다. ssh 포트가 `22`가 아니라면 `www.example.com:2222`처럼 하면 된다. Ansible이 ssh configuration을 확인하여 지정된 포트를 불러오지 않기 때문에 포트가 다를 경우 반드시 명시해 주어야 한다.

## Running your first Ad-Hoc Ansible command

Ansible과 inventory file을 설치하였으니, command를 실행시켜 잘 되는지 확인해볼 수 있다.

```bash
ansible example -m ping -u [username]
```

여기서 `[username]`은 ssh 접속할 때 사용하는 user를 입력하면 된다. 잘 된다면 ping의 결과들이 보일 것이고 안된다면 `-vvvv` 옵션을 추가해서 세부 결과를 확인할 수 있다. `ssh username@www.example.com`이 성공한다면 위의 명령어도 당연히 성공해야 한다.

Ansible은 passwordless authentication을 가정한다. 따라서 ssh에 패스워드를 입력한다면, `ssh-copy-id`를 통해 패스워드 입력을 없앨 수 있다.

```bash
ansible example -a "free -m" -u [username]
```

위처럼 memory usage를 확인할 수 있다. 또한 `df -h`로 disk usage도 확인이 가능하다. 이런 방법으로 서버들에 에러가 없는지 확인할 수 있다.

## Summary

configuration management와 Ansible에 대해 학습하였고, 이를 설치하고 서버에 대해 이야기하며 Ansible을 통해 서버에서 command를 실행시켜보았다.


[^1]: 문서화 하지 않고 구성하였기 때문에, 한번 구성하고 나면 동일하게 설정하기 힘든, 눈처럼 녹아버리는 서버

[^2]: 멱등의. 아무리 여러번해도 결과가 같음.
