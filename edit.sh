#!/bin/sh
set -u
set -e

file="isolinux.cfg.GOLDEN"
tempfile="isolinux.cfg.NEW"

find_start="label linux"
find_end="append initrd.*Server"
sub="label bootlocal
  menu default
  localboot 0x80

label custom
  menu label ^Install Custom Red Hat Enterprise Linux 7.4
  kernel vmlinuz
  append initrd=initrd.img inst.ks=cdrom:/ks.cfg biosdevname=0 net.ifnames=0 inst.stage2=hd:LABEL=RHEL-7.4\x20Server.x86_64
"

echo "Looking for:"
echo "    ${find_start}"
echo "    ${find_end}"
echo ""
echo "Replace with:"
echo "--begin--"
echo "${sub}"
echo "--end--"

cp -f $file $tempfile
awk -v sb="$sub" "/${find_start}/,/${find_end}/ { if ( \$0 ~ /${find_start}/ ) print sb; next } 1" "$file" > "$tempfile"

diff -C2 $file $tempfile


