---
title: "Git Action으로 hugo build 자동화 하기"
date: 2021-12-12T23:16:34+09:00
draft: false
---

Github Action은 Github에서 제공하는 CI/CD 솔루션이다.
유저는 `uses` 라는 명령어로 원하는 작업을 불러올 수 있다.

현재 내가 설정했던 Jenkins를 통한 빌드 및 배포는 이사하며 네트워크 환경이 변경되고, github에서 token을 통한 push만 허용되는 변경 등으로 인해 더이상 실행되고 있지 않았다.
또한 항상 포스트를 작성하려면 VM을 켜야했기에, 너무나 귀찮은 일이 아닐 수 없었다.

따라서 Github Action 통해서 기존에 로컬에서 Jenkins를 통해 hugo 파일을 빌드해서 다른 repo에 올리는 것을 Jenkins를 사용하지 않고 Github Action을 통해 빌드하고 배포하도록 수정했다.
이를 통해 VM에 대한 dependency를 없앨 수 있었으며, 어디서나 내 repo에 push만 하면 포스팅이 자동으로 업데이트 되도록 변경하였다.

## workflows

전체 플로우를 확인한 뒤 하나씩 자세히 확인해보도록 하자.

1. `master` 브랜치로 새로운 내용 삽입
2. `git checkout` 을 통해 submodule, git contents를 pull
3. Github `secrets` 에 `config.toml` 파일을 저장 후 불러오기
4. `hugo --minify` 로 ./public 폴더에 내용 생성
5. google adsense를 위한 파일 삽입
6. github page용 repo에 파일 push

간단하게 모든 플로우가 하나의 container에서 이루어진다고 생각하면 좀 더 이해하기 쉬울 것이다.
해당 container에다가 `sudo apt install -y` 로 필요한 파일들을 다운받을 수도 있고, 원하는 명령어를 마음껏 사용할 수도 있다.
그리고 물론, 실행 후에는 삭제가 된다.

이를 기반으로 한 Github Action 파일은 아래와 같다.

```yml
name: github pages

on:
  push:
    branches:
      - master  # Set a branch to deploy

jobs:
  deploy:
    runs-on: ubuntu-20.04
    steps:
      - uses: actions/checkout@v2
        with:
          token: ${{ secrets.GIT_TOKEN }}
          submodules: recursive

      - name: copy config.toml
        run: echo "${CONFIG_TOML}" > config.toml
        env:
          CONFIG_TOML: ${{ secrets.config }}

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          # extended: true

      - name: Build
        run: hugo --minify

      - name: site-verification
        run: echo "${{ secrets.SITE_VERIFICATION }}" > ./public/google34bf590cfe76298c.html

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          deploy_key: ${{ secrets.ACTIONS_DEPLOY_KEY }}
          external_repository: kimmj/kimmj.github.io
          publish_branch: master  # default: gh-pages
          publish_dir: ./public
```

### `master` 브랜치로 새로운 내용 삽입

기존처럼 새로운 포스팅을 생성하는 부분이다.
`hugo new --kind contents Hugo/hubo-build-git-action.md` 처럼 생성하면 된다.

### `git checkout` 을 통해 submodule, git contents를 pull

```yml
      - uses: actions/checkout@v2
        with:
          token: ${{ secrets.GIT_TOKEN }}
          submodules: recursive
```

여기서 `${{ secrets.GIT_TOKEN }}` 은 `PAT` (Personal Access Token) 이다.
이 토큰을 이용해서 hugo 폴더에 있는 themes 아래 submodule들을 불러온다.

### Github `secrets` 에 `config.toml` 파일을 저장 후 불러오기

```yml
      - name: copy config.toml
        run: echo "${CONFIG_TOML}" > config.toml
        env:
          CONFIG_TOML: ${{ secrets.config }}
```

내 `config.toml` 에는 credential같은 정보가 들어가있어서, github에 파일을 올릴 수 없었다.
이 파일은 이전에 `git-secrets` 라는걸로 해결을 했었는데, github에 이제 secret을 올릴 수 있는 기능이 생겨서, 여기다 그냥 올려버렸다.
이를 `echo`를 통해 repo에 함께 담아 주었다.

### `hugo --minify` 로 ./public 폴더에 내용 생성

```yml
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          # extended: true

      - name: Build
        run: hugo --minify
```

`hugo --minify` 를 입력하게 되면 실제로 `./public` 폴더에 정적 HTML 파일들이 저장된다.
이 파일들은 github page를 위해 사용될 것이다.

### google adsense를 위한 파일 삽입

```yml
      - name: site-verification
        run: echo "${{ secrets.SITE_VERIFICATION }}" > ./public/google34bf590cfe76298c.html
```

예전에 adsense를 달 때 site-verification 파일을 넣었었다.
이게 이번에도 필요한지는 정확하게 기억이 안나지만, 혹시몰라서 그냥 넣어주었다.

### github page용 repo에 파일 push

```yml
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          deploy_key: ${{ secrets.ACTIONS_DEPLOY_KEY }}
          external_repository: kimmj/kimmj.github.io
          publish_branch: master  # default: gh-pages
          publish_dir: ./public
```

여기서 `ACTIONS_DEPLOY_KEY` 는 [create-ssh-deploy-key](https://github.com/peaceiris/actions-gh-pages#%EF%B8%8F-create-ssh-deploy-key) 를 보고 따라하여 만들었다.

이렇게 하면 `kimmj/kimmj.github.io` repo에 master branch로 `./public` 에 있는 파일들이 push된다.
이 때 기존에 있던 파일을 모두 지운 뒤 push 하는 방식이므로 따로 필요한 static file이 해당 repo에 반드시 있어야 할 경우, 위에서 내가 했던 방법대로 secret에 담고 echo로 넣어둔다던지, workaround를 찾아서 해결하면 된다.
