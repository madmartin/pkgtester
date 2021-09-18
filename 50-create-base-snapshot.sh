#!/bin/bash

set -x -e -v

if [ -n "$1" ]; then
	ARCH="$1"
else
	ARCH=amd64
fi

virsh snapshot-list --domain pkgtester-$ARCH
virsh snapshot-create-as --domain pkgtester-$ARCH --name base-snap --description "created by $0 script"
virsh snapshot-list --domain pkgtester-$ARCH
virsh start pkgtester-$ARCH

