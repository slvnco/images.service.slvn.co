#!/bin/bash

set -e

modprobe nbd max_part=8

# Create Disks
mkdir $SLVN_DIST $SLVN_ROOTFS
qemu-img create -f qcow2 $SLVN_DISK_IMAGE 32G
