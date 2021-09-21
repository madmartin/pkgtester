# pkgtester
Helps you to create virtual machines from gentoo stage3 images for qemu

This script collection assists in creating disk images for virtual machines out of gentoo stage3 images. Mainly targeted for testing ebuilds, the virtual machines may be used for other purposes as well.

#### What it does:

- download "latest" marked stage3 archive from gentoo website
- create a qcow2 image file, partition and format it
- mount image, unpack stage3 archive into image
- install kernel and bootloader into image

#### What it does not:

- fully automate the creation of virtual machines

***
#### Requirements
On the machine where this scripts should run on you need:

- qemu
- nbd kernel module (Network Block Device)
- curl
- xfsprogs, xfs filesystem support in kernel
- recommended: libvirt, virt-manager

#### How to use:
All scripts except the download script must run as user "root".


***
### Ideas for enhancements:
- make configurable variables and options, put them in a separate conf file
- add support for openrc stage3 variants
- put gentoo tree into a mountable squashfs instead of rsyncing the files it into image (should be configurable)
- Gentoo download site says musl stages need the musl overlay in the installation. Implement this.

