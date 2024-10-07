#!/bin/bash

debootstrap --arch=amd64 $SLVN_VERSION $SLVN_ROOTFS http://deb.debian.org/debian

mkdir -p ${SLVN_ROOTFS}/boot/efi
mount ${SLVN_BLOCK}p1 ${SLVN_ROOTFS}/boot/efi
