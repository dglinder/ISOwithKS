#!/usr/bin/env sh
set -x
set -e

#################################
# Global variables to tweak.
#
# Location to build IOS in
BUILDROOT=/home/dan/tmp/
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
  rmdir ${BUILDDIR}/isomount/
  rmdir ${BUILDDIR}/
}
trap clean_exit EXIT

#################################
# Show user the possible ISO files to use
echo "List of available ISOs"
ls -1 ./golden_isos/ | cat -n
ISONAME="bogus"

while [ ! -e "./golden_isos/${ISONAME}" ] ; do
  read -p "Please enter the full name of the ISO to use: " ISONAME
  if [ ! -e "./golden_isos/${ISONAME}" ] ; then
    echo "Invalid ISO name.  Try again."
  fi
done

BUILDDIR=$(mktemp -d ${ISONAME}_tempdir_XXXX --tmpdir=${BUILDROOT})

mkdir ${BUILDDIR}/isomount/
mount -o loop ./golden_isos/${ISONAME} ${BUILDDIR}/isomount/



