#!/bin/sh
# 遇到任何错误立即退出
set -e pipefali

# 1. 动态追踪编译依赖（排除系统原生自带的 git, bc, gcc 等）
TARGET_DEPS=("glib2-devel" "meson" "mutter-devel")
INSTALLED_DEPS=()

for dep in "${TARGET_DEPS[@]}"; do
    if ! rpm -q "$dep" >/dev/null 2>&1; then
        INSTALLED_DEPS+=("$dep")
    fi
done

# 安装缺失的编译依赖
if [ ${#INSTALLED_DEPS[@]} -gt 0 ]; then
    dnf -y install "${INSTALLED_DEPS[@]}"
fi

# 2. 下载并编译
REPO="https://github.com/kancko/gnome-rounded-blur"
BUILD_DIR="/tmp"
DEST_DIR="/tmp/blur-build-root"

cd "$BUILD_DIR"
rm -rf gnome-rounded-blur
git clone "$REPO"
cd gnome-rounded-blur

# 动态计算并修改配置以匹配当前容器内的 mutter 版本
MUTTER_SYS_VER=$(mutter --version | grep -o -P '(?<=mutter ).*' | sed -e 's/"//g' -e "s/'//g" -e 's/\..*//g')
HARDCODE_MUTTER_SYS_VER=$(grep -o -P '(?<=mutter_req = ).*' meson.build | sed -e 's/"//g' -e "s/'//g" -e 's/\..*//g' -e 's/>//g' -e 's/=//g' -e 's/ //g')
MUTTER_API_REPO_VER=$(grep -o -P '(?<=mutter_api_version = ).*' meson.build | sed -e 's/"//g' -e "s/'//g" -e 's/ //g')

if [[ "$MUTTER_SYS_VER" -ge "$HARDCODE_MUTTER_SYS_VER" ]]; then
    DIFF_VALUE=$(echo "$MUTTER_SYS_VER - $HARDCODE_MUTTER_SYS_VER" | bc)
    DIFF_VALUE_2=$(echo "$MUTTER_API_REPO_VER + $DIFF_VALUE" | bc)
    sed -i -e '0,/'"mutter_api_version = ""$MUTTER_API_REPO_VER"'/{s/'"$MUTTER_API_REPO_VER"'/'"$DIFF_VALUE_2"'/g}' meson.build
else
    DIFF_VALUE=$(echo "$HARDCODE_MUTTER_SYS_VER - $MUTTER_SYS_VER" | bc)
    DIFF_VALUE_2=$(echo "$MUTTER_API_REPO_VER - $DIFF_VALUE" | bc)
    sed -i -e '0,/'"mutter_req = ""$HARDCODE_MUTTER_SYS_VER"'/{s/'"$HARDCODE_MUTTER_SYS_VER"'/'"$MUTTER_SYS_VER"'/g}' meson.build
    sed -i -e '0,/'"mutter_api_version = ""$MUTTER_API_REPO_VER"'/{s/'"$MUTTER_API_REPO_VER"'/'"$DIFF_VALUE_2"'/g}' meson.build
fi

# 执行构建
meson setup build
meson compile -C build

# 临时沙盒安装并精准复制到系统 /usr
mkdir -p "$DEST_DIR"
meson install -C build --destdir "$DEST_DIR"

if [ -d "$DEST_DIR/usr/local" ]; then
    cp -rf "$DEST_DIR"/usr/local/* /usr/
elif [ -d "$DEST_DIR/usr" ]; then
    cp -rf "$DEST_DIR"/usr/* /usr/
fi

# 3. 编译成功后的极致清理（减小容器镜像体积）
rm -rf /tmp/gnome-rounded-blur
rm -rf /tmp/blur-build-root

# 精准卸载编译期临时引入的 -devel 包与 meson，绝不触碰系统原生组件
if [ ${#INSTALLED_DEPS[@]} -gt 0 ]; then
    dnf remove -y "${INSTALLED_DEPS[@]}"
fi

# 清理 dnf 缓存
dnf clean all
