---
title: "Chapter 2 - Local Infrastructure Development: Ansible and Vagrant"
menuTitle: "Local Infrastructure Development: Ansible and Vagrant"
date:  2020-02-05T15:09:00+09:00
weight: 3
draft: false
tags: ["ansible", "ansible-for-devops"]
pre: "<i class='fas fa-minus'></i>&nbsp;"
---

## Prototyping and testing with local virtual machines

Ansible은 remote, local 가리지 않고 연결할 수 있는 서버면 모두 잘 동작한다. 일반적으로 테스트를 할 때, Ansible Playbook 개발 속도를 빠르게 하기 위해 로컬로 테스트한다. 로컬로 하는 것이 실제 환경에서 테스트하는 것보다 훨씬 안전하다.

{{% notice note %}}

최근 트렌드는 단연 TDD이다. 따라서 Infrastructure에도 테스트는 필요하다.  
소프트웨어에 대한 변경사항은 수동 또는 자동적으로 이루어진다. 이러한 것들이 Ansible과 다른 개발, configuration management 툴과 함께 구현되어 테스트를 할 수 있도록 구현되어있다. 단순하게 로컬에서 테스트를 해본다고 한들, 하지 않는 것(cowboy coding)보다 수천배 낫다.

{{% /notice %}}

**cowboy coding**: production 환경에서 직접 작업하며, 문서화나 코드의 변경점을 감싸지 않는 방법이며, roll back에 대한 대응책이 없다.

지난 십년간 많은 가상화 툴들이 개발되었고, 이에따라 로컬에서 infrastructure emulation을 할 수 있게 되었다. 중요한 서버에 장애를 내지 않고도 여러 테스트를 마음껏 할 수 있다. 단순히 VM을 새로 만들면 되기 때문에 실제 application의 downtime은 존재하지 않을 것이다.

`Vagrant`와 `VirtualBox`로 테스트 인프라를 구축할 수 있고 개별적인 서버 구성을 할 수 있다.

여기에서는 `Vagrant`와 `VirtualBox`로 Ansible을 테스트 할 새로운 서버를 만들 것이다.

## Your first local server: Setting up Vagrant

첫 local virtual server를 생성하기 위해 `Vagrant`와 `VirtualBox`를 다운로드 받고 `Vagrantfile`을 설정하여 virtual server에 대한 설정을 할 것이다.

