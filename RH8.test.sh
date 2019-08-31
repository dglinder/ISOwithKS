#!/usr/bin/env bash
# Notes: https://access.redhat.com/solutions/60959
set -e
set -u

ISO='/home/dan/tmp/ISOs/rhel-8.0-x86_64-dvd.iso'
NEWISO='/var/tmp/rhel8new.iso'

# Get the LABEL variable
export $(blkid -o export "${ISO}")

BUILDDIR="$(mktemp -d /var/tmp/temp_expand.XXX)"
UEFI_MENUFILE="isolinux/isolinux.cfg"
GRUB_MENUFILE="EFI/BOOT/grub.cfg"
TMPMOUNT="$(mktemp -d /var/tmp/temp_mount.XXX)"

MYKS="./rhel8.ks"
MYKS="./ksfiles/RHEL7.ks"

UEFI_START="^label\ linux"
UEFI_END="label linux"
UEFI_MENU="label kickstart
  menu label ^Dans Custom Kickstart Installation of RHEL8.0
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=${LABEL} inst.ks=cdrom:/ks.cfg

label linux"

GRUB_START="### BEGIN .etc.grub.d.10_linux ###"
GRUB_END="menuentry 'Install Red Hat Enterprise Linux 8.0.0' --class fedora --class gnu-linux --class gnu --class os {"
GRUB_CFG="### BEGIN /etc/grub.d/10_linux ###
menuentry 'Install CUSTOM Red Hat Enterprise Linux 8.0' --class fedora --class gnu-linux --class gnu --class os {
    linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${LABEL} inst.ks=cdrom:/ks.cfg
    initrdefi /images/pxeboot/initrd.img
}
${GRUB_END}"

sudo mount -o loop,ro ${ISO} ${TMPMOUNT}

mkdir -p "${BUILDDIR}"
shopt -s dotglob
cp -aRf ${TMPMOUNT}/* ${BUILDDIR}

cp ${MYKS} ${BUILDDIR}/ks.cfg

echo "################################################"
echo "# Fix up the isolinux.cfg"
echo "#"
# Save initial isolinux/ directory permissions
INIT_PERM=$(stat -c%a ${BUILDDIR})

chmod u+w "${BUILDDIR}/$(dirname ${UEFI_MENUFILE})"
chmod u+w "${BUILDDIR}/${UEFI_MENUFILE}"
awk -v sb="${UEFI_MENU}" "/${UEFI_START}/,/${UEFI_END}/ { if ( \$0 ~ /${UEFI_START}/) print sb; next } 1" "${BUILDDIR}/${UEFI_MENUFILE}" > "${BUILDDIR}/${UEFI_MENUFILE}.new"
echo "Added these lines to the ${BUILDDIR}/${UEFI_MENUFILE} file:"
/usr/bin/diff "${BUILDDIR}/${UEFI_MENUFILE}" "${BUILDDIR}/${UEFI_MENUFILE}.new" | cat -n
echo "Diff done"

cp "${BUILDDIR}/${UEFI_MENUFILE}.new" "${BUILDDIR}/${UEFI_MENUFILE}"
# Restore permissions
chmod ${INIT_PERM} "${BUILDDIR}/$(dirname ${UEFI_MENUFILE})"

echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
echo "################################################"
echo "# Fix up the grub.cfg"
echo "#"
# Save initial isolinux/ directory permissions
INIT_PERM=$(stat -c%a ${BUILDDIR}/$(dirname ${GRUB_MENUFILE}))
#INIT_PERM2=$(stat -c%a ${BUILDDIR}/${GRUB_MENUFILE})

chmod u+w "${BUILDDIR}/$(dirname ${GRUB_MENUFILE})"
chmod u+w "${BUILDDIR}/${GRUB_MENUFILE}"
awk -v sb="${GRUB_CFG}" "/${GRUB_START}/,/${GRUB_END}/ { if ( \$0 ~ /${GRUB_START}/) print sb; next } 1" "${BUILDDIR}/${GRUB_MENUFILE}" > "${BUILDDIR}/${GRUB_MENUFILE}.new"
echo "Added these lines to the ${BUILDDIR}/${GRUB_MENUFILE} file:"
/usr/bin/diff "${BUILDDIR}/${GRUB_MENUFILE}" "${BUILDDIR}/${GRUB_MENUFILE}.new" | cat -n
echo "Diff done"

cp "${BUILDDIR}/${GRUB_MENUFILE}.new" "${BUILDDIR}/${GRUB_MENUFILE}"

# Restore permissions
chmod ${INIT_PERM} "${BUILDDIR}/$(dirname ${GRUB_MENUFILE})"

pushd ${BUILDDIR}/
ls -altr .
echo Running mkisofs
sudo mkisofs -o ${NEWISO} -b isolinux/isolinux.bin \
	-J -R -l -c isolinux/boot.cat -no-emul-boot \
	-boot-load-size 4 -boot-info-table -eltorito-alt-boot \
	-e images/efiboot.img -no-emul-boot -graft-points \
	-V "RHEL-8.0 Server.x86_64" . | egrep -iv ^Using

echo Running isohybrid on ISO
sudo isohybrid --uefi ${NEWISO}


