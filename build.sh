#!/bin/sh
# Basic build script for CI
#
# Not recommended to use for normal installs, a simple `zig build` is
# preferable for most cases
#
# REQUIRES: zig tar

[ -z $OPTIMIZE ] && OPTIMIZE=ReleaseSmall
[ -z $ARCH     ] && ARCH=$(uname -m)
[ -z $OS       ] && OS='linux'
[ -z $LIBC     ] && LIBC='musl'

zig build \
    -Doptimize="$OPTIMIZE" \
    -Dtarget="$ARCH-$OS-$LIBC" \
    -Dstrip=true

tar -cf - -C "zig-out/bin" "bwrap" \
    -C "../../zig-out/lib" "libbwrap.a" \
    | xz -9c > "bwrap-$OS-$ARCH.tar.xz"
