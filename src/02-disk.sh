#!/bin/bash

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

umount $SLVN_ROOTFS
mount ${SLVN_BLOCK}p2 $SLVN_ROOTFS -o 'subvol=@,noatime'
mkdir -p $SLVN_ROOTFS/mnt/swap
mount ${SLVN_BLOCK}p2 $SLVN_ROOTFS/mnt/swap -o 'subvol=@swap,noatime'
