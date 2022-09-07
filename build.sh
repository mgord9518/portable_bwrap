#!/bin/sh

[ -z $ARCH ] && ARCH=$(uname -m)

git clone https://github.com/containers/bubblewrap
cd bubblewrap

meson -Dc_link_args="-Wl,--no-undefined /usr/lib/$ARCH-linux-gnu/libcap.a" -Dbuildtype=minsize build
cd build
ninja
# Why tf does it seem impossible to get static builds using Meson? Maybe I missed something but this works
gcc -o bwrap-static bwrap.p/bubblewrap.c.o bwrap.p/bind-mount.c.o bwrap.p/network.c.o bwrap.p/utils.c.o -lcap -lc -lpthread -static -Os

# Also build as a static library for use in aisap (or wherever else someone would want to)
# bwrap must be rebuilt with the main function renamed because one executable cannot have multiple main funcs
# Big thanks to <github.com/Seren541> for the help on how to do this
cd ..
sed -i 's/main /void bwrap_main /g' bubblewrap.c
meson -Dc_link_args="-Wl,--no-undefined /usr/lib/$ARCH-linux-gnu/libcap.a" -Dbuildtype=minsize --reconfigure build
cd build
ninja
ar -rcs libbwrap.a bwrap.p/bubblewrap.c.o bwrap.p/bind-mount.c.o bwrap.p/network.c.o bwrap.p/utils.c.o

strip -s bwrap*
mv bwrap "../../bwrap.$ARCH"
mv bwrap-static "../../bwrap-static.$ARCH"
mv bwrap.a "../../bwrap-static.$ARCH.a"
