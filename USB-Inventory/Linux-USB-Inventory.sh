#!/bin/bash
# Version 2 - 08 December, 2021

# List all the current USB devices and output "manufacturer | product | serial number | vendor ID | product ID" for each device. 
# used for generating inventory reports

# Check your privilege
if [ "$(whoami)" != "root" ]; then
	echo "This script must be run with root/sudo privileges."
	exit 1
fi


printf 'manufacturer name | product name | serial number | vendor ID | product ID\n'


# List all the current USB devices
for devicePath in /sys/bus/usb/devices/*
do

	if [ -f "${devicePath}/bDeviceClass" ]
	then

# if the path includes a device, it will have a device class.
# check for "hub" class == "09" and skip

	deviceClass=$(cat "${devicePath}/bDeviceClass")

	if [ "${deviceClass}" != "09" ]	 # I don't want no hubs.
	then
		vendorID=$("cat ${devicePath}/idVendor")	# all compliant devices will have these
		productID=$("cat ${devicePath}/idProduct")

		[ -f "${devicePath}/manufacturer" ] && manufacturer=$("cat ${devicePath}/manufacturer")|| manufacturer="-"	# not all will have readable names/serials
		[ -f "${devicePath}/product" ] && product=$("cat ${devicePath}/product")|| product="-"
		[ -f "${devicePath}/serial" ] && serial=$("cat ${devicePath}/serial") || serial="-"

		printf '%s | %s | %s | %s | %s \n' "$manufacturer" "$product" "$serial" "$vendorID" "$productID"

	fi

fi

done
