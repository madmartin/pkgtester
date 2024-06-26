#!/bin/bash
#
# configuration file
# sets configurable options in shell variables
#

# @VARIABLE: DIR_BASE
# @DESCRIPTION:
# This is the base directory where all files are placed, downloaded archives and
# qcow2 images
DIR_BASE="/data/virt/package-tester/"

# @VARIABLE: DIR_NFS_SHARES
# @DESCRIPTION:
# Directory which holds subdirectoris for binpkgs-$ARCH, distfiles and work-dir
DIR_NFS_SHARES="$DIR_BASE"

# @VARIABLE: DIR_IMAGE_MOUNT
# @DESCRIPTION:
# Directory where the qcow2 disk image will be mounted
DIR_IMAGE_MOUNT=/mnt/new

# @VARIABLE: NFS_SERVER
# @DESCRIPTION:
# IP address of the NFS server, seen from the virtual machine view. This is
# usually the virtualization host's ip for the libvirt network where the
# virtual machine is attached to.
NFS_SERVER="192.168.122.1"

# @VARIABLE: FSTAB_ADDON_LINES
# @DESCRIPTION:
# Array with lines to add to /etc/fstab, e.g. private overlays
FSTAB_ADDON_LINES=(
	"# mount my overlay"
	"192.168.122.1:/var/db/repos/my-overlay/ /var/db/repos/my-overlay nfs defaults 0 0"
)

# @VARIABLE: FSTAB_ADDON_DIRS
# @DESCRIPTION:
# Array with directories which must be created in disk image
FSTAB_ADDON_DIRS=( "/var/db/repos/md-private" "/mnt/X" "/mnt/Y" )

# @VARIABLE: DISK_SIZE
# @DESCRIPTION:
# the disk image size in bytes. Optional suffixes k or K (kilobyte, 1024)
# M (megabyte, 1024k) and G (gigabyte, 1024M) and T (terabyte, 1024G) are supported.
DISK_SIZE=20G

# @VARIABLE: VM_LOCALE
# @DESCRIPTION:
# which locale should be set in the virtual machine
VM_LOCALE="de_DE.utf8"

# @VARIABLE: VM_KEYBOARD_KEYMAP
# @DESCRIPTION:
# Name of the Keymap that should be set in the virtual machine
VM_KEYBOARD_KEYMAP="de-latin1-nodeadkeys"

# @VARIABLE: VM_TIMEZONE
# @DESCRIPTION:
# Name of the timezone that should be set in the virtual machine
VM_TIMEZONE="Europe/Berlin"

# @VARIABLE: REPO_SQUASHFS
# @DESCRIPTION:
# Wnen set to yes, the portage tree will be put as squashfs image into the disk image
# (and then mounted r/o)
# In all other cases, the portage tree will be copied
REPO_SQUASHFS="yes"

# @VARIABLE: ADD_OVERLAYS_LIST
# @DESCRIPTION:
# List of overlay names. The content of all overlays listed here will be trans-
# ferred into the image. The location of the overlay directory is read from
# /etc/layman/layman.cfg
# Note: for images that contain "musl" in the name, the "musl" overlay is auto-
# matically added.
# Overlays in the list, that are currently not found on the base system, will be
# automatically added and set to the disabled state
# (disabled overlays are synced but not recognized by portage)
ADD_OVERLAYS_LIST=""
#ADD_OVERLAYS_LIST="vdr-devel"

# @VARIABLE: ADD_SSH_PUBKEYS
# @DESCRIPTION:
# Array of ssh public keys to add to /root/.ssh/authorized_keys
ADD_SSH_PUBKEYS=(
	"#comment 1"
	"ssh-rsa <our ssh key here>"
	"#comment 2" )

# @VARIABLE:
# @DESCRIPTION:
#

# @VARIABLE:
# @DESCRIPTION:
#

# @VARIABLE:
# @DESCRIPTION:
#

# @VARIABLE:
# @DESCRIPTION:
#
