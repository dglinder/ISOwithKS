#!/bin/sh
# Media info for the rhel-server-7.4-x86_64-dvd.iso
SHA256SUM=""

KSNAME="RHEL7.ks"
CDLABEL="RHEL-7.4 Server.x86_64"
CDLABEL_FIXED=$(echo ${CDLABEL} | sed 's/\ /\\\\x20/g')

# If the ISO supports MBR booting, here is the menu entry to use.
DO_MBR=1
# If DO_MBR==1, MBR_FIND = String to look for to replace with MBR_MENU in MBR_MENUFILE
MBR_MENUFILE="image/isolinux/isolinux.cfg"
MBR_FIND="append initrd=initrd.img"
MBR_MENU="append initrd=initrd.img inst.ks=cdrom:\/ks.cfg"

# If the ISO supports UEFI booting, here is the menu entry to use.
DO_UEFI=1
# If DO_UEFI==1, UEFI_FIND = String to look for to replace with UEFI_MENU in UEFI_MENUFILE
UEFI_MENUFILE="image/EFI/BOOT/grub.cfg"
UEFI_FIND="menuentry "
UEFI_MENU="menuentry 'Custom Red Hat Enterprise Linux 7.4' --class fedora --class gnu-linux --class gnu --class os {
      linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${CDLABEL_FIXED} inst.ks=cdrom:/ks.cfg
      initrdefi /images/pxeboot/initrd.img
}"


echo ==== DEBUG: CDLABEL : ${CDLABEL}
echo ==== DEBUG: CDLABEL_FIXED : ${CDLABEL_FIXED}
echo ==== DEBUG: UEFI_MENU: ${UEFI_MENU}

