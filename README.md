# build-envs

基于 Podman 的可复现 Linux 编译环境管理仓库。

适用于：

- Qt / C++ / Rust 开发
- 多发行版兼容性构建
- 多 glibc 版本构建
- rootless Podman
- 宿主机源码挂载开发
- 长期持久化开发容器

---

# 目录结构

```text
build-envs/
├── Makefile
└── debian10-glibc228/
    └── Containerfile
```

---

# 依赖

需要：

- Podman
- GNU Make

Arch Linux:

```bash
sudo pacman -S podman make
```

Ubuntu / Debian:

```bash
sudo apt install podman make
```

---

# 构建镜像

```bash
make build
```

默认环境：

```text
debian10-glibc228
```

镜像名：

```text
localhost/debian10-glibc228:latest
```

---

# 启动开发容器

```bash
make run \
  CODE_DIR=/path/to/project \
  QT_DIR=/path/to/Qt
```

示例：

```bash
make run \
  CODE_DIR=/home/zooeywm/repos/cloudclient \
  QT_DIR=/home/zooeywm/Qt
```

---

# 容器特性

当前开发容器具有：

- rootless Podman
- keep-id UID/GID 映射
- 宿主机文件权限保持一致
- Qt SDK 只读挂载
- ccache 持久化
- sudo 免密码
- 持久化 container（退出不删除）

---

# 重新进入已有容器

```bash
make start
```

---

# 停止容器

```bash
make stop
```

---

# 删除容器

```bash
make clean
```

---

# 更新 Containerfile 后

重新创建环境：

```bash
make stop
make clean
make build
make run CODE_DIR=... QT_DIR=...
```

因为：

```text
build 更新的是 image
不会自动更新已有 container
```

---

# Makefile 参数

## ENV

切换环境目录：

```bash
make ENV=ubuntu20-glibc231 build
```

---

## CODE_DIR

宿主机项目目录。

会挂载到：

```text
/home/builder/code
```

---

## QT_DIR

宿主机 Qt SDK 目录。

会只读挂载到：

```text
/home/builder/Qt
```

---

## USERNAME

容器内用户名。

默认：

```text
builder
```

---

# 容器内目录

| 容器路径 | 说明 |
|---|---|
| `/home/builder/code` | 项目源码 |
| `/home/builder/Qt` | Qt SDK |
| `/home/builder/.ccache` | ccache |

---

# 当前环境

## debian10-glibc228

基础镜像：

```text
debian:buster
```

glibc：

```text
2.28
```

已安装：

- build-essential
- cmake
- ninja
- protobuf
- OpenGL/EGL/GLES
- Wayland
- libdrm
- libva
- xkbcommon
- OpenSSL
- input/x11 相关开发库

适用于：

- Qt 6.x
- Wayland
- DRM/VAAPI
- Linux 桌面客户端开发

---

# 添加新环境

新增目录：

```text
ubuntu20-glibc231/
```

并添加：

```text
Containerfile
```

然后：

```bash
make ENV=ubuntu20-glibc231 build
```

---

# 关于 Containerfile

本项目使用：

```text
Containerfile
```

而不是：

```text
Dockerfile
```

原因：

- 面向 OCI / Podman 生态
- 与 Dockerfile 语法兼容
- Podman 默认优先识别 Containerfile

---

# 关于 :Z

挂载参数中的：

```text
:Z
```

用于 SELinux relabel。

在未启用 SELinux 的系统上通常无影响。

保留该参数以兼容：

- Fedora
- RHEL
- OpenShift
- 企业 Linux 环境

---

# 推荐工作流

首次：

```bash
make build
make run CODE_DIR=... QT_DIR=...
```

后续：

```bash
make start
```

退出：

```bash
exit
```

停止：

```bash
make stop
```
