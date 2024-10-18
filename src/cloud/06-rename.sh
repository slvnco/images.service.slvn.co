#!/bin/bash

set -e

ls -lash $SLVN_DISK_IMAGE

ln $SLVN_DISK_IMAGE ./dist/slvn-debian-$SLVN_VERSION-uefi-cloud-$(date '+%Y%m%d').img
