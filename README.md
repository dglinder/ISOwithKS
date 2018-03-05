# ISOwithKS
Goal: Create a framework to automate the production of customized RedHat/CentOS ISOs to aid deployment to bare-metal systems where network boot options are not available.

Usage
=====

Execute the '''make_iso.sh''' script, then answer the questions.
 * The script must run as root, enter your password for sudo if prompted.
 * Which ISO? Choose (copy-and-paste) the entire ISO name presented.

The script will execute on any errors, so a successfull run should end with something like this:

    Built ISO available here:
    /opt/rh/tmp//rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso
    -rw-r--r-- 1 root root 4183703552 Mar  5 11:22 /opt/rh/tmp//rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso
    -rw-r--r-- 1 root root        168 Mar  5 11:23 /opt/rh/tmp//rhel-server-7.4-x86_64-dvd_tempdir/custom-rhel-server-7.4-x86_64-dvd.20180305_112238.iso.sha256sum
    Exiting using exit function.

The iso listed should match with the sha256 checksum in the smaller file.
