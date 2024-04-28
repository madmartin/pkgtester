#!/bin/bash
#
# create virtual machine from stage3 image
# this must be run inside chroot

LANG=C

# check if we are really inside the chrooted system
if [ -e /30-inside-chroot-prepare-vm-from-stage3.sh ]; then
	echo "inside chroot, start working"
else
	echo "not inside chroot, exit"
	exit 1
fi

cd /

# source the config file
DIR=$(dirname $0)
[ -e "$DIR/00-config.sh" ] && source "$DIR/00-config.sh"
[ -e "$DIR/01-config.sh" ] && source "$DIR/01-config.sh"

# determine $Arch and $Variant from filename
STAGE3=$(ls /stage3-*.tar.*)
Arch=$(echo "$STAGE3" | cut -d"-" -f2)
Variant=$(echo "$STAGE3" | cut -d"-" -f3- | rev | cut -d"-" -f2- | rev)
echo "Arch: $Arch - Variant $Variant"

# check for systemd/openrc
if which systemctl >/dev/null 2>&1
then
	INIT=systemd
fi
if which openrc >/dev/null 2>&1
then
	INIT=openrc
fi

# necessary base settings
locale-gen
eselect locale set de_DE.utf8
. /etc/profile

# set a root password
echo "root:admin123.." | chpasswd
if [ $? -ne 0 ]; then
	echo
	echo "##########################################"
	echo "# The password could not be set!         #"
	echo "# Before leaving the chroot environment, #"
	echo "# set a password manually!!!!            #"
	echo "##########################################"
	sleep 5
fi

# configure ssh daemon to allow root login with password
echo "PermitRootLogin yes" >>/etc/ssh/sshd_config

# set Use-Flags for minimum features for grub / nfs-utils
cat >>/etc/portage/package.use/zzz_common <<EOF
sys-boot/grub -grub_platforms_efi-64 -fonts -nls -themes
net-fs/nfs-utils -libmount -nfsidmap -nfsv4 -tcpd -uuid
net-nds/rpcbind -tcpd

EOF

# add settings to make.conf
cat >>/etc/portage/make.conf <<'EOF'

## MD: added lines start here

EMERGE_DEFAULT_OPTS="--keep-going --ask-enter-invalid --quiet-build=y --verbose-conflicts --jobs=3"
# build binary packages

#FEATURES="${FEATURES} buildpkg"
EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --buildpkg --buildpkg-exclude 'sys-kernel/gentoo-sources virtual/* acct-group/* acct-user/* */*-bin'"

ACCEPT_LICENSE="* -@EULA"
MAKEOPTS="-j2"

VDR_MAINTAINER_MODE="1"
PORTAGE_ELOG_CLASSES="warn error info log qa"

# xorg
VIDEO_CARDS="vesa qxl"
INPUT_DEVICES="libinput synaptics"

PORTDIR_OVERLAY="
/var/db/repos/md-private/
$PORTDIR_OVERLAY
"


EOF


# add overlay informatino to make.conf
if [ -n "$ADD_OVERLAYS_LIST" ]
then
	echo "PORTDIR_OVERLAY=\"" >>/etc/portage/make.conf
	for OV in $ADD_OVERLAYS_LIST
	do
		if [ -d "$OVERLAY_STORAGE_DIR/$OV" ]
		then
			echo "$OVERLAY_STORAGE_DIR/$OV" >>/etc/portage/make.conf
		fi
	done
	echo '$PORTDIR_OVERLAY' >>/etc/portage/make.conf
	echo '"' >>/etc/portage/make.conf
fi

# populate fstab
cat >>/etc/fstab <<EOF
LABEL=pkgtester / xfs noatime 0 1

$NFS_SERVER:$DIR_NFS_SHARES/work /root/work nfs defaults 0 0
$NFS_SERVER:$DIR_NFS_SHARES/distfiles /var/cache/distfiles nfs defaults 0 0
$NFS_SERVER:$DIR_NFS_SHARES/binpkgs-$Arch-$Variant /var/cache/binpkgs nfs defaults 0 0
EOF

# create a missing directors
mkdir -p /var/lib/nfs/sm 2>&1 >/dev/null

# portage tree
if [ "$REPO_SQUASHFS" = "yes" ]; then
	echo "/var/db/repos/gentoo.sq /var/db/repos/gentoo squashfs defaults 0 0" >>/etc/fstab
	mount /var/db/repos/gentoo
fi

