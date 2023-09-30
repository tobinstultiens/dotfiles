#!/bin/sh

# Set the display inputs to laptop
laptopSwitch(){
	(sudo ddcutil -b 7 setvcp 0x60 0x11)
	#(sudo ddcutil -b 4 setvcp 0x60 0x11)
}

# Set the display inputs to pc
pcSwitch(){
	(sudo ddcutil -b 7 setvcp 0x60 0x0f)
	#(sudo ddcutil -b 4 setvcp 0x60 0x12)
}

# Retrieve information on what input is being used.
PC=$(sudo ddcutil -b 7 getvcp 0x60)
LAPTOP=$(sudo ddcutil -b 5 getvcp 0x60)

case $1 in
	1)
		if [[ "$LAPTOP" == *"Invalid"* ]]; then
			(sudo ddcutil -b 5 setvcp 0x60 0x0f)
		elif [[ "$LAPTOP" == *"DisplayPort-1"* ]]; then
			(sudo ddcutil -b 5 setvcp 0x60 0x13)
		fi
		;;
	2)
		if [[ "$PC" == *"DisplayPort-1"* ]]; then
			laptopSwitch
		elif [[ "$PC" == *"HDMI-1"* ]]; then
			pcSwitch
		fi
		;;
esac
