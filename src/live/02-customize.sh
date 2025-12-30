#!/bin/bash

set -e

clean() {
    set +e
    umount $SLVN_ROOTFS/dev/pts
    umount $SLVN_ROOTFS/dev
    umount $SLVN_ROOTFS/proc
    umount $SLVN_ROOTFS/sys
    umount $SLVN_ROOTFS/tmp
}
trap 'clean' EXIT

# Mount
mount --bind /dev ${SLVN_ROOTFS}/dev
mount -t devpts /dev/pts ${SLVN_ROOTFS}/dev/pts
mount -t proc proc ${SLVN_ROOTFS}/proc
mount -t sysfs sysfs ${SLVN_ROOTFS}/sys
mount -t tmpfs tmpfs ${SLVN_ROOTFS}/tmp

chroot $SLVN_ROOTFS /bin/bash <<EOF

set -e

export DEBIAN_FRONTEND=noninteractive

cat >/etc/apt/sources.list <<EOL
deb [arch=amd64] http://deb.debian.org/debian ${SLVN_VERSION} main non-free-firmware
deb [arch=amd64] http://deb.debian.org/debian ${SLVN_VERSION}-updates main non-free-firmware
deb [arch=amd64] http://deb.debian.org/debian ${SLVN_VERSION}-backports main non-free-firmware
deb [arch=amd64] http://security.debian.org/debian-security ${SLVN_VERSION}-security main non-free-firmware
EOL

apt-get update
apt-get dist-upgrade -y

# Locales
apt-get install -y \
    locales

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
echo 'LANG=en_US.UTF-8' > /etc/default/locale
locale-gen

# Basic packages.
apt-get install -y \
    bmon \
    htop \
    wget \
    curl \
    nmon \
    ncdu \
    traceroute \
    mtr-tiny \
    dnsutils \
    tmux \
    btrfs-progs \
    bash-completion \
    openssh-server \
    openssh-client \
    linux-image-amd64 \
    live-boot \
    systemd-timesyncd \
    cryptsetup \
    debootstrap \
    arch-install-scripts \
    parted \
    dosfstools \
    python3

apt-get autoremove -y --purge
apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Hostname
echo "debian-live" > /etc/hostname

# Login TTY Screen
echo "Time: \\d \\t" >> /etc/issue
echo "IPv4: \\4" >> /etc/issue
echo "IPv6: \\6" >> /etc/issue

# Authorized Keys
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAotshvvlSdxIHJpVyZEd+wO2Y22U63nihJ9yFBIlpv0 ed25519-gen3-level3" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Root User Password
usermod -p '\$6\$m3rp1XaBgcDgGVj5\$DgZhEYp31DXKcuAi6a10zHELK6V64cfKRtUmo2XxjBUs.DlrFhkJlZupgJhzoUug/wj9GUaEQlmjWmJAo97IH1' root

exit
EOF
