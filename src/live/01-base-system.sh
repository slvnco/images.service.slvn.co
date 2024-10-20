#!/bin/bash

set -e

# Create Disks
mkdir $SLVN_DIST $SLVN_ROOTFS

sudo debootstrap \
    --arch=amd64 \
    ${SLVN_VERSION} \
    "${$SLVN_ROOTFS}" \
    http://deb.debian.org/debian

