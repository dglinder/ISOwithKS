#authselect --enableshadow --passalgo=sha512

# Use CDROM installation media
cdrom

# Use text install
text

# Get the user provided drive information.
%include /tmp/ks-destdrive.ks
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Network information
%include /tmp/ks-network.ks

rootpw Today123!

# System services
services --enabled="chronyd"

# System timezone
timezone Etc/GMT --utc --ntpservers=t1.ntp.company.com,t2.ntp.company.com,t3.ntp.company.com,t4.ntp.company.com,t5.ntp.company.com,t6.ntp.company.com

# Disk partitioning information
volgroup rootvg --pesize=4096 pv.155
# Can't use the --useexisting or --noformat flags when we specify logvol members
logvol swap     --fstype="swap"  --size=2048  --name=swap   --vgname=rootvg
logvol /        --fstype="ext4"  --size=1024  --name=rootlv --vgname=rootvg
logvol /usr     --fstype="ext4"  --size=10240 --name=usrlv  --vgname=rootvg
logvol /home    --fstype="ext4"  --size=2048  --name=homelv --vgname=rootvg
logvol /var     --fstype="ext4"  --size=4096  --name=varlv  --vgname=rootvg
logvol /var/log --fstype="ext4"  --size=5120  --name=loglv  --vgname=rootvg
logvol /tmp     --fstype="ext4"  --size=4096  --name=tmplv  --vgname=rootvg
logvol /opt     --fstype="ext4"  --size=2048  --name=optlv  --vgname=rootvg

eula --accept

%packages --ignoremissing
@core
kexec-tools
libedit
gfdisk
# Only put in packages that are installable on all systems (physical, virtual)
# so this kickstart file can be leveraged in all environments for consistency.
# Include basic ssh tools for communication and remote Ansible work.
openssh
openssh-clients
openssh-server
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

########################################
#
# Begin %pre section
#
%pre --interpreter=/bin/bash  --log=/tmp/ks-pre01.log
# Show debugging commands as they are run: "set -x"
#set -x
# Exit pre-script on ANY ERROR with following "set -e"
set -e
# Ensure any un-set variables are caught
set -u

iotty=`tty`
exec < $iotty > $iotty 2> $iotty

# Defaults that may vary depending on build
def_hn=""
def_dom="company.com"
def_ip=""
def_mask="255.255."
def_gw=""
def_dns="10.65.116.124,10.70.1.149"
network_hostname="bogus"
network_dnsdomain="bogus"
network_ipaddr="bogus"
network_netmask="bogus"
network_gateway="bogus"
setup_bonding="y"
nic_list="eth0"
good_config="n"

