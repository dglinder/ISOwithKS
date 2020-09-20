#!/bin/sh
# Media info for the rhel-server-7.4-x86_64-dvd.iso
SHA256SUM="b45e345f33e3ba22bfff5b21b30a371247864c832220a54b143c454078886e4c"

KSNAME="fedora-coreos-32.ks"
CDLABEL="fedora-coreos-32.20200824.3.0"
CDLABEL_FIXED=$(echo ${CDLABEL} | sed 's/\ /\\\\x20/g')

BOOTSTRAP_NODE="coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.65.237:8080/okd4/fcos.raw.xz coreos.inst.ignition_url=http://192.168.65.237:8080/okd4/bootstrap.ign"
CONTROLPLANE_NODE="coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.65.237:8080/okd4/fcos.raw.xz coreos.inst.ignition_url=http://192.168.65.237:8080/okd4/master.ign"
COMPUTE_NODE="coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.65.237:8080/okd4/fcos.raw.xz coreos.inst.ignition_url=http://192.168.65.237:8080/okd4/worker.ign"
#############################################
# If the ISO supports MBR booting, here is the menu entry to use.
#
DO_MBR=1
# If DO_MBR==1, Replace tex in MBR_MENUFILE between MBR_START
# and MBR_END with MBR_MENU
MBR_MENUFILE="image/isolinux/isolinux.cfg"
# NOTE: These match on a line, so the WHOLE LINE WILL BE CHANGED.
MBR_START="^label linux"
MBR_END="^####"
MBR_MENU="label linux
  menu label ^Fedora CoreOS (Live) Customized for Bootstrap Node
  menu default
  kernel /images/pxeboot/vmlinuz
  append initrd=/images/pxeboot/initrd.img,/images/ignition.img mitigations=auto,nosmt systemd.unified_cgroup_hierarchy=0 coreos.liveiso=fedora-coreos-32.20200824.3.0 ignition.firstboot ignition.platform.id=metal ${BOOTSTRAP_NODE}
"
#
#############################################

#############################################
# If the ISO supports UEFI booting, here is the menu entry to use.
#
DO_UEFI=1
# If DO_UEFI==1, UEFI_FIND = String to look for to replace with UEFI_MENU in UEFI_MENUFILE
UEFI_MENUFILE="image/EFI/fedora/grub.cfg"
UEFI_START="^menuentry.*Fedora CoreOS"
UEFI_END="metal$"
UEFI_MENU="menuentry 'Fedora CoreOS (Live) - Bootstrap Node' --class fedora --class gnu-linux --class gnu --class os {
      linux /images/pxeboot/vmlinuz mitigations=auto,nosmt systemd.unified_cgroup_hierarchy=0 coreos.liveiso=fedora-coreos-32.20200824.3.0 ignition.firstboot ignition.platform.id=metal ${BOOTSTRAP_NODE}
}
"
#
#############################################

#echo ==== DEBUG: CDLABEL : ${CDLABEL}
#echo ==== DEBUG: CDLABEL_FIXED : ${CDLABEL_FIXED}
#echo ==== DEBUG: UEFI_MENU: ${UEFI_MENU}
#echo "==== DEBUG: UEFI_MENU: ${UEFI_MENU}"

