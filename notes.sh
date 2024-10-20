clean() {
    set +e

    umount ${$SLVN_ROOTFS}/dev/pts
    umount ${$SLVN_ROOTFS}/dev
    umount ${$SLVN_ROOTFS}/proc
    umount ${$SLVN_ROOTFS}/sys
    umount ${$SLVN_ROOTFS}/tmp
}


mkdir -p "${SLVN_DIST}/live"

sudo debootstrap \
    --arch=amd64 \
    ${SLVN_VERSION} \
    "${$SLVN_ROOTFS}" \
    http://deb.debian.org/debian

echo "debian-live" | sudo tee "${$SLVN_ROOTFS}/etc/hostname"

mount --bind /dev ${$SLVN_ROOTFS}/dev
mount -t devpts /dev/pts ${$SLVN_ROOTFS}/dev/pts
mount -t proc proc ${$SLVN_ROOTFS}/proc
mount -t sysfs sysfs ${$SLVN_ROOTFS}/sys
mount -t tmpfs tmpfs ${$SLVN_ROOTFS}/tmp

chroot  ${$SLVN_ROOTFS} /bin/bash <<EOF

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
apt-get autoremove --purge -y

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
    tmux \
    btrfs-progs \
    bash-completion \
    openssh-server \
    linux-image-amd64 \
    live-boot \
    systemd-sysv

apt-get autoremove -y --purge
apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

passwd root

# Done!
exit

EOF

umount ${$SLVN_ROOTFS}/dev/pts
umount ${$SLVN_ROOTFS}/dev
umount ${$SLVN_ROOTFS}/proc
umount ${$SLVN_ROOTFS}/sys
umount ${$SLVN_ROOTFS}/tmp

mkdir -p "${SLVN_DIST}/live"/{staging/{EFI/BOOT,boot/grub/x86_64-efi,isolinux,live},tmp}


sudo mksquashfs \
    "${$SLVN_ROOTFS}" \
    "${SLVN_DIST}/live/staging/live/filesystem.squashfs" \
    -e boot


cp "${$SLVN_ROOTFS}/boot"/vmlinuz-* \
    "${SLVN_DIST}/live/staging/live/vmlinuz" && \
cp "${$SLVN_ROOTFS}/boot"/initrd.img-* \
    "${SLVN_DIST}/live/staging/live/initrd"


cat <<'EOF' > "${SLVN_DIST}/live/staging/isolinux/isolinux.cfg"
UI vesamenu.c32

MENU TITLE Boot Menu
DEFAULT linux
TIMEOUT 600
MENU RESOLUTION 640 480
MENU COLOR border       30;44   #40ffffff #a0000000 std
MENU COLOR title        1;36;44 #9033ccff #a0000000 std
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all
MENU COLOR unsel        37;44   #50ffffff #a0000000 std
MENU COLOR help         37;40   #c0ffffff #a0000000 std
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std
MENU COLOR msg07        37;40   #90ffffff #a0000000 std
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std

LABEL linux
  MENU LABEL Debian Live [BIOS/ISOLINUX]
  MENU DEFAULT
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live

LABEL linux
  MENU LABEL Debian Live [BIOS/ISOLINUX] (nomodeset)
  MENU DEFAULT
  KERNEL /live/vmlinuz
  APPEND initrd=/live/initrd boot=live nomodeset
EOF

cat <<'EOF' > "${SLVN_DIST}/live/staging/boot/grub/grub.cfg"
insmod part_gpt
insmod part_msdos
insmod fat
insmod iso9660

insmod all_video
insmod font

set default="0"
set timeout=30

# If X has issues finding screens, experiment with/without nomodeset.

menuentry "Debian Live [EFI/GRUB]" {
    search --no-floppy --set=root --label DEBLIVE
    linux ($root)/live/vmlinuz boot=live
    initrd ($root)/live/initrd
}

menuentry "Debian Live [EFI/GRUB] (nomodeset)" {
    search --no-floppy --set=root --label DEBLIVE
    linux ($root)/live/vmlinuz boot=live nomodeset
    initrd ($root)/live/initrd
}
EOF

cp "${SLVN_DIST}/live/staging/boot/grub/grub.cfg" "${SLVN_DIST}/live/staging/EFI/BOOT/"

cat <<'EOF' > "${SLVN_DIST}/live/tmp/grub-embed.cfg"
if ! [ -d "$cmdpath" ]; then
    # On some firmware, GRUB has a wrong cmdpath when booted from an optical disc.
    # https://gitlab.archlinux.org/archlinux/archiso/-/issues/183
    if regexp --set=1:isodevice '^(\([^)]+\))\/?[Ee][Ff][Ii]\/[Bb][Oo][Oo][Tt]\/?$' "$cmdpath"; then
        cmdpath="${isodevice}/EFI/BOOT"
    fi
fi
configfile "${cmdpath}/grub.cfg"
EOF


cp /usr/lib/ISOLINUX/isolinux.bin "${SLVN_DIST}/live/staging/isolinux/" && \
cp /usr/lib/syslinux/modules/bios/* "${SLVN_DIST}/live/staging/isolinux/"

cp -r /usr/lib/grub/x86_64-efi/* "${SLVN_DIST}/live/staging/boot/grub/x86_64-efi/"

grub-mkstandalone -O i386-efi \
    --modules="part_gpt part_msdos fat iso9660" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="${SLVN_DIST}/live/staging/EFI/BOOT/BOOTIA32.EFI" \
    "boot/grub/grub.cfg=${SLVN_DIST}/live/tmp/grub-embed.cfg"

grub-mkstandalone -O x86_64-efi \
    --modules="part_gpt part_msdos fat iso9660" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="${SLVN_DIST}/live/staging/EFI/BOOT/BOOTx64.EFI" \
    "boot/grub/grub.cfg=${SLVN_DIST}/live/tmp/grub-embed.cfg"


(cd "${SLVN_DIST}/live/staging" && \
    dd if=/dev/zero of=efiboot.img bs=1M count=20 && \
    mkfs.vfat efiboot.img && \
    mmd -i efiboot.img ::/EFI ::/EFI/BOOT && \
    mcopy -vi efiboot.img \
        "${SLVN_DIST}/live/staging/EFI/BOOT/BOOTIA32.EFI" \
        "${SLVN_DIST}/live/staging/EFI/BOOT/BOOTx64.EFI" \
        "${SLVN_DIST}/live/staging/boot/grub/grub.cfg" \
        ::/EFI/BOOT/
)

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "${SLVN_DISK_IMAGE}" \
    -full-iso9660-filenames \
    -volid "DEBLIVE" \
    --mbr-force-bootable -partition_offset 16 \
    -joliet -joliet-long -rational-rock \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-boot \
        isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog isolinux/isolinux.cat \
    -eltorito-alt-boot \
        -e --interval:appended_partition_2:all:: \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B ${SLVN_DIST}/live/staging/efiboot.img \
    "${SLVN_DIST}/live/staging"
