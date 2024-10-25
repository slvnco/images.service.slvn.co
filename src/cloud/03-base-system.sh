#!/bin/bash

set -e

clean() {
    set +e
    umount $SLVN_ROOTFS/mnt/swap
    umount $SLVN_ROOTFS
    qemu-nbd --disconnect $SLVN_BLOCK
}
trap 'clean' EXIT

qemu-nbd --connect=$SLVN_BLOCK $SLVN_DISK_IMAGE

mount ${SLVN_BLOCK}p3 $SLVN_ROOTFS -o 'subvol=@,noatime'
mkdir -p $SLVN_ROOTFS/mnt/swap
mount ${SLVN_BLOCK}p3 $SLVN_ROOTFS/mnt/swap -o 'subvol=@swap,noatime'

debootstrap --arch=amd64 $SLVN_VERSION $SLVN_ROOTFS http://deb.debian.org/debian

