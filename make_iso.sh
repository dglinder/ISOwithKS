#!/usr/bin/env sh
# Automatically add the company custom kickstart file to a UEFI CD Image
#
# Based on notes from:
#  - http://www.tuxfixer.com/mount-modify-edit-repack-create-uefi-iso-including-kickstart-file/
#
#set -x
set -e

#################################
# Global variables to tweak.
#
# Location to build IOS in
BUILDROOT=/home/dan/tmp/
# Menu entry for the custom image menu entry
# TODO - Get the new menu entry PER ISO (RHEL-7.2 in the LABEL), or dynamically generate it from the first menuentry.
# For RedHat 7.2 ISO
NEWMENU="menuentry Custom_Kickstart_Installation --class fedora --class gnu-linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.2\x20Server.x86_64 quiet inst.ks=cdrom:/ks.cfg
        initrdefi /images/pxeboot/initrd.img
}"
# For Centos ISO
NEWMENU="menuentry Custom_Kickstart_Installation --class fedora --class gnu-linux --class gnu --class os {
	linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=CentOS\x207\x20x86_64 quiet inst.ks=cdrom:/ks.cfg
	initrdefi /images/pxeboot/initrd.img
}"
#
# Timestamp for the image:
TS=$(date +%Y%m%d_%H%M%S)
#
#################################

#################################
# Ensure root permissions
if [ `id -u` -gt 0 ] ; then
  echo Must run as root...
  sudo $0 $*
  exit
fi

#################################
# Code to catch an exit and cleanup temp files.
#
function clean_exit {
  echo "Exiting using exit function."
  umount ${BUILDDIR}/isomount/
#  rmdir ${BUILDDIR}/isomount/
#  rmdir ${BUILDDIR}/
}
trap clean_exit EXIT

#################################
# Show user the possible ISO files to use
echo "List of available ISOs"
ls -1 ./golden_isos/ | cat -n
ISONAME="bogus"
if [ ! -z "$1" ] ; then
  ISONAME="$1"
  echo "Using command line ISO: ${ISONAME}"
fi

KSNAME="bogus"
if [ ! -z "$2" ] ; then
  KSNAME="$2"
  echo "Using command line kickstart: ${KSNAME}"
fi

while [ ! -e "./golden_isos/${ISONAME}" ] ; do
  read -p "Please enter the full name of the ISO to use: " -i "${ISONAME}" ISONAME
  if [ ! -e "./golden_isos/${ISONAME}" ] ; then
    echo "Invalid ISO name.  Try again."
  fi
done

#BUILDDIR=$(mktemp -d ${ISONAME}_tempdir_XXXX --tmpdir=${BUILDROOT})
BUILDDIR="${BUILDROOT}/${ISONAME}_tempdir"

mkdir -p ${BUILDDIR}/
mkdir -p ${BUILDDIR}/isomount/
mkdir -p ${BUILDDIR}/image/
mount -o loop ./golden_isos/${ISONAME} ${BUILDDIR}/isomount/

# Copy contents of ISO to new working directory
echo "Copying contents from ISO to ${BUILDDIR}/image/"
rsync -a ${BUILDDIR}/isomount/ ${BUILDDIR}/image/

# Copy the kickstart file into the ISO directory
rsync -a ./ksfiles/${KSNAME} ${BUILDDIR}/image/ks.cfg

# Edit the grub.conf in the ../EFI/BOOT/ directory:
# 0: Backup the original for debugging
cp ${BUILDDIR}/image/EFI/BOOT/grub.cfg ${BUILDDIR}/image/EFI/BOOT/grub.cfg.orig

# 1: Change the menuentry title:
sed -i.$(date +%s) '0,/menuentry /s//ABCDEFGHIJ\nmenuentry /' ${BUILDDIR}/image/EFI/BOOT/grub.cfg

# 2: Insert new text:
INJECT=$(echo "${NEWMENU}" | sed ':a;N;$!ba;s/\n/\\n/g')
sed -i.$(date +%s) "s#ABCDEFGHIJ#${INJECT}#" ${BUILDDIR}/image/EFI/BOOT/grub.cfg

#################################
# Now build the ISO image
#
# mkisofs -o /tmp/rhel_7.2_uefi_custom.iso -b isolinux/isolinux.bin \
#         -J -R -l -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
#         -boot-info-table -eltorito-alt-boot -e images/efiboot.img \
#         -no-emul-boot -graft-points -V "RHEL-7.2 Server.x86_64" \
#         /mnt/custom_rhel72_image/

mkisofs -o ${BUILDDIR}/custom-${ISONAME}.iso -b isolinux/isolinux.bin \
        -J -R -l -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \
        -boot-info-table -eltorito-alt-boot -e images/efiboot.img \
        -no-emul-boot -graft-points -V "CentOS 7 x86_64 " \
        ${BUILDDIR}/image/

echo "Built ISO available here:"
echo "${BUILDDIR}/custom-${ISONAME}.iso"
ls -al "${BUILDDIR}/custom-${ISONAME}.iso"


