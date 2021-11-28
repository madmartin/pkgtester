#!/bin/bash
#
# download latest x86 & amd64 stage3 image

pause() {
	local Answer=""
	echo "Pause."
	echo -n "Enter to continue: "
	read Answer
}

prepare_directories() {
	[ -e "$DIR_NFS_SHARES/distfiles" ] || mkdir "$DIR_NFS_SHARES/distfiles"
	[ -e "$DIR_NFS_SHARES/work" ] || mkdir "$DIR_NFS_SHARES/work"
	[ -e "$DIR_NFS_SHARES/binpkgs-$1-$2" ] || mkdir "$DIR_NFS_SHARES/binpkgs-$1-$2"
}

download_variant() {
	local Arch=$1
	local Variant=$2

	case $Arch in
		x86)	FArch=i686;;
		*)	FArch=$Arch;;
	esac

	# example URLs
	# https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt
	# https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20210919T170549Z/stage3-amd64-openrc-20210919T170549Z.tar.xz

	# determine the exact filename of the download archive behind "latest-XXXX"
	FILE=$(curl --location "https://bouncer.gentoo.org/fetch/root/all/releases/$Arch/autobuilds/latest-stage3-$FArch-$Variant.txt" | sed '/^#/d' | cut -f1 -d" " )
	FILEPATH="https://bouncer.gentoo.org/fetch/root/all/releases/$Arch/autobuilds/$FILE"

	echo "Download URL: $FILEPATH"
	pause
	curl --remote-name --location --continue-at - "$FILEPATH" && echo "Download successful."
	echo
	prepare_directories $Arch $Variant
}

LANG=C
# source the config file
DIR=$(dirname $0); [ -e "$DIR/00-config.sh" ] && source "$DIR/00-config.sh"
cd $DIR_BASE

echo "download latest gentoo stage3 images"
echo "===================================="
echo "  optional parameters: <architecure> <variant>"
echo "  example combinations:"
echo "    $0  amd64 systemd"
echo "    $0  amd64 openrc"
echo "    $0  amd64 musl"
echo "    $0  amd64 musl-hardened"
echo "    $0  amd64 desktop-openrc"
echo "    $0  amd64 desktop-systemd"
echo "    $0  x86 systemd"
echo
echo "    $0  all"

if [ -z "$1" ]; then
	exit
fi

if [ "$1" = "all" ]
then
	download_variant amd64 systemd
	download_variant amd64 musl
	download_variant x86 systemd
else
	download_variant "$1" "$2"
fi

