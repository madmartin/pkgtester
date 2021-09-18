#!/bin/bash

set -x -e -v

if [ -n "$1" ]; then
	ARCH="$1"
else
	ARCH=amd64
fi

virsh snapshot-list --domain pkgtester-$ARCH
virsh snapshot-revert --domain pkgtester-$ARCH --snapshotname base-snap
virsh snapshot-list --domain pkgtester-$ARCH
virsh start pkgtester-$ARCH