1. `Vagrant`와 `VirtualBox`를 OS에 맞게 설치한다.
   - [Download Vagrant](https://www.vagrantup.com/downloads.html)
   - [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. `Vagrantfile`과 provisioning instructions를 저장할 폴더 생성
3. Terminal이나 PowerShell을 열고 해당 폴더로 이동
4. `vagrant box add geerlingguy/centos7`을 이용하여 CentOS 7.x 64-bit을 추가한다.
5. `vagrant init geerlingguy/centos7`으로 방금 다운로드 받은 default virtual server configuration을 생성할 수 있다.
6. `vagrant up`으로 CentOS를 부팅할 수 있다.

`Vagrant`는 이미 만들어진 64-bit CentOS 7 가상 머신을 다운로드 한다. 또는 원할 경우 커스텀 `boxes`를 생성할 수 있다. 이를 통해 `VirtualBox`에서 사용할 configuration 파일인 `Vagrantfile`을 생성하여 이를 가상 머신의 부팅에 사용한다.

이 가상 서버를 관리하는 것은 상당히 쉽다.

- `vagrant halt`: VM 종료
- `vagrant up`: VM을 실행한다.
- `vagrant destroy`: `VirtualBox`에서 완전히 머신을 삭제한다.
  - 이 때 `vagrant up`을 하게 되면 다시 base box에서 재 생성을 하게 된다.
- `vagrant ssh`: 가상 머신으로 ssh 접속. `Vagrantfile`이 위치한 폴더에서 입력하면 된다.
- `vagrant ssh-config`로 수동으로 접속하거나 다른 어플리케이션에서 접속할 수 있다.

## Using Ansible with Vagrant

`Vagrant`는 preconfigured boxes를 사용하여 간편하게 하지만 `VirtualBox`GUI에서도 이와 비슷하게 할 수 있다. `Vagrant`는 다음과 같은 특징이 있다.

- **Network interface management**: port를 VM에 포워드할 수 있고, public network를 공유하거나 inter-VM과 host-only 통신을 위한 private networking을 사용할 수 있다.
- **Shared folder management**: `VirtualBox`에서 host와 VM간에 NFS나 `VirtualBox`의 native folder sharing을 통해 폴더 공유를 하도록 설정한다.
- **Multi-machine management**: `Vagrant`는 하나의 `Vagrantfile`로 여러개의 VM을 관리할 수 있다. 더 중요한 점은, 문서에도 나와있듯 역사적으로 복잡한 환경을 동작시키는 것은 이를 하나의 머신에 관리하도록 만들었다. 이는 프로덕션 셋업의 부정확한 모델로 많은 차이가 있다.
- **Provisioning**: 처음 `vagrant up`을 실행하면 `Vagrant`는 `Vagrantfile`에서 어떤 provider를 선택했든지, 자동으로 금방 생겨난 VM을 provision할 것이다. 또한 VM이 생성되고 난 후에도 `vagrant provision` 명령어를 통해 명시적으로 provisioning을 할 수 있다.

마지막 특징이 가장 중요하다. `Ansible` 또한 `Vagrant`의 provisoner 중 하나이다. `vagrant provision`을 하면 `Vagrant`는 `Ansible`에게 VM을 정의된 `Ansible Playbook`을 실행하도록 한다.

`Vagrantfile`을 열어서 다음을 추가한다. 마지막 end 전에 추가하면 된다. (`Ruby` syntax를 사용한다.)

```ruby
# Provisioning configuration for Ansible
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "playbook.yml"
  # Run commands as root.
  ansible.sudo = true
end
```

이것이 `Vagrant`에서 `Ansible`을 사용하도록 하는 가장 기본적인 설정이다. 깊게 들어가면 더 다양한 옵션들이 있다. 지금은 기본 playbook을 사용할 것이다.

## Your first Ansible Playbook

이제 `palybook.yml` 파일을 생성할 것이다. `Vagrantfile`이 있는 파일과 동일한 위치에서 다음을 입력한다.

```yaml
---
- hosts: all
  tasks:
  - name: Ensure NTP (for time synchronization) is installed.
    yum: name=ntp state=installed
  - name: Ensure NTP is running.
    service: name=ntpd state=started enabled=yes
```

playbook에 대해 간단히 알아보고 넘어가겠다. 이제 playbook을 VM에서 실행시켜본다. `Vagrantfile`과 `playbook.yml`은 동일한 위치에 있어야 한다. 그 다음 `vagrant provision`을 입력한다. 그러면 `tasks`에서 지정한 동작을 하고, 이에대한 status를 확인할 수 있다. 그 후 VM에서 동작한 것들에 대한 요약을 보여준다.

`Ansible`은 방근 정의한 간단한 playbook을 파싱하고, 여러 명령어들을 ssh를 통해 실행하여 우리가 정의한 대로 서버를 설정한다. 한 줄씩 playbook을 확인해보자.

```yaml
---
```

첫 줄은 뒤의 문서가 YAML 형식으로 작성되었음을 알려준다.

```yaml
- hosts: all
```

`Ansible`이 playbook을 어느 host에 적용할지 알려준다. `all`을 사용한 이유는 `Vagrant`가 자체의 개별적인 Ansible inventory file(이전에 생성한 `/etc/ansible/hosts`와는 다른)을 사용하여 방금 정의한 `Vagrant` VM을 관리하기 때문이다.

```yaml
  tasks:
```

뒤에 나오게 될 task들은 모든 host에서 실행될 것이다. (이 경우 우리의 VM)

```yaml
  - name: Ensure NTP daemon (for time synchronization) is installed.
    yum: name=ntp state=installed
```

이 명령어는 `yum install ntp`와 동일하지만 좀 더 똑똑하다. ntp가 설치되어있는지 확인하고 안되어있으면 설치한다. 다음의 shell script와 동일하다.

```bash
if ! rpm -qa | grep -qw ntp; then
  yum install ntp
fi
```

그러나 위의 스크립트는 `Ansible`의 `yum` command만틈 robust하지는 않다. `ntp`가 아닌 `ntpdate`가 설치되어 있을 경우엔 어떻게 해야하나? 이 스크립트는 `Ansible`의 `yum` command와 단순 비교하기에는 무리가 있다.

```yaml
  - name: Ensure NTP is running.
    service: name=ntpd state=started enabled=yes
```

마지막 단계는 `ntpd` service가 시작되었고 동작하는지 확인한다. 그리고 system boot 시 시작되도록 설정한다. 동일한 결과를 내는 shell script는 다음과 같다.

```bash
# Start ntpd if it's not already running.
if ps aux | grep -v grep | grep "[n]tpd" > /dev/null
then
  echo "ntpd is running." > /dev/null
else
  /sbin/service ntpd restart > /dev/null
  echo "Started ntpd."
fi
# Make sure ntpd is enabled on system startup
chkconfig ntpd on
```

shell script가 얼마나 복잡한 지 확인할 수 있다. 그리고 여전히 `Ansible`만큼 robust하지는 않다. idempotency를 보장하려면 shell script에 많은 작업이 필요하다.

더 간결하게 하여 `Ansible`의 `name` module을 사람이 읽을 수 있는 이름으로 각 command에 부여하면 결과적으로 다음과 같은 playbook이 완성된다.

```yml
---
- hosts: all
  tasks:
  - yum: name=ntp state=installed
  - service: name=ntpd state=started enabled=yes
```

{{% notice note %}}

code와 configuration file처럼 Ansible에서의 documentation(function에 name을 부여하는 것, 복잡한 tasks에 대해 comments를 다는 것)은 절대적으로 필요한 것은 아니다. 이렇게 하면 사람이 읽을 수 있는 정보를 가지고 어떻게 playbook이 실행되는지 확인하기 쉽다.

{{% /notice %}}

## Summary

이제 workstatin이 `infrasturcture-in-a-box`가 되었다. 그리고 그 infrastructure가 코드로 잘 테스트되었음을 보장할 수 있다. 이 작은 예시에서 간단하면서도 강력한 `Ansible` playbook을 경험할 수 있었다. 나중에 `Ansible` playbook에 대해서 더 깊게 알아볼 것이다. 또한 `Vagrant`에 대해서도 다루어 볼 것이다.
