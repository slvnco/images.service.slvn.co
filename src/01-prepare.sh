#!/bin/bash

modprobe nbd max_part=8

if [ -b "$SLVN_BLOCK" ]; then
    echo "The block device $SLVN_BLOCK already exits."
fi

# Create Disks
mkdir $SLVN_DIST $SLVN_ROOTFS
qemu-img create -f qcow2 $SLVN_DISK_IMAGE 32G
qemu-nbd --connect=$SLVN_BLOCK $SLVN_DISK_IMAGE
