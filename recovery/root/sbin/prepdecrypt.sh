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

slot_suffix=$(getprop ro.boot.slot_suffix)
vendor_path="/dev/block/bootdevice/by-name/vendor$slot_suffix"
mkdir /v
mount -t ext4 -o ro "$vendor_path" /v
system_path="/dev/block/bootdevice/by-name/system$slot_suffix"
mkdir /s
mount -t ext4 -o ro "$system_path" /s

is_fastboot_twrp=$(getprop ro.boot.fastboot)
if [ ! -z "$is_fastboot_twrp" ]; then
    osver=$(getprop ro.build.version.release_orig)
    patchlevel=$(getprop ro.build.version.security_patch_orig)
    setprop ro.build.version.release "$osver"
    setprop ro.build.version.security_patch "$patchlevel"
    setprop ro.vendor.build.security_patch "2020-06-01"
    finish
fi


build_prop_path="/s/system/build.prop"
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
    setprop ro.vendor.build.security_patch "2020-06-01"
fi
finish

