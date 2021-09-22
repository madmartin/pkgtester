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

# source the config file
DIR=$(dirname $0); [ -e "$DIR/00-config.sh" ] && source "$DIR/00-config.sh"

# determine $Arch and $Variant from filename
STAGE3=$(ls stage3-*.tar.*)
Arch=$(echo "$STAGE3" | cut -d"-" -f2)
Variant=$(echo "$STAGE3" | cut -d"-" -f3- | rev | cut -d"-" -f2- | rev)
echo "Arch: $Arch - Variant $Variant"

set -e -x -v

INIT=unknown

# check for systemd/openrc
if which systemctl >/dev/null 2>&1
then
	INIT=systemd
fi
if which openrc >/dev/null 2>&1
then
	INIT=openrc
fi

case $INIT in
	systemd)
		# configure hostname
		hostnamectl set-hostname "pkgtester-$Arch"

		# configure keyboard layout
		localectl set-keymap de-latin1-nodeadkeys

		# configure timezone
		timedatectl set-timezone Europe/Berlin

		# create machine id, VERY important for networking
		systemd-machine-id-setup
		;;
	openrc)
		echo "FIXME"
		;;
	*)
		echo "unknonw init system, do nothing"
		;;
esac

