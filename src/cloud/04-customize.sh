#!/bin/bash

set -e

clean() {
    set +e
    swapoff $SLVN_ROOTFS/mnt/swap/swapfile

    umount $SLVN_ROOTFS/dev/pts
    umount $SLVN_ROOTFS/dev
    umount $SLVN_ROOTFS/proc
    umount $SLVN_ROOTFS/sys
    umount $SLVN_ROOTFS/tmp
    umount $SLVN_ROOTFS/boot/efi
    umount $SLVN_ROOTFS/mnt/swap
    umount $SLVN_ROOTFS

    qemu-nbd --disconnect $SLVN_BLOCK
}
trap 'clean' EXIT

qemu-nbd --connect=$SLVN_BLOCK $SLVN_DISK_IMAGE

# Mount
mount ${SLVN_BLOCK}p2 $SLVN_ROOTFS -o 'subvol=@,noatime'
mkdir -p $SLVN_ROOTFS/mnt/swap
mount ${SLVN_BLOCK}p2 $SLVN_ROOTFS/mnt/swap -o 'subvol=@swap,noatime'
mkdir -p ${SLVN_ROOTFS}/boot/efi
mount ${SLVN_BLOCK}p1 ${SLVN_ROOTFS}/boot/efi
mount --bind /dev ${SLVN_ROOTFS}/dev
mount -t devpts /dev/pts ${SLVN_ROOTFS}/dev/pts
mount -t proc proc ${SLVN_ROOTFS}/proc
mount -t sysfs sysfs ${SLVN_ROOTFS}/sys
mount -t tmpfs tmpfs ${SLVN_ROOTFS}/tmp

# Basic fstab based on the current mount.
genfstab -t UUID $SLVN_ROOTFS > $SLVN_ROOTFS/etc/fstab

chroot $SLVN_ROOTFS /bin/bash <<EOF

set -e

export DEBIAN_FRONTEND=noninteractive

cat >/etc/apt/sources.list <<EOL
deb [arch=amd64] http://deb.debian.org/debian ${SLVN_VERSION} main non-free-firmware
deb [arch=amd64] http://deb.debian.org/debian ${SLVN_VERSION}-updates main non-free-firmware
deb [arch=amd64] http://deb.debian.org/debian ${SLVN_VERSION}-backports main non-free-firmware
deb [arch=amd64] http://security.debian.org/debian-security ${SLVN_VERSION}-security main non-free-firmware
EOL

apt-get update
apt-get dist-upgrade -y
apt-get autoremove --purge -y

# Locales
apt-get install -y \
    locales

locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
locale-gen

# Basic packages.
apt-get install -y \
    iotop \
    bmon \
    htop \
    wget \
    curl \
    nmon \
    ncdu \
    traceroute \
    tmux \
    git \
    cloud-init \
    btrfs-progs \
    qemu-guest-agent \
    bash-completion \
    openssh-server

# Swap.
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile
fallocate -l 2G /mnt/swap/swapfile
chmod 0600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile

apt-get install linux-image-amd64 grub-efi -y

cat >/etc/default/grub <<EOL
# This file was overwritten during base-image building.
# Version: 1
#
# If you change this file, run 'update-grub' afterwards to update
# /boot/grub/grub.cfg

# Default option.
GRUB_DEFAULT=0

# Show GRUB when waiting.
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo Debian\`

# Wait for 5 seconds.
GRUB_TIMEOUT=5

# Wait for 5 seconds (after a failed boot, however, this option is broken under btrfs, which likely causes it to always think a failure has occured).
GRUB_RECORDFAIL_TIMEOUT=5

# Options on "normal" boots.
GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0,115200 console=tty0"

# Options for recovery boots.
GRUB_CMDLINE_LINUX=""

# Enable the serial console.
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"

# Disable OS scanning.
GRUB_DISABLE_OS_PROBER=true
EOL

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck --no-nvram
update-grub

apt-get autoremove -y --purge
apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Done!
exit

EOF

# Get the final fstab.
cat >$SLVN_ROOTFS/etc/fstab <<EOL
# /etc/fstab: static file system information.
#
# <file system> <mount point> <type> <options> <dump> <pass>

UUID=$(blkid ${SLVN_BLOCK}p1 -s UUID -o value) /boot/efi vfat defaults 0 2
UUID=$(blkid ${SLVN_BLOCK}p2 -s UUID -o value) / btrfs defaults,noatime,subvol=@ 0 0
UUID=$(blkid ${SLVN_BLOCK}p2 -s UUID -o value) /mnt/swap btrfs defaults,noatime,subvol=@swap 0 0

/mnt/swap/swapfile none swap defaults 0 0
EOL
