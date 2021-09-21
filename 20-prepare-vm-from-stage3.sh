#!/bin/bash
#
# create virtual machine image from stage3 image

pause() {
	local Answer=""
	echo "Pause."
	echo -n "Enter to continue: "
	read Answer
}


# read parameters

if [ -n "$1" ]; then
	STAGE3="$1"
else
	STAGE3="stage3-amd64-systemd-20201206T214503Z.tar.xz"
	echo "default image: $STAGE3"
fi
STAGE3=$(readlink --canonicalize $STAGE3)
if [ ! -e "$STAGE3" ]; then
	echo "Stage3 image $STAGE3 does not exist. exit."
fi

set -x -v -e

# VM_NAME=pkg-tester
DISK_NAME="${STAGE3%.tar.*}.qcow2"
DISK_SIZE=20G
echo "VM Disk Name: $DISK_NAME"


if [ -e $DISK_NAME ]; then
	set +x +v +e
	echo
	echo
	echo "Disk $DISK_NAME exists, exit"
	exit 1
fi

cd $(dirname $0)

qemu-img create -f qcow2 "$DISK_NAME" "$DISK_SIZE"


 

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

# trap on exit or STRG-C
trap 'set +e; umount /mnt/new/dev/ /mnt/new/sys/ /mnt/new/proc/; umount /mnt/new/; qemu-nbd --disconnect /dev/nbd0; rmmod nbd' EXIT TERM INT

modprobe nbd max_part=8
sleep 1

qemu-nbd --connect=/dev/nbd0 "$DISK_NAME"
sleep 1

fdisk /dev/nbd0 -l
parted --script --align optimal /dev/nbd0 mklabel msdos -- mkpart primary xfs 1 -0
mkfs.xfs -L pkgtester /dev/nbd0p1


mount /dev/nbd0p1 /mnt/new/

pause

pushd /mnt/new/
#tar xvf "$STAGE3"
# root #tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
tar xpvf "$STAGE3" --xattrs-include='*.*' --numeric-owner

rsync -a --progress /usr/portage/ var/db/repos/gentoo
mount -o bind /dev/ /mnt/new/dev/
mount -o bind /sys/ /mnt/new/sys/
mount -o bind /proc/ /mnt/new/proc/

cp /etc/locale.gen  /mnt/new/etc/locale.gen
cp /etc/resolv.conf /mnt/new/etc/resolv.conf
cp /root/.aliases /mnt/new/root/.aliases

popd

cp ??-inside-*-prepare-vm-from-stage3.sh /mnt/new/
set +x +v +e

echo "do CHROOT, your next step is: run the script /30-inside-chroot-prepare-vm-from-stage3.sh now!"
chroot /mnt/new/

echo
echo "VM disk image file: $DISK_NAME"

# on exit, "trap" umounts all etc.

