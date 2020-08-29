#!/sbin/sh

# Reads and sets properties for decryption

finish()
{
    umount /v
    umount /s
    rmdir /v
    rmdir /s
    setprop crypto.ready 1
    exit 0
}

suffix=$(getprop ro.boot.slot_suffix)
if [ -z "$suffix" ]; then
    suf=$(getprop ro.boot.slot)
    suffix="_$suf"
fi
venpath="/dev/block/bootdevice/by-name/vendor$suffix"
mkdir /v
mount -t ext4 -o ro "$venpath" /v
syspath="/dev/block/bootdevice/by-name/system$suffix"
mkdir /s
mount -t ext4 -o ro "$syspath" /s

is_fastboot_twrp=$(getprop ro.boot.fastboot)
if [ ! -z "$is_fastboot_twrp" ]; then
    osver=$(getprop ro.build.version.release_orig)
    patchlevel=$(getprop ro.build.version.security_patch_orig)
    setprop ro.build.version.release "$osver"
    setprop ro.build.version.security_patch "$patchlevel"
    setprop ro.vendor.build.security_patch "2018-06-05"
    finish
fi

build_prop_path="/s/build.prop"
if [ -f /s/system/build.prop ]; then
    build_prop_path="/s/system/build.prop"
fi

vendor_prop_path="/v/build.prop"
if [ -f "$build_prop_path" ]; then
    # TODO: It may be better to try to read these from the boot image than from /system
    osver=$(grep -i 'ro.build.version.release' "$build_prop_path"  | cut -f2 -d'=')
    patchlevel=$(grep -i 'ro.build.version.security_patch' "$build_prop_path"  | cut -f2 -d'=')
    vendorlevel=$(grep -i 'ro.vendor.build.security_patch' "$vendor_prop_path"  | cut -f2 -d'=')
    setprop ro.build.version.release "$osver"
    setprop ro.build.version.security_patch "$patchlevel"
    setprop ro.vendor.build.security_patch "$vendorlevel"
else
    # Be sure to increase the PLATFORM_VERSION in build/core/version_defaults.mk to override Google's anti-rollback features to something rather insane
    osver=$(getprop ro.build.version.release_orig)
    patchlevel=$(getprop ro.build.version.security_patch_orig)
    setprop ro.build.version.release "$osver"
    setprop ro.build.version.security_patch "$patchlevel"
    setprop ro.vendor.build.security_patch "2018-06-05"
fi
finish

