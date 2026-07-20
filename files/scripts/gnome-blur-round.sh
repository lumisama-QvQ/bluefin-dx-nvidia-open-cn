#!/bin/sh
dnf install -y glib2-devel meson mutter-devel gobject-introspection bc git gcc gcc-c++
curl https://raw.githubusercontent.com/aunetx/blur-my-shell/refs/heads/master/scripts/rounded_blur_build.sh | bash -s -- -i
rm -rf /tmp/gnome-rounded-blur
rm -rf ./binary
sudo dnf remove -y glib2-devel meson mutter-devel gobject-introspection bc gcc gcc-c++
