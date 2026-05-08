# build-envs

基于 Podman 的可复现 Linux 编译环境仓库。

这个仓库当前只做两件事：

- 构建指定发行版 / glibc / 架构的开发镜像
- 启动带源码和 Qt SDK 挂载的持久化开发容器

## 依赖

- Podman
- GNU Make

Debian / Ubuntu:

```bash
sudo apt install podman make
```

Arch Linux:

```bash
sudo pacman -S podman make
```

## 支持的环境

| ENV                       | Arch    | Base image        | glibc  | Notes                                  |
| ------------------------- | ------- | ----------------- | ------ | -------------------------------------- |
| `debian10-glibc228-x64`   | `amd64` | `debian:buster`   | `2.28` | 兼容旧 glibc 的 x64 构建环境           |
| `debian12-glibc236-arm64` | `arm64` | `debian:bookworm` | `2.36` | 包含 `librockchip_mpp.so` 和兼容软链接 |

`ENV` 是必填参数；不传会直接报错。

## 常用流程

1. 构建镜像

```bash
make ENV=debian10-glibc228-x64 build
```

2. 启动开发容器

```bash
make ENV=debian10-glibc228-x64 run \
  CODE_DIR=/path/to/project \
  QT_DIR=/path/to/Qt
```

示例：

```bash
make ENV=debian10-glibc228-x64 run \
  CODE_DIR=/home/zooeywm/repos/cloudclient \
  QT_DIR=/home/zooeywm/Qt
```

3. 再次进入已存在的容器

```bash
make ENV=debian10-glibc228-x64 start
```

4. 进入容器的 root shell

```bash
make ENV=debian10-glibc228-x64 root
```

5. 停止或删除容器

```bash
make ENV=debian10-glibc228-x64 stop
make ENV=debian10-glibc228-x64 clean
make ENV=debian10-glibc228-x64 purge
```

## Make 目标

| Target  | 说明                               |
| ------- | ---------------------------------- |
| `build` | 构建 `localhost/<ENV>:latest` 镜像 |
| `run`   | 创建并进入容器                     |
| `start` | 启动并附着到已有容器               |
| `root`  | 以 `root` 身份进入已有容器         |
| `stop`  | 停止容器                           |
| `clean` | 删除容器                           |
| `purge` | 删除镜像                           |

容器名固定为 `<ENV>`，镜像名固定为 `localhost/<ENV>:latest`。

## Make 变量

| 变量       | 是否必填     | 默认值    | 说明                                   |
| ---------- | ------------ | --------- | -------------------------------------- |
| `ENV`      | 是           | 无        | 目标环境，必须是 `SUPPORTED_ENVS` 之一 |
| `CODE_DIR` | `run` 时必填 | 无        | 宿主机项目目录                         |
| `QT_DIR`   | `run` 时必填 | 无        | 宿主机 Qt SDK 目录，只读挂载           |
| `USERNAME` | 否           | `builder` | 容器内用户名，同时影响 home 路径       |
| `ENGINE`   | 否           | `podman`  | 容器引擎命令                           |

## 容器内挂载路径

假设 `USERNAME=builder`：

| 容器路径             | 来源       |
| -------------------- | ---------- |
| `/home/builder/code` | `CODE_DIR` |
| `/home/builder/Qt`   | `QT_DIR`   |

容器工作目录默认是 `/home/<USERNAME>/code`。

## 容器行为

- 使用 `--userns=keep-id`，容器内 UID/GID 与宿主机当前用户保持一致
- `QT_DIR` 以只读方式挂载
- 容器退出后不会自动删除
- `root` 目标依赖容器已经存在且正在运行

## 更新环境后的处理

修改 `Containerfile` 或环境目录里的文件后，已有容器不会自动更新。需要手动重建：

```bash
make ENV=debian10-glibc228-x64 stop
make ENV=debian10-glibc228-x64 clean
make ENV=debian10-glibc228-x64 build
make ENV=debian10-glibc228-x64 run \
  CODE_DIR=/path/to/project \
  QT_DIR=/path/to/Qt
```

## 添加新环境

1. 新建一个环境目录，例如 `debian12-glibc236-x64/`
2. 在目录下添加 `Containerfile`
3. 如有额外二进制资产，一并放进该目录
4. 在 `Makefile` 的 `SUPPORTED_ENVS` 中加入新环境名
5. 使用 `make ENV=<new-env> build` 验证
