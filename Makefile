#!/usr/bin/make -f

# Global
export SLVN_VERSION = bookworm
export SLVN_ROOTFS = ./dist/rootfs
export SLVN_DIST = ./dist

.PHONY: all
all: cloud

.PHONY: clean
clean:
	rm -rf $(SRC_CLOUD)/dist

# Cloud
SRC_CLOUD = ./src/cloud
cloud: export SLVN_BLOCK = /dev/nbd0
cloud: export SLVN_DISK_IMAGE = ./dist/slvn-debian-$SLVN_VERSION-uefi-cloud-latest.img
cloud: $(SRC_CLOUD)/*.sh
	$(MAKE) clean
	cd $(SRC_CLOUD)/; $(foreach s, $^, echo "Running $(realpath $s)..."; bash "$(realpath $s)" || exit 1;)
