# 我的定制化bluefin-dx-nvidia &nbsp; [![bluefin](https://github.com/lumisama-qvq/bluefin-dx-nvidia-open-cn/actions/workflows/build.yml/badge.svg)](https://github.com/lumisama-qvq/bluefin-dx-nvidia-open-cn/actions/workflows/build.yml)

基于[ublue](https://universal-blue.org/)项目的[bluefin-dx-nvidia-open](https://github.com/ublue-os/bluefin/pkgs/container/bluefin-dx-nvidia-open)再开发

## 特色

- [x] 使用[gnome-rounded-blur](https://github.com/kancko/gnome-rounded-blur)修复blur my shell在圆角模糊的问题
- [x] 添加ibus-rime
- [x] 优化bluefin-cli，方便用户自定义
- [x] 自定义 `ujust` 配方（`rime-ice` 一键安装/更新[雾凇拼音](https://github.com/iDvel/rime-ice)）
- [x] 添加方便的国内源更换方法（`cn-mirror` / `cn-mirror-restore`，支持 rpm-ostree、dnf、Flathub 一键切换到中科大 USTC 镜像）
- [ ] 增加mihomo/mihomo-smart内核
- [ ] 优化gnome体验

## 使用方法（ujust）

镜像内置了自定义 `ujust` 配方（挂载在 `[CN]` 分组下），使用 `ujust --list` 可查看：

- **`ujust rime-ice`** — 一键从 GitHub 下载 [rime-ice](https://github.com/iDvel/rime-ice) 最新版 `full.zip` 并安装/更新到 ibus-rime 用户配置目录（默认 `~/.config/ibus/rime`），仅覆盖配置和词库文件,因此也可作为更新手段。安装完成后在输入法里重新部署即可。
  - 环境变量：`RIME_USER_DIR`（自定义目录，如 fcitx5 用 `~/.local/share/fcitx5/rime`）、`RIME_ICE_MIRROR`（国内下载镜像前缀，如 `https://ghproxy.com/`）。
- **`ujust cn-mirror`** — 一键把系统软件源切换到中科大 (USTC) 镜像
  - `rpm-ostree` / `dnf` — Fedora 软件源（两者共用 `/etc/yum.repos.d/`
  - `flathub` — Flatpak 应用商店源（随后运行 `flatpak update` 生效）
  - `brew` — Homebrew 镜像源（把 `HOMEBREW_API_DOMAIN` / `HOMEBREW_BOTTLE_DOMAIN` 两个变量写入 `~/.config/environment.d/10-env.conf`，与所用 shell 无关，重新登录后生效）
  
  切换前自动备份（Fedora 源备份为 `*.ustc.bak`、brew 配置备份为 `10-env.conf.ustc.bak`），需要 `sudo` 权限。
- **`ujust cn-mirror-restore`** — 一键还原为官方源：从备份恢复 Fedora 源，Flathub 恢复为官方 URL（`https://dl.flathub.org/repo`）。

## 部署

要在已安装ublue系的系统上变基到此镜像:

- 初次变基需要在非信任模式下部署，这会自动下载密钥:

  ```sh
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/lumisama-qvq/bluefin-dx-nvidia-open-cn:latest
  ```

- 重启以完成变基:

  ```sh
  systemctl reboot
  ```

- 再次变基，并信任：
  
  ```sh
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/lumisama-qvq/bluefin-dx-nvidia-open-cn:latest
  ```

- 再次重启以完成部署

  ```sh
  systemctl reboot
  ```

使用 `latest` 标签，保证每次更新均指向最新的镜像。目前镜像锁在Fedora 44版本，无需担心。

### 针对国内用户网络的建议

对于无法有效连接ghcr的，可尝试替换为国内镜像源（不保证可用）

只需将`ghcr.io`替换成`ghcr.1ms.run`或者`ghcr.nju.edu.cn`

## ISO文件

可在Fedora Atomic上构建，您可以使用这里提供的说明生成[脱机ISO](https://blue-build.org/how-to/generate-iso/#_top). 目前ISO文件过大，无法在GitHub上进行托管，用户暂时请以变基的方式使用本镜像。

## 验证

镜像使用 [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign)签名. 您可以通过下载 `cosign.pub` 文件并运行下面命令来验证签名:

```bash
cosign verify --key cosign.pub ghcr.io/lumisama-qvq/bluefin-dx-nvidia-open-cn
```

-------

感谢[bluebuild](https://blue-build.org/)提供优秀的模板和配置资料！