while [ "${good_config}" == "n" ] ; do
  ################################################################
  # Clean up from any previous runs
  #
  rm -f /tmp/ks-network.ks /tmp/ks-destdrive.ks

  ################################################################
  # Collect minimal information to jump-start system onto network
  #
  clear
  echo "################################################################"
  echo "# Basic networking"
  echo "#"
  echo "Please enter this systems network information:"
  read -p "Hostname of this system:   " -ei "${def_hn}"   network_hostname
  read -p "DNS domain of this system: " -ei "${def_dom}"  network_dnsdomain
  read -p "IP address of this system: " -ei "${def_ip}"   network_ipaddr
  netmask_sane="no"
  while [ "${netmask_sane}" == "no" ] ; do
    read -p "IP netmask of this system: " -ei "${def_mask}" network_netmask
    # Need to temporarialy ignore error codes returned for this grep.
    set +e
    echo ${network_netmask} | grep -w -E -o '^(254|252|248|240|224|192|128).0.0.0|255.(254|252|248|240|224|192|128|0).0.0|255.255.(254|252|248|240|224|192|128|0).0|255.255.255.(254|252|248|240|224|192|128|0)' > /dev/null
    exit_code=$?
    # Re-enable exit code watching in script.
    set -e
    if [ ${exit_code} -ne 0 ]; then
      echo "### ERROR >>>>>>-<<<<<< ERROR ###"
      echo "--> Invalid netmask : ${network_netmask} <--"
      echo "### ERROR >>>>>>-<<<<<< ERROR ###"
      netmask_sane="no"
    else
      netmask_sane="yes"
    fi
  done
  read -p "DNS  to use initially:     " -ei "${def_dns}"  def_dns
  # Compute the base network to pre-fill for the gateway.
  IFS=. read -r i1 i2 i3 i4 <<< "${network_ipaddr}"
  IFS=. read -r m1 m2 m3 m4 <<< "${network_netmask}"
  def_gw=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$(( (i4 & m4) + 1 ))")
  read -p "IP address of the gateway: " -ei "${def_gw}"   network_gateway
  echo ""

  # Set the default values if we have to re-run the setup loop.
  def_hn=${network_hostname}
  def_dom=${network_dnsdomain}
  def_ip=${network_ipaddr}
  def_mask=${network_netmask}
  def_dns=${def_dns}

  #
  ################################################################

  ################################################################
  # Setup bonding if desired
  #
  # Bonding notes:
  # URL: https://access.redhat.com/solutions/2150361
  #      https://access.redhat.com/solutions/1474223
  #      * So if vlan id is 100 and base interface is bond0, then correct parameter would be vlan=vlan100:bond0
  #
  clear
  echo "################################################################"
  echo "# Network interface bonding"
  echo "#"
  echo "Network devices found on this system:"
  ip link show
  echo "-- end of list --"
  echo ""
  read -p "Is network bonding to be setup? (yes/no): " -ei "${setup_bonding}" setup_bonding
  echo ""
  # Convert to lower case
  setup_bonding=$( echo "${setup_bonding}" | tr "[:upper:]" "[:lower:]" )
  # strip off first character so y==yes/yup/yeppers, n==no/nope/never
  setup_bonding=$( echo "${setup_bonding}" | cut -c 1 )

  if [ "${setup_bonding}" == "y" ] ; then
    echo "Bonding will be ENABLED."
    echo ""
    echo "Enter a comma separated list of TWO"
    read -p "network devices to use for bonding: " -ei "${nic_list}" nic_list
    nic_inuse=$( echo "${nic_list},lo,bond0" | sed 's/,/|/g')
    # Write the BONDING network information for the installer:
    cat<<END_BOND >/tmp/ks-network.ks
network --device=bond0 --bootproto=static --activate --ip=${network_ipaddr} --netmask=${network_netmask} --gateway=${network_gateway} --hostname=${network_hostname} --teamslaves="${nic_list}" --teamconfig='{"runner": {"name": "activebackup"}}' --nameserver=${def_dns} --hostname ${network_hostname}.${network_dnsdomain}
END_BOND
  else
    echo "Bonding will be DISABLED"
    echo ""
    read -p "Enter the network devices to use: " -ei "${nic_list}" nic_list
    nic_inuse=$( echo "${nic_list},lo" | sed 's/,/|/g')
    # Write the SINGLE NIC network information for the installer:
    cat<<END_NET >/tmp/ks-network.ks
network --device=${nic_list} --bootproto=static --activate --ip=${network_ipaddr} --netmask=${network_netmask} --gateway=${network_gateway} --hostname=${network_hostname} --nameserver=${def_dns}  --hostname ${network_hostname}.${network_dnsdomain}
END_NET
  fi
  #
#  # Disable all the other un-used NICs
#  all_nic=$(ip ad li | egrep '^[0-9]' | cut -d: -f 2 | sed 's/ //g')
#  disable_nics=$(echo "${all_nic}" | egrep -v "${nic_inuse}")
#  for NIC in ${disable_nics} ; do
#    echo "Disabling $NIC"
#    cat<<END_DISABLE_NIC >> /tmp/ks-network.ks
#network --device=${NIC} --onboot=no
#END_DISABLE_NIC
#  done
  #
  ################################################################

  ################################################################
  # Setup installation destination disk
  #
  clear
  echo "################################################################"
  echo "# Installation destination"
  echo "#"
  echo "Choose installation destination drive name:"
  OIFS="${IFS}"
  (
    IFS=$'\n'
    HDS="$(list-harddrives)"
    for X in ${HDS} ; do
      diskname=$(echo $X | cut -d\  -f1)
      disksize=$(echo $X | cut -d\  -f2)
      echo "Drive: ${diskname}, ${disksize}MB"
    done
    unset IFS
  )
  echo "--- end of list of hard drives ---"
  echo ""
  read -p "Enter the drive name to install to: " -ei "sda" destdrive

  # Set the DISK/PARITITON information for the installer:
  rm -f /tmp/ks-destdrive.ks

