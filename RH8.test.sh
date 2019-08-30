#!/usr/bin/env bash
# Notes: https://access.redhat.com/solutions/60959
set -e
set -u
set -x

ISO='/home/dan/tmp/ISOs/rhel-8.0-x86_64-dvd.iso'
# Get the LABEL variable
export $(blkid -o export "${ISO}")

BUILDDIR="$(mktemp -d /tmp/temp_expand.XXX)"
UEFI_MENUFILE="isolinux/isolinux.cfg"
TMPMOUNT="$(mktemp -d /tmp/temp_mount.XXX)"

MYKS="./rhel8.ks"
MYKS="./ksfiles/RHEL7.ks"

UEFI_MENU="label kickstart
  menu label ^Dans Custom Kickstart Installation of RHEL8.0
  kernel vmlinuz
  append initrd=initrd.img inst.stage2=hd:LABEL=${LABEL} inst.ks=cdrom:/ks.cfg

label linux"
#  menu label ^Install Red Hat Enterprise Linux 8.0.0
#  kernel vmlinuz
#  append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-8-0-0-BaseOS-x86_64 quiet
#
#"

UEFI_START="^label\ linux"
UEFI_END="label linux"

sudo mount -o loop,ro ${ISO} ${TMPMOUNT}

mkdir -p "${BUILDDIR}"
shopt -s dotglob
cp -aRf ${TMPMOUNT}/* ${BUILDDIR}

cp ${MYKS} ${BUILDDIR}/

# Save initial isolinux/ directory permissions
INIT_PERM=$(stat -c%a ${BUILDDIR})

chmod u+w ${BUILDDIR}/isolinux/
awk -v sb="${UEFI_MENU}" "/${UEFI_START}/,/${UEFI_END}/ { if ( \$0 ~ /${UEFI_START}/) print sb; next } 1" "${BUILDDIR}/${UEFI_MENUFILE}" > "${BUILDDIR}/${UEFI_MENUFILE}.new"

# Restore permissions
chmod ${INIT_PERM} ${BUILDDIR}/isolinux/

vimdiff "${BUILDDIR}/${UEFI_MENUFILE}" "${BUILDDIR}/${UEFI_MENUFILE}.new"

