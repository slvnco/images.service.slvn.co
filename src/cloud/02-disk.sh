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
  mkpart primary 1MiB 1GiB \
  set 1 esp on \
  mkpart primary 1GiB 100% \
  print

# Create Filesystems.
mkfs.vfat -F 32 -n ESP ${SLVN_BLOCK}p1
mkfs.btrfs ${SLVN_BLOCK}p2

# Subvolumes.
mount ${SLVN_BLOCK}p2 $SLVN_ROOTFS
btrfs subvolume create $SLVN_ROOTFS/@
btrfs subvolume create $SLVN_ROOTFS/@swap
