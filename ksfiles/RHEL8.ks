#version=RHEL8
ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --none --initlabel
# Use graphical install
graphical
repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream
# Use CDROM installation media
cdrom
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted $6$W8ilqVqQcAfFv3h2$MoBGB.6n0H6N.j3JBxuAREty1HSXUAY0nGOc600t.1AbWLcrLEooBAd2eRLJYzvSp259EANLzukwyV0ik16GB.
# X Window System configuration information
xconfig  --startxonboot
# Run the Setup Agent on first boot
firstboot --enable
# System services
services --disabled="chronyd"
# System timezone
timezone Etc/UTC --isUtc --nontp

%packages
@^graphical-server-environment
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
