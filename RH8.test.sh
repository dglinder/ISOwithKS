#!/usr/bin/env bash
clear
# Notes: https://access.redhat.com/solutions/60959
set -e
set -u

ISO='/home/dan/tmp/ISOs/rhel-8.0-x86_64-dvd.iso'
NEWISO='/var/tmp/rhel8new.iso'
TS="$(date)"

# Get the LABEL variable
export $(blkid -o export "${ISO}")

function finish {
	# Cleanup before exit
	sudo umount ${TMPMOUNT}
	#rm -rf ${BUILDDIR} ${TMPMOUNT}
}
trap finish EXIT

#BUILDDIR="$(mktemp -d /var/tmp/temp_expand.XXX)"
#TMPMOUNT="$(mktemp -d /var/tmp/temp_mount.XXX)"
BUILDDIR="/var/tmp/temp_expand"
TMPMOUNT="/var/tmp/temp_mount"
mkdir -p ${BUILDDIR}
mkdir -p ${TMPMOUNT}

echo "Mounting ISO onto ${TMPMOUNT}"
echo "Expanding ISO into ${BUILDDIR}"

MYKS="./ksfiles/RHEL8.ks"

UEFI_MENUFILE="isolinux/isolinux.cfg"
UEFI_START="^label\ linux"
UEFI_END="label linux"
UEFI_MENU="label kickstart
  menu label ^Dans ${TS} Custom UEFI RHEL8.0
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=${LABEL} inst.ks=cdrom:/ks.cfg

label linux"

GRUB_MENUFILE="EFI/BOOT/grub.cfg"
GRUB_START="### BEGIN .etc.grub.d.10_linux ###"
GRUB_END="menuentry 'Install Red Hat Enterprise Linux 8.0.0' --class fedora --class gnu-linux --class gnu --class os {"
GRUB_CFG="### BEGIN /etc/grub.d/10_linux ###
menuentry 'Dans ${TS} Custom MBR RHEL 8.0' --class fedora --class gnu-linux --class gnu --class os {
	linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${LABEL} inst.ks=cdrom:/ks.cfg
	initrdefi /images/pxeboot/initrd.img
}
${GRUB_END}"

sudo mount -o loop,ro ${ISO} ${TMPMOUNT}

mkdir -p "${BUILDDIR}"
shopt -s dotglob
rsync -a --progress --delete ${TMPMOUNT}/* ${BUILDDIR}

cp ${MYKS} ${BUILDDIR}/ks.cfg

echo "################################################"
echo "# Fix up the isolinux.cfg"
echo "#"
# Save initial isolinux/ directory permissions
INIT_PERM_D=$(stat -c%a $(dirname ${BUILDDIR}))
INIT_PERM_F=$(stat -c%a ${BUILDDIR})

chmod u+w "${BUILDDIR}/$(dirname ${UEFI_MENUFILE})"
chmod u+w "${BUILDDIR}/${UEFI_MENUFILE}"
cp -p "${BUILDDIR}/${UEFI_MENUFILE}" "${BUILDDIR}/${UEFI_MENUFILE}.orig"

awk -v sb="${UEFI_MENU}" "/${UEFI_START}/,/${UEFI_END}/ { if ( \$0 ~ /${UEFI_START}/) print sb; next } 1" "${BUILDDIR}/${UEFI_MENUFILE}" > "${BUILDDIR}/${UEFI_MENUFILE}.new"
echo "Added these lines to the ${BUILDDIR}/${UEFI_MENUFILE} file:"
/usr/bin/diff -C8 "${BUILDDIR}/${UEFI_MENUFILE}.orig" "${BUILDDIR}/${UEFI_MENUFILE}.new" | cat -n
echo "Diff done"

cat "${BUILDDIR}/${UEFI_MENUFILE}.new" > "${BUILDDIR}/${UEFI_MENUFILE}"
# Restore permissions
chmod ${INIT_PERM_F} "${BUILDDIR}/${UEFI_MENUFILE}"
chmod ${INIT_PERM_D} "${BUILDDIR}/$(dirname ${UEFI_MENUFILE})"

echo "################################################"
echo "# Fix up the grub.cfg"
echo "#"
# Save initial isolinux/ directory permissions
INIT_PERM_D=$(stat -c%a ${BUILDDIR}/$(dirname ${GRUB_MENUFILE}))
INIT_PERM_F=$(stat -c%a ${BUILDDIR}/${GRUB_MENUFILE})

chmod u+w "${BUILDDIR}/$(dirname ${GRUB_MENUFILE})"
chmod u+w "${BUILDDIR}/${GRUB_MENUFILE}"
cp -p "${BUILDDIR}/${GRUB_MENUFILE}" "${BUILDDIR}/${GRUB_MENUFILE}.orig"

awk -v sb="${GRUB_CFG}" "/${GRUB_START}/,/${GRUB_END}/ { if ( \$0 ~ /${GRUB_START}/) print sb; next } 1" "${BUILDDIR}/${GRUB_MENUFILE}" > "${BUILDDIR}/${GRUB_MENUFILE}.new"
echo "Added these lines to the ${BUILDDIR}/${GRUB_MENUFILE} file:"
/usr/bin/diff -C8 "${BUILDDIR}/${GRUB_MENUFILE}.orig" "${BUILDDIR}/${GRUB_MENUFILE}.new" | cat -n
echo "Diff done"

cp "${BUILDDIR}/${GRUB_MENUFILE}.new" "${BUILDDIR}/${GRUB_MENUFILE}"

# Restore permissions
chmod ${INIT_PERM_F} "${BUILDDIR}/${GRUB_MENUFILE}"
chmod ${INIT_PERM_D} "${BUILDDIR}/$(dirname ${GRUB_MENUFILE})"

pushd ${BUILDDIR}/
echo "################################################"
echo "# Building ${NEWISO}"
echo "#"
sudo rm -f ${NEWISO}
sudo mkisofs -o ${NEWISO} \
	-b isolinux/isolinux.bin \
	-J \
	-R \
	-l \
	-c isolinux/boot.cat \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-eltorito-alt-boot \
	-e images/efiboot.img \
	-no-emul-boot \
	-graft-points \
	-V "${LABEL}" . \
	2>&1 | egrep -v 'estimate finish|^Using\ .*for\ |^Done with:|^Writing:|^Scanning |^Excluded: ..*TRANS.TBL$'

sudo chown ${USER}:$(id -gn) ${NEWISO}

echo "################################################"
echo "# Running isohybrid on ISO"
echo "#"
isohybrid --uefi ${NEWISO}

echo "################################################"
echo "# Running implantisomd5 on ISO"
echo "#"
implantisomd5 ${NEWISO}

popd
echo "Done!"
ls -altr ${NEWISO}


