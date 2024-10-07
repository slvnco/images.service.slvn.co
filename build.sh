#!/bin/bash

export SLVN_VERSION=bookworm
export SLVN_DISK_IMAGE=./dist/slvn-debian-$SLVN_VERSION-uefi-cloud-$(date '+%Y%m%d').img
export SLVN_BLOCK=/dev/nbd0
export SLVN_ROOTFS=./rootfs
export SLVN_DIST=./dist

set -e

for script in ./src/*.sh; do
    echo "Running $script..."
    bash "$script"
    echo "Completed $script."
done
