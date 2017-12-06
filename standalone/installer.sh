#!/sbin/sh
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2015-2017 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.

SCRIPT="$1"
OUTFD="$2"
ZIP="$3"
ARCH="$(getprop ro.product.cpu.abi)"

print() {
	echo "ui_print [+] $*" >&$OUTFD
}

die() {
	echo "ui_print [-] $*" >&$OUTFD
	exit 1
}

cleanup() {
	mount -o ro,remount /system
	rm -rf /tmp/wireguard
}

mount_system() {
	local slot dev

	if grep -q /system /proc/mounts; then
		print "Remounting system partition r/w"
		mount -o rw,remount /system
	else
		print "Mounting system partition"

		slot="$(getprop ro.boot.slot_suffix)"
		[ -z "$slot" ] && slot="$(getprop ro.boot.slot)"

		dev="$(find /dev/block -iname "system$slot" -print | head -n 1)"
		[ -n "$dev" ] || die "Could not find system partition"

		mount -o rw "$dev" /system || die "Could not mount system partition"
	fi
}

echo "ui_print ==================================" >&$OUTFD
echo "ui_print =          WireGuard Tools       =" >&$OUTFD
echo "ui_print =             by zx2c4           =" >&$OUTFD
echo "ui_print =         www.wireguard.com      =" >&$OUTFD
echo "ui_print ==================================" >&$OUTFD

trap cleanup INT TERM EXIT

mount_system

rm -rf /tmp/wireguard
mkdir -p /tmp/wireguard
print "Extracting files"
unzip -d /tmp/wireguard "$ZIP"
[ -d /tmp/wireguard/arch/$ARCH ] || die "Not available for device's ABI"
print "Installing WireGuard tools"
cp /tmp/wireguard/arch/$(getprop ro.product.cpu.abi)/* /system/xbin/
cp /tmp/wireguard/addon.d/40-wireguard.sh /system/addon.d/
chmod 755 /system/xbin/wg /system/xbin/wg-quick /system/addon.d/40-wireguard.sh

mkdir -pm 700 /data/misc/wireguard
print "Success! Be sure your kernel has the WireGuard module enabled."
