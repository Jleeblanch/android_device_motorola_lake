#!/system/bin/sh

PATH=/sbin:/system/bin:/vendor/sbin:/vendor/bin
export PATH

# Globals
scriptname=${0##*/}
dlkm_path=/vendor/lib/modules
panel_path=/sys/devices/virtual/graphics/fb0
fastboot_twrp=$(getprop ro.boot.fastboot)

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

load_panel_modules()
{
	panel_supplier=""
	panel_supplier=$(cat $panel_path/panel_supplier 2> /dev/null)
	notice "Panel supplier is: $panel_supplier"

	case $panel_supplier in
		boe | tianmah)
			insmod $dlkm_path/himax_mmi.ko
			;;
		tianman)
			insmod $dlkm_path/nova_mmi.ko
			;;
		tianma)
			insmod $dlkm_path/synaptics_tcm_i2c.ko
			insmod $dlkm_path/synaptics_tcm_core.ko
			insmod $dlkm_path/synaptics_tcm_touch.ko
			insmod $dlkm_path/synaptics_tcm_device.ko
			insmod $dlkm_path/synaptics_tcm_reflash.ko
			insmod $dlkm_path/synaptics_tcm_testing.ko
			;;
		*)
			notice "$panel_supplier is not supported"
			;;
	esac
}

load_misc_modules()
{
	notice "Loading kernel modules from [$dlkm_path]"
	insmod $dlkm_path/aw869x.ko
	insmod $dlkm_path/bq2597x_mmi.ko
	insmod $dlkm_path/mmi_pl_chg_manager.ko
	insmod $dlkm_path/mmi_sys_temp.ko
	insmod $dlkm_path/sensors_class.ko
	insmod $dlkm_path/sx933x_sar.ko
}

# If we are fastboot booting twrp, then do nothing
if [ ! -z "$fastboot_twrp" ]; then
	notice "TWRP was booted using fastboot, modules not needed"
	setprop dlkm.loaded 0
	return 0
fi

# Mount vendor
slot_suffix=$(getprop ro.boot.slot_suffix)
vendor_path="/dev/block/bootdevice/by-name/vendor$slot_suffix"
mount -t ext4 -o ro $vendor_path /vendor

# Detect whether modules exist, if they do then assume we are on stock.
if [ -d "$dlkm_path" ]; then
	notice "[$dlkm_path] exists, assuming needed..."
	load_panel_modules
	load_misc_modules
	umount /vendor
	setprop dlkm.loaded 1
	return 0
else
	notice "[$dlkm_path] does not exist, assuming not needed..."
	umount /vendor
	setprop dlkm.loaded 0
	return 0
fi
