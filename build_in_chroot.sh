#!/bin/sh

sudo apt install qemu-user-static

mkdir -p chrootdir/tmp chrootdir/dev chrootdir/proc sfsmnt upper/usr/bin work upper/run/systemd

# Move QEMU to the chroot directory
cp /usr/bin/qemu-aarch64-static upper/usr/bin

# Mount up the chroot
sudo mount -t squashfs "bionic-server-cloudimg-$1.squashfs" sfsmnt
sudo mount -t overlay overlay -olowerdir=sfsmnt,upperdir=upper,workdir=work chrootdir

sudo mount -o bind /proc chrootdir/proc/
#sudo mount -o bind /dev chrootdir/dev/
sudo mount --rbind /run/systemd chrootdir/run/systemd

# Everything below will be run inside the chroot
cat << EOF | sudo chroot chrootdir /bin/bash
sudo apt update
sudo apt install -y python3-pip libcap-dev pkg-config
sudo pip3 install --upgrade pip
sudo pip3 install meson ninja

wget https://raw.githubusercontent.com/mgord9518/portable_bwrap/main/build.sh
sh build.sh
EOF
