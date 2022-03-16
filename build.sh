#!/bin/sh
# The libraries I chose to statically link are based on <github.com/AppImage/pkg2appimage/blob/master/excludelist>

[ -z $ARCH ] && ARCH=$(uname -m)

git clone https://github.com/containers/bubblewrap
cd bubblewrap

meson -Dc_link_args="-Wl,--no-undefined /usr/lib/$ARCH-linux-gnu/libcap.a" -Dbuildtype=minsize build
cd build
ninja

strip -s bwrap
mv bwrap "../../bwrap.$ARCH"
