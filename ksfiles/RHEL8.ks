lang en_US
REM *** Modify the network settings to reflect required 
REM *** network settings.  
network --bootproto dhcp 
REM *** The IP address should be the address of the 
REM *** Linux repository server. The /SHAREVOL/RedHatCD 
REM *** must be shared as an NFS volume.  
nfs --server 192.1.1.3 --dir /SHAREVOL/RedHatCD 
device ethernet eepro100 
keyboard "us" 
zerombr yes 
clearpart --Linux 
part /boot --size 30 
part swap --size 128 
part / --size 100 --grow 
install 
mouse genericps/2 
timezone Etc/GMT-6 
#xconfig --server "Mach64" --monitor "generic monitor" 
skipx 
rootpw today123
auth --useshadow --enablemd5 
lilo --location partition 
reboot 
%packages 
ElectricFence 
setup 
filesystem 
basesystem
ldconfig
glibc
shadow-utils
mkkickstart
mktemp
termcap
libtermcap
bash
MAKEDEV
SysVinit
XFree86-Mach64
ncurses
info
grep
XFree86-libs
chkconfig
XFree86-xfs
anacron
anonftp
fileutils
mailcap
textutils
apache
apmd
arpwatch
ash
at
authconfig
autoconf
automake
yp-tools
ypbind
ypserv
zlib
zlib-devel
%end
%post
