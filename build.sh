#!/bin/sh
# The libraries I chose to statically link are based on <github.com/AppImage/pkg2appimage/blob/master/excludelist>

[ -z $ARCH ] && ARCH=$(uname -m)

git clone https://github.com/containers/bubblewrap
cd bubblewrap

meson -Dc_link_args="-Wl,--no-undefined /usr/lib/$ARCH-linux-gnu/libcap.a" -Dbuildtype=minsize build
cd build
ninja
# Why tf does it seem impossible to get static builds using Meson? Maybe I missed something but this works
gcc -o bwrap-static bwrap.p/bubblewrap.c.o bwrap.p/bind-mount.c.o bwrap.p/network.c.o bwrap.p/utils.c.o -lcap -lc -lpthread -static -Os

strip -s bwrap*
mv bwrap "../../bwrap.$ARCH"
mv bwrap-static "../../bwrap-static.$ARCH"
