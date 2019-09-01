# ISOwithKS

Goal: Create a framework to automate the production of customized RedHat/CentOS ISOs to aid deployment to bare-metal systems where network boot options are not available.

## Usage

Execute the ```make_iso.sh``` script, then answer the questions.

 * The script must run as root, enter your password for sudo if prompted.
 * Choose the full name of the ISO to start with, then enter the entire ISO name presented.

The script will execute on any errors, so a successfull run should end with something like this:

    Built ISO available here:
    /opt/rh/tmp/rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso
    -rw-r--r-- 1 root root 4183703552 Mar  5 11:22 /opt/rh/tmp/rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso
    -rw-r--r-- 1 root root        168 Mar  5 11:23 /opt/rh/tmp/rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso.sha256sum
    Exiting using exit function.

The iso listed should match with the sha256 checksum in the smaller file.

## Details of execution

At a high level the script performs the following steps:

1. Prompts the user for the name of the ISO to build from.
* Or the system will take the name of the ISO from the command line.
1. The script verifies that the customization information in ```media_info``` exists for this ISO.
1. The ISO file is mounted at ```${BUILDDIR}/isomount/``` and the contents are extracted to ```${BUILDDIR}/image/```
* These are gloval variables that can be customized.
* See the *Customization* section below.
1. The customization information is loaded from the ```./media_info/${ISONAME}.info.sh``` file
* The file is a shell script format and sets variables used later in the ```make_iso.sh``` script.
* Necessary variables are checked; the script exits if any are missing.
1. The various legacy and UEFI boot configuration files are updated
* Values from the ```media_info``` files are used to update the files.
1. An ISO is built and stored in the ```${BUILDDIR}``` directory.
* The ISO begins with "custom-" and has the timestamp embedded in the name for tracking.

## Customization

### Script customizations

The ```make_iso.sh``` script has some global variables set at the top of the file that are necessary to configure for your specific build environment.

* ```BUILDROOT``` : This path is where the resulting ISO as well as the temporary files used during the customizatino process are stored.
* ```GOLDENISO``` : This is the path to the ISO files downloaded from the vendor, e.g. RedHat.com, etc.

### Configuration files

The script relies on a number of ISO specific files to properly configure the final ISO correctly as new cutomized installation distributions are necessary.  A knowledge of common Unix shell scripting tools such as ```awk```, ```sed```, ```rsync```, and ```mkisofs```.

The script first includes the variables setup within the ```media_info``` directory.  The specific file that is included is based on the name of the ISO file chosen with the ".iso" removed.  Each of these files defines these variables:

* ```SHA256SUM``` : (currently optional) The SHA256 checksum of the ISO image to enure the starting ISO is valid.
* ```DO_MBR``` and ```DO_UEFI``` : When set to ```1```, the script will configure the MBR and/or UEFI boot options.

Both of the MBR and UEFI seections use the same variables, differing only in their prefix (```MBR_``` or ```UEFI_```).  The following variables are prepended with either of these text strings replacing the ```X_```.

* ```X_MENUFILE``` : This variable points to the text configuration file, normally the ```isolinux.cfg``` or ```grub.conf``` file that will be edited.
```
    MBR_MENUFILE="image/isolinux/isolinux.cfg"
```
* ```X_START``` : The string in this variable is a REGEXP search string
```
    MBR_START="^label linux"
```
* ```X_END``` : x
 ```
   MBR_END="append initrd=initrd.img"
```
* ```X_MENU``` : x
```
    MBR_MENU="label bootlocal
      localboot 0x80
      menu default

    label custom
      menu label Install ^Custom Red Hat Enterprise Linux 7.4
      kernel vmlinuz
      append initrd=initrd.img inst.stage2=hd:LABEL=${CDLABEL_FIXED} inst.ks=cdrom:/ks.cfg biosdevname=0 net.ifnames=0

    label linux
      menu label ^Install Red Hat Enterprise Linux 7.4
      kernel vmlinuz
      append initrd=initrd.img inst.stage2=hd:LABEL=RHEL-7.4\x20Server.x86_64 quiet
    "
```
