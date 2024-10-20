#!/bin/bash

set -e

mkdir -p ${SLVN_DIST}/final/{staging/{EFI/BOOT,boot/grub/x86_64-efi,isolinux,live},tmp}

mksquashfs \
    ${SLVN_ROOTFS} \
    ${SLVN_DIST}/final/staging/live/filesystem.squashfs \
    -e boot

cp ${SLVN_ROOTFS}/boot/vmlinuz-* ${SLVN_DIST}/final/staging/live/vmlinuz
cp ${SLVN_ROOTFS}/boot/initrd.img-* ${SLVN_DIST}/final/staging/live/initrd

cat <<EOF > ${SLVN_DIST}/final/staging/isolinux/isolinux.cfg
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

cat <<EOF > ${SLVN_DIST}/final/staging/boot/grub/grub.cfg
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

cp ${SLVN_DIST}/final/staging/boot/grub/grub.cfg ${SLVN_DIST}/final/staging/EFI/BOOT/

cat <<EOF > ${SLVN_DIST}/final/tmp/grub-embed.cfg
if ! [ -d "$cmdpath" ]; then
    # On some firmware, GRUB has a wrong cmdpath when booted from an optical disc.
    # https://gitlab.archlinux.org/archlinux/archiso/-/issues/183
    if regexp --set=1:isodevice '^(\([^)]+\))\/?[Ee][Ff][Ii]\/[Bb][Oo][Oo][Tt]\/?$' "$cmdpath"; then
        cmdpath="${isodevice}/EFI/BOOT"
    fi
fi
configfile "${cmdpath}/grub.cfg"
EOF

cp /usr/lib/ISOLINUX/isolinux.bin ${SLVN_DIST}/final/staging/isolinux/
cp /usr/lib/syslinux/modules/bios/* ${SLVN_DIST}/final/staging/isolinux/
cp -r /usr/lib/grub/x86_64-efi/* ${SLVN_DIST}/final/staging/boot/grub/x86_64-efi/

grub-mkstandalone -O i386-efi \
    --modules="part_gpt part_msdos fat iso9660" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="${SLVN_DIST}/final/staging/EFI/BOOT/BOOTIA32.EFI" \
    "boot/grub/grub.cfg=${SLVN_DIST}/final/tmp/grub-embed.cfg"

grub-mkstandalone -O x86_64-efi \
    --modules="part_gpt part_msdos fat iso9660" \
    --locales="" \
    --themes="" \
    --fonts="" \
    --output="${SLVN_DIST}/final/staging/EFI/BOOT/BOOTx64.EFI" \
    "boot/grub/grub.cfg=${SLVN_DIST}/final/tmp/grub-embed.cfg"


(cd "${SLVN_DIST}/final/staging" && \
    dd if=/dev/zero of=efiboot.img bs=1M count=20 && \
    mkfs.vfat efiboot.img && \
    mmd -i efiboot.img ::/EFI ::/EFI/BOOT && \
    mcopy -vi efiboot.img \
        "${SLVN_DIST}/final/staging/EFI/BOOT/BOOTIA32.EFI" \
        "${SLVN_DIST}/final/staging/EFI/BOOT/BOOTx64.EFI" \
        "${SLVN_DIST}/final/staging/boot/grub/grub.cfg" \
        ::/EFI/BOOT/
)

xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "${SLVN_DIST}/slvn.iso" \
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
    -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B ${SLVN_DIST}/final/staging/efiboot.img \
    "${SLVN_DIST}/final/staging"
