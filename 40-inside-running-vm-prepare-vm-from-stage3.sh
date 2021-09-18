#!/bin/bash
#
# create virtual machine from stage3 image
# this must be run inside running VM with systemd

LANG=C

# check if we are really inside the virtual server
if [ -e /40-inside-running-vm-prepare-vm-from-stage3.sh ]; then
	if lscpu | grep -e "BIOS Vendor.*QEMU" -q
	then
		echo "inside virtual machine, start working"
	else
		echo "not inside virtual machine, exit"
		exit 1
	fi
else
	echo "not inside chroot/vm, exit"
	exit 1
fi

set -e -x -v

ARCH=$(eselect profile list | head -n 2 | awk --field-separator "/" '/default/ { print $3; }')

# configure hostname
hostnamectl set-hostname "pkgtester-$ARCH"

# configure keyboard layout
localectl set-keymap de-latin1-nodeadkeys

# configure timezone
timedatectl set-timezone Europe/Berlin

# create machine id, VERY important for networking
systemd-machine-id-setup

