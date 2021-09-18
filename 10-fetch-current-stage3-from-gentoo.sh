#!/bin/bash
#
# download latest x86 & amd64 stage3 image


pause() {
	local Answer=""
	echo "Pause."
	echo -n "Enter to continue: "
	read Answer
}


download_variant() {
	local Arch=$1
	local Variant=$2

	case $Arch in
		x86)	FArch=i686;;
		*)	FArch=$Arch;;
	esac

	#FILE_amd64=$(curl -L  https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/latest-stage3-amd64-systemd.txt | sed '/^#/d' | cut -f1 -d" " )
	#FILE_amd64_musl=$(curl -L  https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/latest-stage3-amd64-musl.txt | sed '/^#/d' | cut -f1 -d" " )
	#FILE_x86=$(curl -L  https://bouncer.gentoo.org/fetch/root/all/releases/x86/autobuilds/latest-stage3-i686-systemd.txt | sed '/^#/d' | cut -f1 -d" " )
	#echo "x86:        https://bouncer.gentoo.org/fetch/root/all/releases/x86/autobuilds/$FILE_x86"
	#echo "amd64:      https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/$FILE_amd64"
	#echo "amd64-musl: https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/$FILE_amd64_musl"

	FILE=$(curl -L  https://bouncer.gentoo.org/fetch/root/all/releases/$Arch/autobuilds/latest-stage3-$FArch-$Variant.txt | sed '/^#/d' | cut -f1 -d" " )
	FILEPATH="https://bouncer.gentoo.org/fetch/root/all/releases/$Arch/autobuilds/$FILE"

	echo "Download URL: $FILEPATH"
	pause
	curl -LO -C - "$FILEPATH" && echo "Download successful."
	echo
}


echo "download latest gentoo stage3 images"
echo "===================================="
echo "  optional parameters: <architecure> <variant>"
echo "  example combinations:"
echo "    $0  amd64 systemd"
echo "    $0  amd64 openrc"
echo "    $0  amd64 musl"
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

