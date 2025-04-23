#!/bin/bash

set -e

clean() {
    set +e
    umount $SLVN_ROOTFS
    qemu-nbd --disconnect $SLVN_BLOCK
}
trap 'clean' EXIT

qemu-nbd --connect=$SLVN_BLOCK $SLVN_DISK_IMAGE

# Parition
parted --script --align optimal -- $SLVN_BLOCK \
  mklabel gpt \
  mkpart primary 1MiB 2MiB \
  set 1 bios_grub on \
  mkpart primary 2MiB 1GiB \
  mkpart primary 1GiB 100% \
  print

lsblk

# Create Filesystems.
mkfs.ext4 ${SLVN_BLOCK}p2
mkfs.btrfs ${SLVN_BLOCK}p3

# Subvolumes.
mount ${SLVN_BLOCK}p3 $SLVN_ROOTFS
btrfs subvolume create $SLVN_ROOTFS/@
btrfs subvolume create $SLVN_ROOTFS/@swap