# https://access.redhat.com/discussions/762253
#  if [ ${UEFI}" ] ; then
#    parted -s /dev/${destdrive} mklabel gpt
#    cat <<END_UEFIDISK >>/tmp/ks-destdrive.ks
#part /boot/efi  --fstype='efi'   --ondisk=${destdrive} --size=200
#END_UEFIDISK
#  fi

  cat <<END_DISK >>/tmp/ks-destdrive.ks
# Partition clearing information
clearpart --drives=${destdrive} --all

# Initialize any invalid partition tables
zerombr

# Run the Setup Agent on first boot
firstboot --disabled

# Setup which drive to install to.
ignoredisk --only-use=${destdrive}

# System bootloader configuration
bootloader --append=' crashkernel=auto' --location=mbr --boot-drive=${destdrive}

# Setup initial boot and physical volume.
part biosboot   --fstype='biosboot' --size=1
part /boot      --fstype='ext4'  --ondisk=${destdrive} --size=1024
part /boot/efi  --fstype='efi'   --ondisk=${destdrive} --size=200
part pv.155     --fstype='lvmpv' --ondisk=${destdrive} --size=38912 --grow
END_DISK
  #
  ################################################################

  ################################################################
  # Verify setup configuration
  #
  clear
  echo "################################################################"
  echo "# Review configuration"
  echo "#"
  echo ""
  echo "Full hostname with domain: ${network_hostname}.${network_dnsdomain}"
  echo ""
  echo "Installation drive: ${destdrive}"
  echo "Drive details (gdisk):"
  gdisk -l /dev/${destdrive} | egrep -v '^$|sr0|read-only' | sed 's/^/    /g'
  echo ""
  echo "IP address: ${network_ipaddr}/${network_netmask}"
  echo "Default gateway: ${network_gateway}"
  echo ""
  echo "DNS Server(s): ${def_dns}"
  echo ""
  echo -n "NIC bonding: ${setup_bonding} -"
  if [ "${setup_bonding}" == "y" ] ; then
    echo " BONDED network ports: ${nic_list}"
  else
    echo " SINGLE network port: ${nic_list}"
  fi
  echo ""
  echo "#"
  echo "################################################################"
  echo ""
  echo "Confirm the configuration above, then press return to"
  echo "proceed with installation or enter 'no' to retry."
  read -p "Continue with install? ([yes] or no): " good_config
  if [ "${good_config}" == "" ] ; then
    good_config="y"
  fi
  # Convert to lower case
  good_config=$( echo "${good_config}" | tr "[:upper:]" "[:lower:]" )
  # strip off first character so y==yes/yup/yeppers, n==no/nope/never
  good_config=$( echo "${good_config}" | cut -c 1 )
done
#
################################################################
parted -s /dev/${destdrive} mklabel gpt
%end
#
# End %pre section
#
########################################

########################################
#
# Begin %post section
#
%post --interpreter=/bin/bash --nochroot --log=/mnt/sysimage/root/ks-post01.log
cp /tmp/ks-* /mnt/sysimage/root/
%end
#
%post --interpreter=/bin/bash --log=/root/ks-post02.log
date +"%Y-%m-%d_%H:%M:%S - Kickstart-installed Red Hat Linux" | tee -a /root/Kickstart-notes
date +"%Y-%m-%d_%H:%M:%S - Building $(hostname -f) (FQDN)" | tee -a /root/Kickstart-notes
date +"%Y-%m-%d_%H:%M:%S - Building $(hostname -s) (short hostname)" | tee -a /root/Kickstart-notes
date +"%Y-%m-%d_%H:%M:%S - Mounted filesystems in %post section" | tee -a /root/Kickstart-notes
df -Ph | tee -a /root/Kickstart-notes
if grep -i PACKER /proc/cmdline ; then
  date +"%Y-%m-%d_%H:%M:%S - /proc/cmdline: " $(cat /proc/cmdline) | tee -a /root/Kickstart-notes
fi
sync
%end
#
# End %post section
#
########################################

# RHEL 6 - Move reboot command to top
reboot
