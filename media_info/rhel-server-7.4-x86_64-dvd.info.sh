#!/bin/sh
# Media info for the rhel-server-7.4-x86_64-dvd.iso
SHA256SUM=""

KSNAME="RHEL7.ks"
CDLABEL="RHEL-7.4 Server"

# If the ISO supports MBR booting, here is the menu entry to use.
DO_MBR=1
# If DO_MBR==1, MBR_FIND = String to look for to replace with MBR_MENU in MBR_MENUFILE
MBR_MENUFILE=""
MBR_FIND=""
MBR_MENU=""

# If the ISO supports UEFI booting, here is the menu entry to use.
DO_UEFI=1
# If DO_UEFI==1, UEFI_FIND = String to look for to replace with UEFI_MENU in UEFI_MENUFILE
UEFI_MENUFILE=""
UEFI_FIND=""
UEFI_MENU="menuentry Custom_Kickstart_Installation --class fedora --class gnu-linux --class gnu --class os {
        linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=RHEL-7.2\x20Server.x86_64 quiet inst.ks=cdrom:/ks.cfg
        initrdefi /images/pxeboot/initrd.img
}"



