#!/bin/sh
# The libraries I chose to statically link are based on <github.com/AppImage/pkg2appimage/blob/master/excludelist>

git clone https://github.com/containers/bubblewrap
cd bubblewrap

meson build
cd build
ninja
