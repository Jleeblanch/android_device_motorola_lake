#!/sbin/sh

SLOT=`getprop ro.boot.slot_suffix`
mount /dev/block/bootdevice/by-name/vendor$SLOT /vendor -o ro

panel_supplier=""
panel_supplier=$(cat /sys/devices/virtual/graphics/fb0/panel_supplier 2> /dev/null)
echo "panel supplier vendor is: [$panel_supplier]"

case $panel_supplier in
	boe | tianmah)
		insmod /vendor/lib/modules/himax_mmi.ko
		;;
	tianman)
		insmod /vendor/lib/modules/nova_mmi.ko
		;;
	tianma)
		insmod /vendor/lib/modules/synaptics_tcm_i2c.ko
		insmod /vendor/lib/modules/synaptics_tcm_core.ko
		insmod /vendor/lib/modules/synaptics_tcm_touch.ko
		insmod /vendor/lib/modules/synaptics_tcm_device.ko
		insmod /vendor/lib/modules/synaptics_tcm_reflash.ko
		insmod /vendor/lib/modules/synaptics_tcm_testing.ko
		;;
	*)
		echo "$panel_supplier not supported"
		;;
esac

# MMI Common
insmod /vendor/lib/modules/mmi_pl_chg_manager.ko
insmod /vendor/lib/modules/mmi_sys_temp.ko
insmod /vendor/lib/modules/sensors_class.ko

# Lake specific
insmod /vendor/lib/modules/aw869x.ko
insmod /vendor/lib/modules/bq2597x_mmi.ko
insmod /vendor/lib/modules/sx933x_sar.ko

umount /vendor
