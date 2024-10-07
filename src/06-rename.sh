#!/bin/bash

ls -lash $SLVN_DISK_IMAGE

ln $SLVN_DISK_IMAGE ./dist/slvn-debian-$SLVN_VERSION-uefi-cloud-latest.img
