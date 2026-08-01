# vim: set ft=make :
# 本仓库定制的 ujust 配方（CN 分区）
# 挂载位置由 bluefin 基镜像的 00-entry.just 通过 `import? "/usr/share/ublue-os/just/60-custom.just"` 自动引入

# 一键从 GitHub 安装/更新 雾凇拼音 (rime-ice) 到 ibus-rime 用户配置目录
# 用户目录默认 ~/.config/ibus/rime；可通过环境变量 RIME_USER_DIR 覆盖
[group('CN')]
rime-ice:
    #!/usr/bin/env bash
    set -euo pipefail

    # 允许用户自定义目录（如使用 fcitx5: ~/.local/share/fcitx5/rime）
    RIME_DIR="${RIME_USER_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/ibus/rime}"
    RIME_ICE_URL="${RIME_ICE_URL:-https://github.com/iDvel/rime-ice/releases/latest/download/full.zip}"
    # 可选国内镜像，例如 ghproxy / gh-proxy.com / ghproxy.net
    MIRROR="${RIME_ICE_MIRROR:-}"
    [[ -n "$MIRROR" ]] && RIME_ICE_URL="${MIRROR%/}${RIME_ICE_URL}"

    if ! gum confirm "安装/更新 雾凇拼音 (rime-ice) 到 ${RIME_DIR}？" ; then
        exit 0
    fi

    for cmd in curl unzip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "错误：缺少依赖 $cmd，请先安装。"
            exit 1
        fi
    done

    echo "下载 rime-ice 发行包..."
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT
    curl -fL --retry 3 -o "${TMP_DIR}/full.zip" "$RIME_ICE_URL"
    unzip -qo "${TMP_DIR}/full.zip" -d "${TMP_DIR}/rime-ice"

    mkdir -p "$RIME_DIR"
    # 备份仓库自带的 default.yaml 等将被覆盖的文件（保留用户对仓库文件的直接修改）
    if [ -f "$RIME_DIR/default.yaml" ]; then
        cp -f "$RIME_DIR/default.yaml" "${RIME_DIR}/default.yaml.bak.$(date +%Y%m%d%H%M%S)"
    fi
    # 复制配置与词库；*.custom.yaml 等用户自定义文件不会被覆盖
    cp -rf "${TMP_DIR}/rime-ice/." "$RIME_DIR/"

    echo "已安装到 ${RIME_DIR}"
    echo "请在输入法设置中重新部署（托盘图标 → 部署 / F4 → Deploy），或运行 ibus restart"

# 一键把系统软件源切换到中科大 (USTC) 镜像，可选 rpm-ostree / dnf / Flatpak Flathub / Homebrew
[group('CN')]
cn-mirror:
    #!/usr/bin/env bash
    set -euo pipefail

    ITEMS=(
        "rpm-ostree  :  Fedora 软件源（影响 rpm-ostree install 分层安装）"
        "dnf         :  Fedora 软件源（影响 dnf install / makecache）"
        "flathub     :  Flatpak Flathub 应用商店源"
        "brew        :  Homebrew 镜像源（写入 ~/.config/environment.d/10-env.conf 的 HOMEBREW_* 两行）"
    )
    SELECTED="$(gum choose --no-limit --header "选择要切换到中科大(USTC)镜像的源（空格多选，回车确认）" "${ITEMS[@]}")"
    [[ -n "$SELECTED" ]] || { echo "未选择任何源，已退出。"; exit 0; }

    gum confirm "确认将所选源切换到 USTC 中科大镜像？原配置会先备份。" || { echo "已取消。"; exit 0; }

    sudo -v

    # ---- Fedora 软件源 ----
    FEDORA_SWITCHED=0

    switch_fedora() {
        local repo="$1"
        local src=""
        if [[ -f "/etc/yum.repos.d/$repo.repo" ]]; then
            src="/etc/yum.repos.d/$repo.repo"
        elif [[ -f "/usr/etc/yum.repos.d/$repo.repo" ]]; then
            src="/usr/etc/yum.repos.d/$repo.repo"
        fi
        if [[ -z "$src" ]]; then
            echo "跳过：找不到 $repo.repo"
            return 0
        fi
        local target="/etc/yum.repos.d/$repo.repo"
        if [[ "$src" != "$target" ]]; then
            sudo cp -f "$src" "$target"
        fi
        sudo sed -i.ustc.bak \
            -e 's|^metalink=|#metalink=|g' \
            -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.ustc.edu.cn/fedora|g' \
            "$target"
        if ! grep -qE '^\s*baseurl=' "$target"; then
            echo "警告：$target 没有可用的 baseurl（repo 格式不常见），请手动检查"
        fi
        echo "已切换：$target"
    }

    # ---- Homebrew 镜像源 ----
    switch_brew() {
        local envdir="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
        local conf="$envdir/10-env.conf"
        mkdir -p "$envdir"
        touch "$conf"
        # 只在首次切换时备份，保证备份始终是原始内容
        if [[ ! -f "$conf.ustc.bak" ]]; then
            cp -f "$conf" "$conf.ustc.bak"
        fi
        # 已存在则替换该行，否则追加（兼容带/不带 export 前缀的写法）
        for var in \
            'HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"' \
            'HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"'; do
            key="${var%%=*}"
            if grep -q "^\(export[[:space:]]*\)\?${key}=" "$conf"; then
                sed -i "s|^\(export[[:space:]]*\)\?${key}=.*|${var}|" "$conf"
            else
                echo "$var" >> "$conf"
            fi
        done
        echo "已写入 brew 镜像源配置（$conf），重新登录后生效"
    }

    while IFS= read -r choice; do
        case "$choice" in
            rpm-ostree* | dnf*)
                if [[ "$FEDORA_SWITCHED" -eq 0 ]]; then
                    FEDORA_SWITCHED=1
                    echo ">> 切换 Fedora 软件源（rpm-ostree / dnf）..."
                    switch_fedora "fedora"
                    switch_fedora "fedora-updates"
                    switch_fedora "fedora-updates-testing"
                    if command -v dnf >/dev/null 2>&1; then
                        sudo dnf makecache || echo "警告：dnf makecache 失败，可稍后手动执行 sudo dnf makecache"
                    fi
                fi
                ;;
            flathub*)
                echo ">> 切换 Flathub 到 USTC 镜像..."
                if flatpak remotes --system --columns=name 2>/dev/null | grep -qx "flathub"; then
                    sudo flatpak remote-modify --system flathub --url="https://mirrors.ustc.edu.cn/flathub"
                    echo "系统级 flathub 已切换"
                fi
                if flatpak remotes --user --columns=name 2>/dev/null | grep -qx "flathub"; then
                    flatpak remote-modify --user flathub --url="https://mirrors.ustc.edu.cn/flathub"
                    echo "用户级 flathub 已切换"
                fi
                if ! flatpak remotes --system --columns=name 2>/dev/null | grep -qx "flathub" \
                    && ! flatpak remotes --user --columns=name 2>/dev/null | grep -qx "flathub"; then
                    echo "提示：未找到 flathub remote，可先运行 flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
                fi
                ;;
            brew*)
                echo ">> 切换 Homebrew 镜像源..."
                switch_brew
                ;;
        esac
    done <<< "$SELECTED"

    echo
    echo "完成！"
    echo "  - dnf / rpm-ostree：下次 install 自动走新源，也可立即 sudo dnf makecache 刷新缓存"
    echo "  - Flatpak：运行 flatpak update 拉取应用更新"
    echo "  - Homebrew：重新登录后生效（已写入 ~/.config/environment.d/10-env.conf，与 shell 无关）"
    echo "如需还原官方源，运行：ujust cn-mirror-restore"

