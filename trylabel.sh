ISO='/home/dan/tmp/ISOs/rhel-8.0-x86_64-dvd.iso'
export $(blkid -o export "${ISO}")
echo "ISO Label: >>${LABEL}<<"

# awk -v sb="${UEFI_MENU}" "/${UEFI_START}/,/${UEFI_END}/ { if ( \$0 ~ /${UEFI_START}/) print sb; next } 1" "${BUILDDIR}/${UEFI_MENUFILE}.${local_TS}" > "${BUILDDIR}/${UEFI_ MENUFILE}"

UEFI_MENU="label kickstart
  menu label ^Dans Custom Kickstart Installation of RHEL8.0
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=${LABEL} inst.ks=cdrom:/ks.cfg

label linux
  menu label ^Install Red Hat Enterprise Linux 8.0.0
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-8-0-0-BaseOS-x86_64 quiet

"

UEFI_START="^label\ linux"
UEFI_END="label linux"

BUILDDIR="/tmp/temp_expand.8jP/"
UEFI_MENUFILE="isolinux/isolinux.cfg"

# cat /tmp/temp_expand.8jP/isolinux/isolinux.cfg | awk -v sb="${UEFI_MENU}" "/${UEFI_START}/,/${UEFI_END}/ { if ( \$0 ~ /${UEFI_START}/) print sb; next } 1" "${BUILDDIR}/${UEFI_MENUFILE}" | egrep -C5 "label kickstart"

awk -v sb="${UEFI_MENU}" "/${UEFI_START}/,/${UEFI_END}/ { if ( \$0 ~ /${UEFI_START}/) print sb; next } 1" "${BUILDDIR}/${UEFI_MENUFILE}" | egrep -C5 "label kickstart"

