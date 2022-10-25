#!/bin/sh

[ -z $ARCH ] && ARCH=$(uname -m)

git clone https://github.com/containers/bubblewrap
cd bubblewrap

./autogen.sh
meson -Dbuildtype=minsize build
cd build
ninja
# Why tf does it seem impossible to get static builds using Meson? Maybe I missed something but this works
gcc -o bwrap-static bwrap.p/bubblewrap.c.o bwrap.p/bind-mount.c.o bwrap.p/network.c.o bwrap.p/utils.c.o -lcap -lc -lpthread -static -Os

cat ../config.log

# Also build as a static library for use in aisap (or wherever else someone would want to)
# bwrap must be rebuilt with the main function renamed because one executable cannot have multiple main funcs
# Big thanks to <github.com/Seren541> for the help on how to do this
cd ..
perl -0pe "s/int\nmain/int bwrap_main/" -i bubblewrap.c
gcc -c -Os bind-mount.c -o bwrap-bind-mount.o
gcc -c -Os network.c -o bwrap-network.o
gcc -c -Os utils.c -o bwrap-utils.o
gcc -c -Os bubblewrap.c -o bwrap-bubblewrap.o
ar -rcs libbwrap.a bwrap-bubblewrap.o bwrap-bind-mount.o bwrap-network.o bwrap-utils.o

strip -s build/bwrap*
mv build/bwrap "../bwrap.$ARCH"
mv build/bwrap-static "../bwrap-static.$ARCH"
mv libbwrap.a "../libbwrap.$ARCH.a"