# 一键还原 cn-mirror 切换前的官方源（rpm-ostree / dnf / Flathub / Homebrew）
[group('CN')]
cn-mirror-restore:
    #!/usr/bin/env bash
    set -euo pipefail

    gum confirm "确认恢复官方软件源？" || { echo "已取消。"; exit 0; }
    sudo -v

    # 还原 Fedora 软件源（从 *.ustc.bak 备份恢复）
    RESTORED=0
    for bak in /etc/yum.repos.d/*.ustc.bak; do
        [[ -e "$bak" ]] || continue
        sudo mv -f "$bak" "${bak%.ustc.bak}"
        RESTORED=1
        echo "已还原 ${bak%.ustc.bak}"
    done
    [[ "$RESTORED" -eq 1 ]] || echo "未找到 Fedora 源备份（可能还没切换过）。"

    # 还原 Flathub 为官方源
    if flatpak remotes --system --columns=name 2>/dev/null | grep -qx "flathub"; then
        sudo flatpak remote-modify --system flathub --url="https://dl.flathub.org/repo"
        echo "系统级 flathub 已还原为官方源"
    fi
    if flatpak remotes --user --columns=name 2>/dev/null | grep -qx "flathub"; then
        flatpak remote-modify --user flathub --url="https://dl.flathub.org/repo"
        echo "用户级 flathub 已还原为官方源"
    fi

    # 还原 Homebrew 镜像源配置（优先从备份恢复，无备份则写回官方默认值）
    ENV_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/10-env.conf"
    if [[ -f "$ENV_CONF.ustc.bak" ]]; then
        mv -f "$ENV_CONF.ustc.bak" "$ENV_CONF"
        echo "已还原 brew 镜像源配置：$ENV_CONF"
    elif [[ -f "$ENV_CONF" ]]; then
        sed -i \
            -e 's|^\(export[[:space:]]*\)\?HOMEBREW_API_DOMAIN=.*|HOMEBREW_API_DOMAIN="https://formulae.brew.sh/api"|' \
            -e 's|^\(export[[:space:]]*\)\?HOMEBREW_BOTTLE_DOMAIN=.*|HOMEBREW_BOTTLE_DOMAIN="https://ghcr.io/v2/homebrew"|' \
            "$ENV_CONF"
        echo "已把 brew 两个变量还原为官方默认：$ENV_CONF"
    else
        echo "跳过：找不到 $ENV_CONF"
    fi

    echo
    echo "已恢复官方源。建议运行：sudo dnf makecache && flatpak update"
