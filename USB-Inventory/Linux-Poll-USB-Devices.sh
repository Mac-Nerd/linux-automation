#!/bin/bash

# Parses /sys/bus/usb/devices/usb for devices/products that match the $MANIFEST
# To generate a manifest, download and run "Linux-Make-USB-Manifest.sh" on a machine with the desired devices connected


MANIFEST="/etc/USBManifest.txt"

INVENTORY=$(wc -l ${MANIFEST} | awk '{print $1}')
echo "Polling for ${INVENTORY} devices."

FOUND=0

ERRORS=0

CHECKLIST=$(cat ${MANIFEST})


if [ ! -f ${MANIFEST} ]
then
	echo "ERROR: No Manifest in ${MANIFEST} - To generate a manifest, download and run Linux-Make-USB-Manifest.sh first."
	exit 1002
fi

# Check your privilege
if [ $(whoami) != "root" ]; then
    echo "This script must be run with root/sudo privileges."
    exit 1001
fi

# List all the current USB devices
for devicePath in /sys/bus/usb/devices/*
do

        if [ -f ${devicePath}/bDeviceClass ]
        then

# if the path includes a device, it will have a device class.
# check for "hub" class == "09" and skip

        deviceClass=`cat ${devicePath}/bDeviceClass`

                if [ ${deviceClass} != "09" ]  # I don't want no hubs.
                then
                    	vendorID=`cat ${devicePath}/idVendor` 	# all compliant devices will have these
                        productID=`cat ${devicePath}/idProduct`

			DEVICE=$(printf '%s | %s' "$vendorID" "$productID")

			# search the manifest for the same device info
			if [[ $(grep "$DEVICE" ${MANIFEST}) ]]
			then
				((FOUND++))
				CHECKLIST=$(printf "%s" "$CHECKLIST" | sed "/${DEVICE}/d" )
			else

				[ -f ${devicePath}/manufacturer ] && manufacturer=`cat ${devicePath}/manufacturer` || manufacturer="unknown"	# not all will have readable names/serials
				[ -f ${devicePath}/product ] && product=`cat ${devicePath}/product` || product="unknown"
				[ -f ${devicePath}/serial ] && serial=`cat ${devicePath}/serial` || serial="-"

				echo "ERROR: Device not in Manifest: ${DEVICE}: ${manufacturer} ${product} ${serial}"

				((ERRORS++))
			fi


                fi

        fi

done

echo "Found: ${FOUND} of ${INVENTORY} devices."
if [ ! -z "${CHECKLIST}" ]
then
	((ERRORS++))
	echo "ERROR: MISSING USB DEVICE(S)"
	printf "%s" "${CHECKLIST}\n"
fi


# if everything is present, log success and exit 0
# otherwise, log missing item, exit nonzero

if [ $ERRORS != 0 ]
then
	ERRORS=1001
fi

exit $ERRORS
