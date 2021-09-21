#!/bin/bash
#
# create virtual machine from stage3 image
# this must be run inside chroot

# chroot /mnt/new/

LANG=C

# check if we are really inside the chrooted system
if [ -e /30-inside-chroot-prepare-vm-from-stage3.sh ]; then
	echo "inside chroot, start working"
else
	echo "not inside chroot, exit"
	exit 1
fi

# necessary base settings
locale-gen
eselect locale set de_DE.utf8
. /etc/profile

# set a root password
echo "root:root123.." | chpasswd

# determine which ARCH we have here
ARCH=$(eselect profile list | head -n 2 | awk --field-separator "/" '/default/ { print $3; }')

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

# populate fstab
cat >>/etc/fstab <<EOF
LABEL=pkgtester / xfs noatime 0 1

192.168.122.1:/data/virt/package-tester/work /root/work nfs defaults 0 0
192.168.122.1:/data/virt/package-tester/distfiles /var/cache/distfiles nfs defaults 0 0
192.168.122.1:/data/virt/package-tester/binpkgs-$ARCH /var/cache/binpkgs nfs defaults 0 0
192.168.122.1:/var/lib/layman/md-private /var/db/repos/md-private nfs defaults 0 0
EOF

# create mountpoints
mkdir -p /var/db/repos/md-private /root/work

# install sys-kernel/gentoo-kernel-bin
emerge -av sys-kernel/gentoo-kernel-bin sys-boot/grub net-fs/nfs-utils
# grub-install --target=i386-pc --boot-directory=./boot/ /dev/nbd0
grub-install --target=i386-pc /dev/nbd0
grub-mkconfig -o /boot/grub/grub.cfg


# cleanup distfiles, nfs share is later mounted on top of this
find /var/cache/distfiles/ -type f -delete

# configure network
systemctl enable systemd-networkd
systemctl enable sshd
echo "PermitRootLogin yes" >>/etc/ssh/sshd_config

cat >/etc/systemd/network/10-enp1s0.network <<EOF
[Match]
Name=enp1s0

[Network]
DHCP=yes
EOF

# set unstable keywords for packages I work with, ~amd64
cat >/etc/portage/package.accept_keywords <<EOF
dev-embedded/esptool ~amd64
media-tv/oscam ~amd64
sys-fs/btrfsmaintenance ~amd64
dev-python/reedsolomon ~amd64
app-admin/passwordsafe ~amd64
net-im/signal-cli-bin ~amd64

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

# now adjust ARCH in case it is not ~amd64
if [ "$ARCH" != "amd64" ]
then
	sed -i "s/amd64/$ARCH/" /etc/portage/package.accept_keywords
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
echo "now leave CHROOT,"
echo "boot virtual machine, then after first login execute"
echo "  /40-inside-running-vm-prepare-vm-from-stage3.sh"
echo
echo "Note: on the first boot, the VM does not configure the network."
echo "Don't panic, this will work after running the script above."

#exit
