# ISOwithKS
Goal: Create a framework to automate the production of customized RedHat/CentOS ISOs to aid deployment to bare-metal systems where network boot options are not available.

Usage
=====

Execute the '''make_iso.sh''' script, then answer the questions.
 * The script must run as root, enter your password for sudo if prompted.
 * Choose the full name of the ISO to start with, then enter the entire ISO name presented.

The script will execute on any errors, so a successfull run should end with something like this:

    Built ISO available here:
    /opt/rh/tmp//rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso
    -rw-r--r-- 1 root root 4183703552 Mar  5 11:22 /opt/rh/tmp//rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso
    -rw-r--r-- 1 root root        168 Mar  5 11:23 /opt/rh/tmp//rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso.sha256sum
    Exiting using exit function.

The iso listed should match with the sha256 checksum in the smaller file.

Details of execution
====================

At a high level the script performs the following steps:
1. Prompts the user for the name of the ISO to build from.
  * Or the system will take the name of the ISO from the command line.
1. The script verifies that the customization information in '''media_info''' exists for this ISO.
1. The ISO file is mounted at '''${BUILDDIR}/isomount/''' and the contents are extracted to '''${BUILDDIR}/image/'''
  * These are gloval variables that can be customized.
  * See the *Customization* section below.
1. The customization information is loaded from the '''./media_info/${ISONAME}.info.sh''' file
  * The file is a shell script format and sets variables used later in the '''make_iso.sh''' script.
  * Necessary variables are checked; the script exits if any are missing.
1. The various legacy and UEFI boot configuration files are updated
  * Values from the '''media_info''' files are used to update the files.
1. An ISO is built and stored in the '''${BUILDDIR}''' directory.
  * The ISO begins with "custom-" and has the timestamp embedded in the name for tracking.
 
Customization
=============

The script has some global variables set at the top of the file that are necessary to configure for your specific build environment.

 * '''BUILDROOT''' : This path is where the resulting ISO as well as the temporary files used during the customizatino process are stored.
 * '''GOLDENISO''' : This is the path to the ISO files downloaded from the vendor, e.g. RedHat.com, etc.


