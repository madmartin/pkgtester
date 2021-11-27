#!/bin/bash
#
# create virtual machine image from stage3 image

pause() {
	local Answer=""
	echo "Pause."
	echo -n "Enter to continue: "
	read Answer
}

# source the config file
DIR=$(dirname $0); [ -e "$DIR/00-config.sh" ] && source "$DIR/00-config.sh"
cd $DIR_BASE

# read parameters
if [ -n "$1" ]; then
	STAGE3="$1"
else
	STAGE3="stage3-amd64-systemd-20201206T214503Z.tar.xz"
	echo "no image filename given, use default image file: $STAGE3"
fi
FULL_STAGE3=$(readlink --canonicalize $STAGE3)
if [ ! -e "$FULL_STAGE3" ]; then
	echo "Stage3 image $FULL_STAGE3 does not exist. exit."
	exit
fi

# determine $Arch and $Variant from filename
Arch=$(echo "$STAGE3" | cut -d"-" -f2)
Variant=$(echo "$STAGE3" | cut -d"-" -f3- | rev | cut -d"-" -f2- | rev)
echo "Arch: $Arch - Variant $Variant"
pause

# VM_NAME=pkg-tester
DISK_NAME="${FULL_STAGE3%.tar.*}.qcow2"
echo "VM Disk Name: $DISK_NAME  Size $DISK_SIZE"

if [ -e $DISK_NAME ]; then
	set +x +v +e
	echo
	echo
	echo "Disk $DISK_NAME exists, exit"
	exit 1
fi

qemu-img create -f qcow2 "$DISK_NAME" "$DISK_SIZE"

set -x -v -e

#
# 
# How to mount a qcow2 disk image
#
#This is a quick guide to mounting a qcow2 disk images on your host server. This is useful to reset passwords, edit files, or recover something without the virtual machine running.
#
# Step 1 - Enable NBD on the Host
#
# modprobe nbd max_part=8
#
# Step 2 - Connect the QCOW2 as network block device
#
# qemu-nbd --connect=/dev/nbd0 /var/lib/vz/images/100/vm-100-disk-1.qcow2
#
# Step 3 - Find The Virtual Machine Partitions
#
# fdisk /dev/nbd0 -l
#
# Step 4 - Mount the partition from the VM
#
# mount /dev/nbd0p1 /mnt/somepoint/
#
# Step 5 - After you done, unmount and disconnect
#
# umount /mnt/somepoint/
# qemu-nbd --disconnect /dev/nbd0
# rmmod nbd

LANG=C

# note: operations with nbd seem to need some time in the background, so we add some sleeps


function cleanup() {
	set +e
	echo "umount disks, release qcow2 image"
	cd "$DIR_IMAGE_MOUNT"
	umount dev/ sys/ proc/ var/cache/distfiles var/cache/binpkgs
	cd ..
	umount "$DIR_IMAGE_MOUNT"
	sleep 1
	qemu-nbd --disconnect /dev/nbd0
	sleep 1
	rmmod nbd
}

# trap on exit or STRG-C
trap cleanup EXIT TERM INT

modprobe nbd max_part=8
sleep 1

qemu-nbd --connect=/dev/nbd0 "$DISK_NAME"
sleep 1

fdisk /dev/nbd0 -l
parted --script --align optimal /dev/nbd0 mklabel msdos -- mkpart primary xfs 1 -0
mkfs.xfs -L pkgtester /dev/nbd0p1

mount /dev/nbd0p1 "$DIR_IMAGE_MOUNT"

pause

pushd $DIR_IMAGE_MOUNT

# extract the stage3 archive
#tar xvf "$STAGE3"
# root #tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
tar xpvf "$FULL_STAGE3" --xattrs-include='*.*' --numeric-owner

# create mountpoints
mkdir -p ./root/work

# create STAGE3 image file name as a marker for source file name, for later evaluation
touch "$STAGE3"

# portage tree
rsync -a --progress /usr/portage/ var/db/repos/gentoo

# mount pseude-filesystems
mount -o bind /dev/ dev/
mount -o bind /sys/ sys/
mount -o bind /proc/ proc/

# mount distfiles + binpkgs-filesystems
mount -o bind "$DIR_NFS_SHARES"/distfiles var/cache/distfiles
mount -o bind "$DIR_NFS_SHARES"/binpkgs-$Arch var/cache/binpkgs

cp /etc/locale.gen  etc/locale.gen
cp /etc/resolv.conf etc/resolv.conf
cp /root/.aliases root/.aliases

popd

echo
echo "copy scripts into image"
cp 00-config.sh ??-inside-*-prepare-vm-from-stage3.sh "$DIR_IMAGE_MOUNT"

if [ -e patches ]; then
	echo "directory \"patches\" exists, copy patches to /etc/portage"
	cp -rp patches/ "$DIR_IMAGE_MOUNT"/etc/portage/
fi

set +x +v +e

echo "do CHROOT, your next step is: run the script /30-inside-chroot-prepare-vm-from-stage3.sh now!"
chroot "$DIR_IMAGE_MOUNT"

echo
echo "VM disk image file: $DISK_NAME"

# on exit, "trap" umounts all etc.