# add additional fstab lines from configuration
printf "%s\n" "${FSTAB_ADDON_LINES[@]}" >>/etc/fstab

# create mountpoints
for D in /root/work ${FSTAB_ADDON_DIRS[@]}
do
	mkdir -p "$D"
done

echo "#######################################"
echo "# doing an emerge @world update now   #"
echo "#######################################"
emerge --ask --verbose --buildpkg=y --autounmask=y --usepkg -DuN @world

# install sys-kernel/gentoo-kernel-bin and others
PACKAGE_LIST="sys-kernel/gentoo-kernel-bin sys-boot/grub net-fs/nfs-utils"
if [ "$INIT" = "openrc" ]; then
	PACKAGE_LIST+=" net-misc/dhcpcd"
fi
echo "#######################################"
echo "# emerging kernel and others now      #"
echo "#######################################"
emerge --ask --verbose --buildpkg=y --autounmask=y --usepkg $PACKAGE_LIST

# grub-install --target=i386-pc --boot-directory=./boot/ /dev/nbd0
grub-install --target=i386-pc /dev/nbd0
grub-mkconfig -o /boot/grub/grub.cfg

case $INIT in
	systemd)
		echo "Found systemd, configure services"
		# systemd: configure network
		systemctl enable systemd-networkd
		systemctl enable sshd

		cat >/etc/systemd/network/10-enp1s0.network <<-EOF
		[Match]
		Name=enp1s0

		[Network]
		DHCP=yes
		EOF
		;;
	openrc)
		echo "Found openrc init system, add services"
		rc-update add sshd
		cd /etc/init.d/
		ln -s net.lo net.enp1s0
		rc-update add net.enp1s0
		# insert some startup depency quirks
		echo 'rc_need="!rpc.idmapd"' >>/etc/conf.d/nfsclient
		echo 'rc_need=localmount' >>/etc/conf.d/sshd
		;;
	*)
		echo "unknonw init system, do nothing"
		;;
esac

# set unstable keywords for packages I work with, ~amd64
# some stage3 images have an existing directory .../package.accept_keywords
if [ ! -e /etc/portage/package.accept_keywords ]; then
	mkdir -p /etc/portage/package.accept_keywords
fi
cat >/etc/portage/package.accept_keywords/mykeywords <<EOF
dev-embedded/esptool ~amd64
media-tv/oscam ~amd64
sys-fs/btrfsmaintenance ~amd64
dev-python/reedsolo ~amd64
app-admin/passwordsafe ~amd64
net-im/signal-cli-bin ~amd64
media-sound/jack ~amd64

media-video/vdr ~amd64
media-tv/gentoo-vdr-scripts ~amd64
sys-process/wait_on_pid ~amd64

app-eselect/eselect-vdr ~amd64
media-fonts/vdrsymbols-ttf ~amd64
media-plugins/vdr-* ~amd64
media-plugins/xbmc-addon-pvr ~amd64
www-misc/vdradmin-am ~amd64
x11-themes/vdr-channel-logos ~amd64
virtual/linuxtv-dvb-headers ~amd64

media-video/naludump ~amd64
media-video/noad ~amd64
sys-firmware/tt-s2-6400-firmware ~amd64
media-tv/v4l-dvb-saa716x ~amd64
EOF

# now adjust $Arch in case it is not ~amd64
if [ "$Arch" != "amd64" ]
then
	sed -i "s/amd64/$Arch/" /etc/portage/package.accept_keywords
fi

# some settings for the bash
cat >/etc/profile.d/history.sh <<EOF
HISTSIZE=2500
HISTCONTROL="ignoreboth"
#HISTCONTROL="ignoredups"
#HISTIGNORE='fg:bg:exit:history:[ \t]*'
HISTTIMEFORMAT='%F %H:%M:%S '
EOF

cat >/etc/profile.d/load-aliases.sh <<EOF
if [ -r ~/.aliases ]
then
        alias sa='alias>~/.aliases'
        source ~/.aliases
fi
EOF

set +x +v

echo
echo
echo "Setup of VM in chroot environment finished."
echo "==========================================="
echo "Whats next? - YOU do:"
echo "exit from this CHROOT (type \"exit\"),"
echo "boot virtual machine, then login with \"root\" / password \"admin123..\""
echo "after first login - execute"
echo "  /40-inside-running-vm-prepare-vm-from-stage3.sh"
echo
echo "Note: on the first boot, the VM does not configure the network."
echo "Don't panic, this will work after running the script above."

#exit
