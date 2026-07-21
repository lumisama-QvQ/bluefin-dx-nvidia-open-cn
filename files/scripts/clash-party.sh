#!/bin/bash

set -e pipefail
REPO="mihomo-party-org/clash-party"
TMP_RPM="/tmp/clash-party.rpm"

# 1. 安装基础依赖
dnf install -y --setopt=install_weak_deps=False curl jq

# 2. 从 GitHub API 获取 amd64 最新 RPM 下载地址
DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '
  .assets[]
  | select(.name | endswith(".rpm"))
  | select(.name | test("x86_64|amd64|x64"; "i"))
  | .browser_download_url
' | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: Failed to find amd64 RPM package"
  exit 1
fi

# 3. 直连下载并安装
curl -sSL -o "$TMP_RPM" "$DOWNLOAD_URL"
dnf install -y --setopt=install_weak_deps=False "$TMP_RPM"

# 4. 清理临时文件与 DNF 缓存
rm -f "$TMP_RPM"
dnf clean all
rm -rf /var/cache/dnf
