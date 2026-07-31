# 我的定制化bluefin-dx-nvidia &nbsp; [![bluefin](https://github.com/lumisama-qvq/bluefin-dx-nvidia-open-cn/actions/workflows/build.yml/badge.svg)](https://github.com/lumisama-qvq/bluefin-dx-nvidia-open-cn/actions/workflows/build.yml)

## 特色

- [x] 使用[gnome-rounded-blur](https://github.com/kancko/gnome-rounded-blur)修复blur my shell在圆角模糊的问题
- [x] 添加ibus-rime
- [x] 优化bluefin-cli，方便用户自定义
- [ ] 添加方便的国内源更换方法
- [ ] 增加mihomo/mihomo-smart内核
- [ ] 优化gnome体验

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

## ISO文件

可在Fedora Atomic上构建，您可以使用这里提供的说明生成[脱机ISO](https://blue-build.org/how-to/generate-iso/#_top). 目前ISO文件过大，无法在GitHub上进行托管，用户暂时请以变基的方式使用本镜像。

## 验证

镜像使用 [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign)签名. 您可以通过下载 `cosign.pub` 文件并运行下面命令来验证签名:

```bash
cosign verify --key cosign.pub ghcr.io/lumisama-qvq/bluefin-dx-nvidia-open-cn
```
