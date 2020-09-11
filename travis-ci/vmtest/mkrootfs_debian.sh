#!/bin/bash
# This script builds a Debian root filesystem image for testing libbpf in a
# virtual machine.
set -e -u -x -o pipefail
if [ "$(id -u)" != 0 ]; then
	echo "$0 must run as root" >&2
	exit 1
fi
root=$(mktemp -d -p "$PWD")
trap 'rm -r "$root"' EXIT
mkdir -p .debootstrap
debootstrap \
	--cache-dir="$PWD/.debootstrap" \
	--include=binutils,busybox,elfutils,iproute2,libcap2,libelf1,zlib1g \
	--variant=minbase \
	bullseye "$root"
rm -rf \
	"$root"/etc/rcS.d \
	"$root"/usr/share/{doc,info,locale,man,zoneinfo} \
	"$root"/var/cache/apt/archives/* \
	"$root"/var/lib/apt/lists/*
chroot "$root" dpkg --remove --force-remove-essential coreutils
"$(dirname "$0")"/mkrootfs_tweak.sh "$root"
name="libbpf-vmtest-rootfs-$(date +%Y.%m.%d).tar.zst"
rm -f "$name"
tar -C "$root" -c . | zstd -T0 -19 -o "$name"
