#!/bin/bash

set -e

virt-sysprep --add $SLVN_DISK_IMAGE --hostname default-hostname --operations defaults,-ssh-userdir
virt-sysprep --add $SLVN_DISK_IMAGE --enable machine-id
virt-sparsify --in-place $SLVN_DISK_IMAGE

echo "Compressing disk..."
qemu-img convert -c -O qcow2 $SLVN_DISK_IMAGE $SLVN_DISK_IMAGE.compressed
rm $SLVN_DISK_IMAGE && mv $SLVN_DISK_IMAGE.compressed $SLVN_DISK_IMAGE
