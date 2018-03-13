#!/bin/sh
# Media info for the rhel-server-6.9-x86_64-dvd.iso
SHA256SUM="9a4b22bf3fc9d7cddc6b93570f1fabc35039109487c65827baf5e427a24333da"

KSNAME="RHEL6.ks"
CDLABEL="RHEL-6.9 Server.x86_64"
CDLABEL_FIXED=$(echo ${CDLABEL} | sed 's/\ /\\\\x20/g')

#############################################
# If the ISO supports MBR booting, here is the menu entry to use.
#
DO_MBR=1
# If DO_MBR==1, MBR_FIND = String to look for to replace with MBR_MENU in MBR_MENUFILE
MBR_MENUFILE="image/isolinux/isolinux.cfg"
# NOTE: These match on a line, so the WHOLE LINE WILL BE CHANGED.
MBR_START="^label linux"
MBR_END="append initrd=initrd.img"
MBR_MENU="label bootlocal
  localboot 0x80
  menu default

label custom
  menu label Install ^Custom Red Hat Enterprise Linux 6.9
  kernel vmlinuz
  append initrd=initrd.img ks=cdrom:/ks.cfg

label linux
  menu label ^Install or upgrade an existing system
  kernel vmlinuz
  append initrd=initrd.img
"
#
#############################################

#############################################
# If the ISO supports UEFI booting, here is the menu entry to use.
#
DO_UEFI=0
# If DO_UEFI==1, UEFI_FIND = String to look for to replace with UEFI_MENU in UEFI_MENUFILE
UEFI_MENUFILE="image/EFI/BOOT/grub.cfg"
UEFI_START="^menuentry.*Install Red Hat Enterprise Linux"
UEFI_END="^}"
UEFI_MENU="menuentry 'Custom Red Hat Enterprise Linux 7.4' --class fedora --class gnu-linux --class gnu --class os {
      linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${CDLABEL_FIXED} inst.ks=cdrom:/ks.cfg biosdevname=0 net.ifnames=0
      initrdefi /images/pxeboot/initrd.img
}
"
#
#############################################

#echo ==== DEBUG: CDLABEL : ${CDLABEL}
#echo ==== DEBUG: CDLABEL_FIXED : ${CDLABEL_FIXED}
#echo ==== DEBUG: UEFI_MENU: ${UEFI_MENU}
#echo "==== DEBUG: UEFI_MENU: ${UEFI_MENU}"

